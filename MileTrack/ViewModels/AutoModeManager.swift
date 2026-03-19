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
  }

  /// Represents the overall health of tracking capabilities.
  /// - green: Everything working - Auto Mode is enabled and has required permissions
  /// - orange: Auto Mode is disabled or needs attention (user should enable it)
  /// - red: Something is broken - permissions denied or location services off
  enum TrackingHealth: Equatable {
    case green
    case orange
    case red
    
    var color: String {
      switch self {
      case .green: return "green"
      case .orange: return "orange"
      case .red: return "red"
      }
    }
    
    var systemImage: String {
      switch self {
      case .green: return "checkmark.circle.fill"
      case .orange: return "exclamationmark.circle.fill"
      case .red: return "xmark.circle.fill"
      }
    }
    
    var title: String {
      switch self {
      case .green: return "Tracking Active"
      case .orange: return "Tracking Off"
      case .red: return "Tracking Issue"
      }
    }
    
    var description: String {
      switch self {
      case .green: return "Auto Mode is on and ready to detect drives."
      case .orange: return "Auto Mode is off. Turn it on in Settings to detect drives automatically."
      case .red: return "There's a permission issue preventing tracking. Check Settings."
      }
    }
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
    var currentSpeedMPH: Double?
  }
  
  /// Computed tracking health based on current status and permissions.
  var trackingHealth: TrackingHealth {
    let s = status
    
    // Red: Something is broken - permissions denied or restricted
    if s.locationAuthorization == .denied || s.locationAuthorization == .restricted {
      return .red
    }
    if s.motionAuthorization == .denied || s.motionAuthorization == .restricted {
      return .red
    }
    
    // Orange: Auto Mode is disabled by user
    if !s.isEnabled {
      return .orange
    }
    
    // Orange: Location not determined yet (needs setup)
    if s.locationAuthorization == .notDetermined {
      return .orange
    }
    
    // Green: Auto Mode is enabled and we have sufficient permissions
    if s.isEnabled && (s.locationAuthorization == .authorizedAlways || s.locationAuthorization == .authorizedWhenInUse) {
      return .green
    }
    
    // Default to orange for any other ambiguous state
    return .orange
  }

  @Published private(set) var status: TrackingStatus

  private let logger = DiagnosticsLogger.shared

  private let tripStore: TripStore
  private let rulesStore: RulesStore?
  private let locationsStore: LocationsStore?
  private let drivingDetection: DrivingDetectionService
  private let locationTracking: LocationTrackingService
  private let rulesEngine = RulesEngine()
  private let geocoder: ReverseGeocodeService

  private var cancellables: Set<AnyCancellable> = []

  private var driveStartDate: Date?
  private var driveStartLocation: CLLocation?
  private var lastStopDate: Date?
  private var isRunning: Bool = false
  private var geocodeTasks: [Task<Void, Never>] = []

  init(
    tripStore: TripStore,
    rulesStore: RulesStore? = nil,
    locationsStore: LocationsStore? = nil,
    drivingDetection: DrivingDetectionService? = nil,
    locationTracking: LocationTrackingService? = nil
  ) {
    self.tripStore = tripStore
    self.rulesStore = rulesStore
    self.locationsStore = locationsStore
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
      lastEvent: nil,
      currentSpeedMPH: nil
    )

    // Use the stored (non-optional) instances, not the optional parameters.
    self.drivingDetection.delegate = self
    self.locationTracking.delegate = self
    
    // Register default for motion detection toggle (enabled by default)
    UserDefaults.standard.register(defaults: [
      "useMotionDetection": true
    ])

    // Keep toggle in sync even if Settings isn't open.
    NotificationCenter.default.publisher(for: UserDefaults.didChangeNotification)
      .debounce(for: .milliseconds(150), scheduler: RunLoop.main)
      .sink { [weak self] _ in
        guard let self else { return }
        let enabled = UserDefaults.standard.bool(forKey: "autoModeEnabled")
        self.setEnabled(enabled)
      }
      .store(in: &cancellables)

    // Trigger initial authorization status update - CLLocationManager fires this callback
    // shortly after delegate is set, but we want to ensure we have the current status
    Task { @MainActor [weak self] in
      guard let self else { return }
      // Update authorization statuses from the services
      self.status.locationAuthorization = self.locationTracking.authorizationStatus
      self.status.motionAuthorization = self.drivingDetection.authorizationStatus

      // Salvage any trip that was in-progress when the app was last killed.
      self.checkForSalvagedTrip()

      // Start if enabled - now that we have current authorization
      if self.status.isEnabled {
        self.startIfNeeded()
      }
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

    // Check location authorization - need at least When In Use, prefer Always for background
    let auth = status.locationAuthorization
    if auth == .denied || auth == .restricted {
      status.lastEvent = "Location permission denied — Auto Mode paused"
#if DEBUG
      debugLogStatus(prefix: "[AutoMode] start blocked (location denied)")
#endif
      logger.log("tracking", "start blocked (location permission denied)")
      isRunning = false
      status.isRunning = false
      return
    }

    // Mark as running before starting monitoring
    isRunning = true
    status.isRunning = true
    
    // Check if motion detection is enabled via UserDefaults
    let useMotionDetection = UserDefaults.standard.bool(forKey: "useMotionDetection")
    
    if useMotionDetection {
      status.lastEvent = "Auto Mode running (speed + motion)"
      logger.log("tracking", "started speed-based location monitoring + motion detection")
      
      // Start motion detection for confidence scoring
      drivingDetection.start()
    } else {
      status.lastEvent = "Auto Mode running (GPS-only)"
      logger.log("tracking", "started speed-based location monitoring (motion disabled)")
      
      // Motion detection disabled - GPS-only mode
      // Don't start drivingDetection service
    }

    // Handle location authorization flow
    // iOS requires a two-step process: first "When In Use", then "Always"
    if auth == .notDetermined {
      // First time: request When In Use permission
      logger.log("tracking", "requesting location when in use authorization")
      locationTracking.requestWhenInUse()
      // After user grants When In Use, we can immediately request Always
      // The delegate callback will handle starting monitoring once authorized
    } else if auth == .authorizedWhenInUse {
      // Already have When In Use, start monitoring and request upgrade to Always
      logger.log("tracking", "starting monitoring with when in use, requesting upgrade to always")
      locationTracking.startMonitoring()
      // Request upgrade to Always for background tracking
      locationTracking.requestAlwaysAuthorization()
    } else if auth == .authorizedAlways {
      // Perfect - we have full access, start monitoring
      logger.log("tracking", "starting monitoring with always authorization")
      locationTracking.startMonitoring()
    }

#if DEBUG
    debugLogStatus(prefix: useMotionDetection ? "[AutoMode] started (speed + motion)" : "[AutoMode] started (GPS-only)")
#endif
  }

  func stop() {
    // Idempotent.
    clearPersistedState()
    for task in geocodeTasks { task.cancel() }
    geocodeTasks.removeAll()

    drivingDetection.stop()
    locationTracking.reset()
    logger.log("tracking", "stopped location monitoring + tracking (reset)")
    driveStartDate = nil
    driveStartLocation = nil
    status.isDriving = false
    status.isLocationTrackingActive = false
    status.distanceMeters = 0
    status.tripStartDate = nil
    status.currentSpeedMPH = nil

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

  // MARK: - In-progress trip persistence

  /// Snapshot of an active trip, written to UserDefaults on every distance update.
  /// Lets us salvage partial trip data if the app is killed mid-drive.
  private struct InProgressTripState: Codable {
    let startDate: Date
    let startLatitude: Double?
    let startLongitude: Double?
    let accumulatedMeters: Double
    let savedAt: Date

    /// Discard snapshots older than 4 hours — the user almost certainly stopped driving.
    static let maxAgeSeconds: TimeInterval = 4 * 3600
    var isStale: Bool { Date().timeIntervalSince(savedAt) > Self.maxAgeSeconds }
  }

  private static let inProgressStateKey = "com.miletrack.inProgressTripState"

  private func persistInProgressState() {
    guard status.isDriving, let startDate = driveStartDate else { return }
    let state = InProgressTripState(
      startDate: startDate,
      startLatitude: driveStartLocation?.coordinate.latitude,
      startLongitude: driveStartLocation?.coordinate.longitude,
      accumulatedMeters: status.distanceMeters,
      savedAt: Date()
    )
    if let data = try? JSONEncoder().encode(state) {
      UserDefaults.standard.set(data, forKey: Self.inProgressStateKey)
    }
  }

  private func clearPersistedState() {
    UserDefaults.standard.removeObject(forKey: Self.inProgressStateKey)
  }

  /// Called once on launch. If a persisted in-progress state exists (app was killed mid-drive),
  /// creates a salvaged trip and inserts it into the inbox.
  private func checkForSalvagedTrip() {
    guard
      let data = UserDefaults.standard.data(forKey: Self.inProgressStateKey),
      let state = try? JSONDecoder().decode(InProgressTripState.self, from: data)
    else { return }

    clearPersistedState()

    guard !state.isStale else {
      logger.log("tracking", "discarded stale in-progress state (age > 4h)")
      return
    }

    let endDate = Date()
    let duration = endDate.timeIntervalSince(state.startDate)
    let miles = state.accumulatedMeters / 1609.344

    guard miles >= Guardrails.minimumDistanceMiles,
          duration >= Guardrails.minimumDurationSeconds else {
      logger.log("tracking", "discarded salvaged trip (too short: \(String(format: "%.2f", miles))mi \(Int(duration))s)")
      return
    }

    var trip = Trip(
      date: endDate,
      distanceMiles: miles,
      durationSeconds: Int(duration),
      startLabel: "Recovered trip",
      endLabel: nil,
      startLatitude: state.startLatitude,
      startLongitude: state.startLongitude,
      endLatitude: nil,
      endLongitude: nil,
      source: .auto,
      state: .pendingCategory,
      category: nil,
      clientOrOrg: nil,
      projectCode: nil,
      notes: "Recovered after unexpected app exit"
    )

    if let rulesStore {
      let (updated, _) = rulesEngine.applyFirstMatch(to: trip, rules: rulesStore.rules)
      trip = updated
    }

    tripStore.trips.insert(trip, at: 0)
    logger.log("tracking", "salvaged trip from persistent state: \(String(format: "%.2f", miles))mi \(Int(duration))s")

    if let lat = state.startLatitude, let lon = state.startLongitude {
      let startLoc = CLLocation(latitude: lat, longitude: lon)
      if let match = locationsStore?.nearest(to: startLoc) {
        if let idx = tripStore.trips.firstIndex(where: { $0.id == trip.id }) {
          tripStore.trips[idx].startLabel = match.location.name
          if !match.location.address.isEmpty {
            tripStore.trips[idx].startAddress = match.location.address
          }
        }
      } else {
        let task = Task { [weak self] in
          guard let self else { return }
          let result = await self.geocoder.addresses(for: startLoc)
          guard let result else { return }
          await MainActor.run {
            if let idx = self.tripStore.trips.firstIndex(where: { $0.id == trip.id }) {
              self.tripStore.trips[idx].startLabel = result.shortLabel
              self.tripStore.trips[idx].startAddress = result.fullAddress
            }
          }
        }
        geocodeTasks.append(task)
      }
    }
  }

  // MARK: - Private

  private func finishDrive(at endDate: Date, endLocation: CLLocation?) {
    clearPersistedState()
    let result = locationTracking.stopTrackingWithEndpoints()
    status.isLocationTrackingActive = false
    logger.log("tracking", "location updates stopped")

    let startLoc = driveStartLocation ?? result.startLocation
    let potentialStart = driveStartDate ?? result.startDate
    driveStartDate = nil
    driveStartLocation = nil

    guard let start = potentialStart else {
      // No start date means something went wrong - discard this partial trip
      logger.log("tracking", "trip discarded: no start date")
      status.lastEvent = "Trip discarded (no start date)"
      status.distanceMeters = 0
      return
    }

    let duration = endDate.timeIntervalSince(start)
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
      startLatitude: startLoc?.coordinate.latitude,
      startLongitude: startLoc?.coordinate.longitude,
      endLatitude: endLocation?.coordinate.latitude,
      endLongitude: endLocation?.coordinate.longitude,
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
    // Resolve labels: snap to saved locations first, then fall back to reverse geocoding.
    if let startLoc {
      if let match = locationsStore?.nearest(to: startLoc) {
        // Snap to saved location (e.g. "Home")
        if let idx = tripStore.trips.firstIndex(where: { $0.id == trip.id }) {
          tripStore.trips[idx].startLabel = match.location.name
          if !match.location.address.isEmpty {
            tripStore.trips[idx].startAddress = match.location.address
          }
        }
#if DEBUG
        print("[AutoMode] start snapped to saved location \"\(match.location.name)\" (\(Int(match.distance))m away)")
#endif
        logger.log("tracking", "start snapped to \"\(match.location.name)\" (\(Int(match.distance))m)")
      } else {
        let task = Task { [weak self] in
          guard let self else { return }
          let result = await self.geocoder.addresses(for: startLoc)
          guard let result else { return }
          await MainActor.run {
            if let idx = self.tripStore.trips.firstIndex(where: { $0.id == trip.id }) {
              self.tripStore.trips[idx].startLabel = result.shortLabel
              self.tripStore.trips[idx].startAddress = result.fullAddress
            }
          }
        }
        geocodeTasks.append(task)
      }
    }
    let endLoc = endLocation ?? result.endLocation
    if let endLoc {
      if let match = locationsStore?.nearest(to: endLoc) {
        // Snap to saved location
        if let idx = tripStore.trips.firstIndex(where: { $0.id == trip.id }) {
          tripStore.trips[idx].endLabel = match.location.name
          if !match.location.address.isEmpty {
            tripStore.trips[idx].endAddress = match.location.address
          }
        }
#if DEBUG
        print("[AutoMode] end snapped to saved location \"\(match.location.name)\" (\(Int(match.distance))m away)")
#endif
        logger.log("tracking", "end snapped to \"\(match.location.name)\" (\(Int(match.distance))m)")
      } else {
        let task = Task { [weak self] in
          guard let self else { return }
          let result = await self.geocoder.addresses(for: endLoc)
          guard let result else { return }
          await MainActor.run {
            if let idx = self.tripStore.trips.firstIndex(where: { $0.id == trip.id }) {
              self.tripStore.trips[idx].endLabel = result.shortLabel
              self.tripStore.trips[idx].endAddress = result.fullAddress
            }
          }
        }
        geocodeTasks.append(task)
      }
    }
    status.lastEvent = "Drive captured → Inbox"
    status.distanceMeters = 0
    lastStopDate = endDate
    status.lastStopDate = lastStopDate
    status.tripStartDate = nil
  }

#if DEBUG
  @MainActor
  func debugSimulateDrive(distanceMiles: Double = 3.2, durationSeconds: Int = 420) {
    let end = Date()
    
    // Rotate through realistic route scenarios
    let routes = [
      (start: "Home", end: "Office", startAddr: "123 Oak Street, Cupertino, CA 95014", endAddr: "1 Apple Park Way, Cupertino, CA 95014", startLat: 37.3229, startLon: -122.0321, endLat: 37.3349, endLon: -122.0090),
      (start: "Downtown", end: "Airport", startAddr: "Market Street, San Francisco, CA 94102", endAddr: "San Francisco International Airport, San Francisco, CA 94128", startLat: 37.7749, startLon: -122.4194, endLat: 37.6213, endLon: -122.3790),
      (start: "Coffee Shop", end: "Client Site", startAddr: "Starbucks, Main Street, Mountain View, CA 94041", endAddr: "Google Campus, Mountain View, CA 94043", startLat: 37.3861, startLon: -122.0839, endLat: 37.4220, endLon: -122.0841),
      (start: "Home", end: "Gym", startAddr: "Residential Area, Palo Alto, CA 94301", endAddr: "24 Hour Fitness, Palo Alto, CA 94301", startLat: 37.4419, startLon: -122.1430, endLat: 37.4275, endLon: -122.1697),
      (start: "Office", end: "Restaurant", startAddr: "Tech Campus, Menlo Park, CA 94025", endAddr: "University Avenue, Palo Alto, CA 94301", startLat: 37.4530, startLon: -122.1817, endLat: 37.4469, endLon: -122.1603)
    ]
    
    let routeIndex = tripStore.trips.count % routes.count
    let route = routes[routeIndex]
    
    var trip = Trip(
      date: end,
      distanceMiles: max(0.0, distanceMiles),
      durationSeconds: max(0, durationSeconds),
      startLabel: route.start,
      endLabel: route.end,
      startAddress: route.startAddr,
      endAddress: route.endAddr,
      startLatitude: route.startLat,
      startLongitude: route.startLon,
      endLatitude: route.endLat,
      endLongitude: route.endLon,
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
  
  func drivingDetectionDidUpdateMotionConfidence(_ service: DrivingDetectionService, confidence: Double) {
    Task { @MainActor in
      // Forward motion confidence to location tracking service
      self.locationTracking.updateMotionConfidence(confidence)
    }
  }

  // These are kept for backward compatibility but no longer used for primary detection
  func drivingDetectionDidStartDriving(_ service: DrivingDetectionService, at date: Date) {
    // Speed-based detection now handles this
  }

  func drivingDetectionDidStopDriving(_ service: DrivingDetectionService, at date: Date) {
    // Speed-based detection now handles this
  }
}

extension AutoModeManager: LocationTrackingServiceDelegate {
  func locationTrackingDidUpdateAuthorization(_ service: LocationTrackingService, status: CLAuthorizationStatus) {
    Task { @MainActor in
      let previousAuth = self.status.locationAuthorization
      self.status.locationAuthorization = status
      
      // Handle authorization changes when auto mode is enabled
      guard self.status.isEnabled, self.isRunning else { return }
      
      switch status {
      case .authorizedWhenInUse:
        // Start monitoring if not already running
        if !self.locationTracking.isMonitoring {
          self.locationTracking.startMonitoring()
          self.status.lastEvent = "Location authorized — monitoring started"
          self.logger.log("tracking", "when in use authorized, started monitoring")
        }
        
        // If we just got When In Use for the first time, wait a moment then request Always
        if previousAuth == .notDetermined {
          // Small delay to let iOS dismiss the first prompt before showing the second
          try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second delay
          
          // Make sure we're still authorized before requesting upgrade
          if self.status.locationAuthorization == .authorizedWhenInUse {
            self.logger.log("tracking", "requesting upgrade to always authorization")
            self.locationTracking.requestAlwaysAuthorization()
          }
        }
        
      case .authorizedAlways:
        // Start monitoring if not already running
        if !self.locationTracking.isMonitoring {
          self.locationTracking.startMonitoring()
          self.status.lastEvent = "Location always authorized — background monitoring active"
          self.logger.log("tracking", "always authorized, started monitoring")
        } else {
          self.status.lastEvent = "Location always authorized — background monitoring active"
          self.logger.log("tracking", "upgraded to always authorization")
        }
        
      case .denied, .restricted:
        // If a trip is in progress, salvage the partial trip data before stopping
        if self.status.isDriving {
          self.logger.log("tracking", "permission revoked mid-trip, salvaging partial trip")
          self.finishDrive(at: Date(), endLocation: nil)
          self.status.isDriving = false
        }
        // Stop monitoring if permission was revoked
        if self.locationTracking.isMonitoring {
          self.locationTracking.stopMonitoring()
          self.status.lastEvent = "Location permission denied"
          self.logger.log("tracking", "permission denied, stopped monitoring")
        }
        
      case .notDetermined:
        // Shouldn't happen, but handle it gracefully
        break
        
      @unknown default:
        break
      }
    }
  }

  func locationTrackingDidUpdateDistance(_ service: LocationTrackingService, distanceMeters: Double) {
    Task { @MainActor in
      self.status.distanceMeters = distanceMeters
      self.persistInProgressState()
    }
  }

  func locationTrackingDidDetectMovementStart(_ service: LocationTrackingService, location: CLLocation) {
    Task { @MainActor in
      guard self.status.isEnabled else { return }
      guard self.isRunning else { return }

      // Anti-flap cooldown: ignore starts shortly after a stop.
      let now = Date()
      if let lastStopDate = self.lastStopDate, now.timeIntervalSince(lastStopDate) < Guardrails.cooldownSeconds {
#if DEBUG
        print("[AutoMode] movement start ignored (cooldown \(Int(Guardrails.cooldownSeconds))s)")
        debugLogStatus(prefix: "[AutoMode] cooldown")
#endif
        self.status.lastEvent = "Movement ignored (cooldown)"
        return
      }

      self.status.isDriving = true
      let speedMPH = location.speed >= 0 ? location.speed * 2.23694 : 0
      self.status.currentSpeedMPH = speedMPH
      self.status.lastEvent = "Movement detected (>\(Int(LocationTrackingService.speedThresholdMPS * 2.23694)) mph)"
      self.driveStartDate = now
      
      // ENHANCEMENT: Use pre-movement location if available (from before speed threshold was exceeded)
      // This provides a more accurate starting point by looking back at location history
      if let preMovementLocation = self.locationTracking.getPreMovementLocation() {
        self.driveStartLocation = preMovementLocation
        self.logger.log("tracking", "using pre-movement location as start (backtracked from history)")
#if DEBUG
        let distance = preMovementLocation.distance(from: location)
        print("[AutoMode] backtracked \(Int(distance))m to pre-movement location")
#endif
      } else {
        // Fallback to current location if no history available
        self.driveStartLocation = location
        self.logger.log("tracking", "using current location as start (no history)")
      }
      
      self.status.tripStartDate = now
      self.logger.log("tracking", "movement detected (speed: \(String(format: "%.1f", speedMPH)) mph)")

      // Start distance tracking
      if !self.status.isLocationTrackingActive {
        self.locationTracking.startTracking()
        self.status.isLocationTrackingActive = true
        self.logger.log("tracking", "distance tracking started")
      }

#if DEBUG
      debugLogStatus(prefix: "[AutoMode] movement started (speed-based)")
#endif
    }
  }

  func locationTrackingDidDetectMovementStop(_ service: LocationTrackingService, location: CLLocation) {
    Task { @MainActor in
      guard self.status.isEnabled else { return }
      guard self.isRunning else { return }

      self.status.isDriving = false
      self.status.currentSpeedMPH = nil
      self.status.lastEvent = "Movement stopped (2min confirmation)"
      self.logger.log("tracking", "movement stopped (finalized after 2min)")
      self.finishDrive(at: Date(), endLocation: location)

#if DEBUG
      debugLogStatus(prefix: "[AutoMode] movement stopped (speed-based)")
#endif
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

