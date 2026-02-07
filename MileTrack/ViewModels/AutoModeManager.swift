import Combine
import CoreLocation
import CoreMotion
import Foundation

@MainActor
final class AutoModeManager: ObservableObject {
  enum Guardrails {
    static let minimumDistanceMiles: Double = 0.30
    static let minimumDurationSeconds: TimeInterval = 120
    static let cooldownSeconds: TimeInterval = 45
    static let stableNonDrivingSeconds: TimeInterval = 20
  }

  struct TrackingStatus: Equatable {
    var isEnabled: Bool
    var isRunning: Bool
    var motionAuthorization: CMAuthorizationStatus
    var locationAuthorization: CLAuthorizationStatus
    var isDriving: Bool
    var isLocationTrackingActive: Bool
    var distanceMeters: Double
    var tripStartDate: Date?
    var lastStopDate: Date?
    var lastEvent: String?
  }

  @Published private(set) var status: TrackingStatus

  private let logger = DiagnosticsLogger.shared

  private let tripStore: TripStore
  private let rulesStore: RulesStore?
  private let drivingDetection: DrivingDetectionService
  private let locationTracking: LocationTrackingService
  private let rulesEngine = RulesEngine()
  private let geocoder: ReverseGeocodeService

  private var cancellables: Set<AnyCancellable> = []

  private var driveStartDate: Date?
  private var lastStopDate: Date?
  private var isRunning: Bool = false
  private var endGraceTask: Task<Void, Never>?
  private var geocodeTasks: [Task<Void, Never>] = []

  init(
    tripStore: TripStore,
    rulesStore: RulesStore? = nil,
    drivingDetection: DrivingDetectionService? = nil,
    locationTracking: LocationTrackingService? = nil
  ) {
    self.tripStore = tripStore
    self.rulesStore = rulesStore
    // Avoid evaluating potentially `@MainActor` default arguments at the call site.
    let drivingDetectionService = drivingDetection ?? DrivingDetectionService()
    let locationTrackingService = locationTracking ?? LocationTrackingService()
    self.drivingDetection = drivingDetectionService
    self.locationTracking = locationTrackingService
    self.geocoder = ReverseGeocodeService()

    self.status = TrackingStatus(
      isEnabled: UserDefaults.standard.bool(forKey: "autoModeEnabled"),
      isRunning: false,
      motionAuthorization: drivingDetectionService.authorizationStatus,
      locationAuthorization: locationTrackingService.authorizationStatus,
      isDriving: false,
      isLocationTrackingActive: false,
      distanceMeters: 0,
      tripStartDate: nil,
      lastStopDate: nil,
      lastEvent: nil
    )

    // Use the stored (non-optional) instances, not the optional parameters.
    self.drivingDetection.delegate = self
    self.locationTracking.delegate = self

    // Keep toggle in sync even if Settings isn’t open.
    NotificationCenter.default.publisher(for: UserDefaults.didChangeNotification)
      .debounce(for: .milliseconds(150), scheduler: RunLoop.main)
      .sink { [weak self] _ in
        guard let self else { return }
        let enabled = UserDefaults.standard.bool(forKey: "autoModeEnabled")
        self.setEnabled(enabled)
      }
      .store(in: &cancellables)

    // Start if enabled.
    if status.isEnabled {
      startIfNeeded()
    }
  }

  func setEnabled(_ enabled: Bool) {
    if status.isEnabled == enabled { return }
    status.isEnabled = enabled
    status.lastEvent = enabled ? "Auto Mode enabled" : "Auto Mode disabled"
    logger.log("tracking", enabled ? "auto mode toggled ON" : "auto mode toggled OFF")

    if enabled {
      startIfNeeded()
    } else {
      stop()
    }
  }

  func startIfNeeded() {
    guard status.isEnabled else { return }

    // Defensive: do not start if Motion permission is denied/restricted.
    // Users can re-enable in iOS Settings (Motion & Fitness / app settings).
    if status.motionAuthorization == .denied || status.motionAuthorization == .restricted {
      status.lastEvent = "Motion permission denied — Auto Mode paused"
#if DEBUG
      debugLogStatus(prefix: "[AutoMode] start blocked (motion denied)")
#endif
      logger.log("tracking", "start blocked (motion permission denied)")
      isRunning = false
      status.isRunning = false
      return
    }

    guard !isRunning else {
#if DEBUG
      debugLogStatus(prefix: "[AutoMode] startIfNeeded ignored (already running)")
#endif
      logger.log("tracking", "start ignored (already running)")
      return
    }
    if let lastStopDate, Date().timeIntervalSince(lastStopDate) < Guardrails.cooldownSeconds {
#if DEBUG
      debugLogStatus(prefix: "[AutoMode] startIfNeeded ignored (cooldown)")
#endif
      logger.log("tracking", "start ignored (cooldown)")
      return
    }

    isRunning = true
    status.isRunning = true
    status.lastEvent = "Auto Mode running"
    logger.log("tracking", "started motion activity updates")
    drivingDetection.start()

    // Prompt for location when enabling if not determined.
    if status.locationAuthorization == .notDetermined {
      logger.log("tracking", "requesting location when-in-use authorization")
      locationTracking.requestWhenInUse()
    }

#if DEBUG
    debugLogStatus(prefix: "[AutoMode] started")
#endif
  }

  func stop() {
    // Idempotent.
    endGraceTask?.cancel()
    endGraceTask = nil
    for task in geocodeTasks { task.cancel() }
    geocodeTasks.removeAll()

    drivingDetection.stop()
    locationTracking.reset()
    logger.log("tracking", "stopped motion activity + location updates (reset)")
    driveStartDate = nil
    status.isDriving = false
    status.isLocationTrackingActive = false
    status.distanceMeters = 0
    status.tripStartDate = nil

    isRunning = false
    status.isRunning = false
    lastStopDate = Date()
    status.lastStopDate = lastStopDate
    status.lastEvent = "Stopped"
    logger.log("tracking", "stopped")

#if DEBUG
    debugLogStatus(prefix: "[AutoMode] stopped")
#endif
  }

  func requestWhenInUseLocation() {
    locationTracking.requestWhenInUse()
  }

  // MARK: - Private

  private func finishDrive(at endDate: Date) {
    let result = locationTracking.stopTrackingWithEndpoints()
    status.isLocationTrackingActive = false
    logger.log("tracking", "location updates stopped")

    let start = driveStartDate ?? result.startDate
    driveStartDate = nil

    let duration = (start != nil) ? endDate.timeIntervalSince(start!) : 0
    let distance = result.distanceMeters

    let miles = distance / 1609.344

    // Threshold guardrails.
    if miles < Guardrails.minimumDistanceMiles || duration < Guardrails.minimumDurationSeconds {
#if DEBUG
      print("[AutoMode] drive skipped: miles=\(String(format: "%.2f", miles)) duration=\(Int(duration))s (min \(Guardrails.minimumDistanceMiles) mi, \(Int(Guardrails.minimumDurationSeconds))s)")
#endif
      logger.log("tracking", "trip skipped miles=\(String(format: "%.2f", miles)) duration=\(Int(duration))s")
      status.lastEvent = "Drive ignored (too short)"
      status.distanceMeters = 0
      lastStopDate = endDate
      status.lastStopDate = lastStopDate
      status.tripStartDate = nil
      return
    }

    var trip = Trip(
      date: endDate,
      distanceMiles: miles,
      durationSeconds: Int(duration),
      startLabel: "Trip start",
      endLabel: "Trip end",
      source: .auto,
      state: .pendingCategory,
      category: nil,
      clientOrOrg: nil,
      projectCode: nil,
      notes: nil
    )

    if let rulesStore {
      let (updated, _) = rulesEngine.applyFirstMatch(to: trip, rules: rulesStore.rules)
      trip = updated
    }

    tripStore.trips.insert(trip, at: 0)
#if DEBUG
    print("[AutoMode] inserted auto trip \(trip.id) pending_category")
#endif
    let milesText = String(format: "%.2f", miles)
    logger.log("tracking", "trip created id=\(trip.id.uuidString) miles=\(milesText) duration=\(Int(duration))s")
    // Reverse geocode without blocking UI. Update the inserted trip in place when labels resolve.
    if let startLoc = result.startLocation {
      let task = Task { [weak self] in
        guard let self else { return }
        let label = await self.geocoder.label(for: startLoc)
        guard let label else { return }
        await MainActor.run {
          if let idx = self.tripStore.trips.firstIndex(where: { $0.id == trip.id }) {
            self.tripStore.trips[idx].startLabel = label
          }
        }
      }
      geocodeTasks.append(task)
    }
    if let endLoc = result.endLocation {
      let task = Task { [weak self] in
        guard let self else { return }
        let label = await self.geocoder.label(for: endLoc)
        guard let label else { return }
        await MainActor.run {
          if let idx = self.tripStore.trips.firstIndex(where: { $0.id == trip.id }) {
            self.tripStore.trips[idx].endLabel = label
          }
        }
      }
      geocodeTasks.append(task)
    }
    status.lastEvent = "Drive captured → Inbox"
    status.distanceMeters = 0
    lastStopDate = endDate
    status.lastStopDate = lastStopDate
    status.tripStartDate = nil
  }

#if DEBUG
  func debugSimulateDrive(distanceMiles: Double = 3.2, durationSeconds: Int = 420) {
    let end = Date()
    var trip = Trip(
      date: end,
      distanceMiles: max(0.0, distanceMiles),
      durationSeconds: max(0, durationSeconds),
      startLabel: "Trip start",
      endLabel: "Trip end",
      source: .auto,
      state: .pendingCategory,
      category: nil,
      clientOrOrg: nil,
      projectCode: nil,
      notes: "Simulated"
    )

    if let rulesStore {
      let (updated, _) = rulesEngine.applyFirstMatch(to: trip, rules: rulesStore.rules)
      trip = updated
    }
    tripStore.trips.insert(trip, at: 0)
    status.lastEvent = "Simulated drive → Inbox"
  }
#endif
}

extension AutoModeManager: DrivingDetectionServiceDelegate {
  func drivingDetectionDidUpdateAuthorization(_ service: DrivingDetectionService, status: CMAuthorizationStatus) {
    Task { @MainActor in
      self.status.motionAuthorization = status
    }
  }

  func drivingDetectionDidStartDriving(_ service: DrivingDetectionService, at date: Date) {
    Task { @MainActor in
      guard self.status.isEnabled else { return }
      guard self.isRunning else { return }

      // Anti-flap cooldown: ignore starts shortly after a stop.
      if let lastStopDate = self.lastStopDate, date.timeIntervalSince(lastStopDate) < Guardrails.cooldownSeconds {
#if DEBUG
        print("[AutoMode] driving start ignored (cooldown \(Int(Guardrails.cooldownSeconds))s)")
        debugLogStatus(prefix: "[AutoMode] cooldown")
#endif
        self.status.lastEvent = "Driving ignored (cooldown)"
        return
      }

      self.endGraceTask?.cancel()
      self.endGraceTask = nil

      self.status.isDriving = true
      self.status.lastEvent = "Driving detected"
      self.driveStartDate = date
      self.status.tripStartDate = date
      self.logger.log("tracking", "driving detected (start)")

      // Start location tracking only if at least When In Use is granted.
      let auth = self.status.locationAuthorization
      if auth == .authorizedWhenInUse || auth == .authorizedAlways {
        if !self.status.isLocationTrackingActive {
          self.locationTracking.startTracking()
          self.status.isLocationTrackingActive = true
          self.logger.log("tracking", "location updates started")
        }
      } else {
        self.status.lastEvent = "Driving detected (location not authorized)"
        self.logger.log("tracking", "driving detected but location not authorized")
      }

#if DEBUG
      debugLogStatus(prefix: "[AutoMode] driving started")
#endif
    }
  }

  func drivingDetectionDidStopDriving(_ service: DrivingDetectionService, at date: Date) {
    Task { @MainActor in
      guard self.status.isEnabled else { return }
      guard self.isRunning else { return }

      // Require stable non-driving before ending (anti-flap).
      self.status.isDriving = false
      self.status.lastEvent = "Driving ended (waiting)"
      self.logger.log("tracking", "driving ended (grace period started)")

      self.endGraceTask?.cancel()
      self.endGraceTask = Task { [weak self] in
        guard let self else { return }
        let ns = UInt64(Guardrails.stableNonDrivingSeconds * 1_000_000_000)
        try? await Task.sleep(nanoseconds: ns)
        await MainActor.run {
          guard self.status.isEnabled, self.isRunning else { return }
          // If driving resumed, don't end.
          guard !self.status.isDriving else { return }
          self.status.lastEvent = "Driving ended"
          self.logger.log("tracking", "driving ended (finalized)")
          self.finishDrive(at: date)
        }
      }

#if DEBUG
      debugLogStatus(prefix: "[AutoMode] driving stop signaled (grace)")
#endif
    }
  }
}

extension AutoModeManager: LocationTrackingServiceDelegate {
  func locationTrackingDidUpdateAuthorization(_ service: LocationTrackingService, status: CLAuthorizationStatus) {
    Task { @MainActor in
      self.status.locationAuthorization = status
      if self.status.isEnabled, self.status.isDriving, (status == .authorizedWhenInUse || status == .authorizedAlways) {
        if !self.status.isLocationTrackingActive {
          self.locationTracking.startTracking()
          self.status.isLocationTrackingActive = true
          self.status.lastEvent = "Location authorized — tracking started"
        }
      }
    }
  }

  func locationTrackingDidUpdateDistance(_ service: LocationTrackingService, distanceMeters: Double) {
    Task { @MainActor in
      self.status.distanceMeters = distanceMeters
    }
  }
}

#if DEBUG
private extension AutoModeManager {
  func debugLogStatus(prefix: String) {
    let miles = (status.distanceMeters / 1609.344)
    let start = status.tripStartDate?.formatted(date: .abbreviated, time: .shortened) ?? "—"
    let lastStop = status.lastStopDate?.formatted(date: .abbreviated, time: .shortened) ?? "—"
    let milesText = String(format: "%.2f", miles)
    print("\(prefix) isRunning=\(status.isRunning) miles=\(milesText) start=\(start) lastStop=\(lastStop)")
  }
}
#endif

