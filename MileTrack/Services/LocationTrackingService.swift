import CoreLocation
import Foundation

protocol LocationTrackingServiceDelegate: AnyObject {
  func locationTrackingDidUpdateAuthorization(_ service: LocationTrackingService, status: CLAuthorizationStatus)
  func locationTrackingDidUpdateDistance(_ service: LocationTrackingService, distanceMeters: Double)
  func locationTrackingDidDetectMovementStart(_ service: LocationTrackingService, location: CLLocation)
  func locationTrackingDidDetectMovementStop(_ service: LocationTrackingService, location: CLLocation)
  func locationTrackingDidFailWithError(_ service: LocationTrackingService, error: Error)
}

// Default implementations for optional delegate methods
extension LocationTrackingServiceDelegate {
  func locationTrackingDidDetectMovementStart(_ service: LocationTrackingService, location: CLLocation) {}
  func locationTrackingDidDetectMovementStop(_ service: LocationTrackingService, location: CLLocation) {}
  func locationTrackingDidFailWithError(_ service: LocationTrackingService, error: Error) {}
}

/// Distance accumulator with speed-based auto-detection using CoreLocation updates.
@MainActor
final class LocationTrackingService: NSObject {
  weak var delegate: LocationTrackingServiceDelegate?

  // Speed thresholds for auto-detection (in meters per second)
  // 5 mph = 2.2352 m/s
  static let speedThresholdMPS: Double = 2.2352
  static let stopConfirmationSeconds: TimeInterval = 120
  static let requiredConsecutiveHighSpeedReadings: Int = 2

  private let manager: CLLocationManager
  private(set) var isTracking: Bool = false
  private(set) var isMonitoring: Bool = false
  private(set) var isMoving: Bool = false

  private var lastLocation: CLLocation?
  private var firstLocation: CLLocation?
  private(set) var lastAcceptedLocation: CLLocation?
  private var accumulatedDistanceMeters: Double = 0
  private(set) var startDate: Date?

  // Speed-based detection state
  private var lastBelowSpeedDate: Date?
  private var stopConfirmationTask: Task<Void, Never>?
  private var consecutiveHighSpeedCount: Int = 0
  
  // Motion confidence (provided by DrivingDetectionService)
  private(set) var motionConfidence: Double = 0.0
  
  // Location history for backtracking to true start location
  private var recentLocationHistory: [(location: CLLocation, timestamp: Date)] = []
  private let locationHistoryMaxAge: TimeInterval = 300 // Keep 5 minutes of history
  private let locationHistoryMaxCount: Int = 100 // Cap at 100 locations

  init(manager: CLLocationManager = CLLocationManager()) {
    self.manager = manager
    super.init()
    self.manager.delegate = self
    self.manager.activityType = .automotiveNavigation
    // Start with low-power settings; accuracy is adjusted based on monitoring vs tracking state
    self.manager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
    self.manager.distanceFilter = 10
    self.manager.pausesLocationUpdatesAutomatically = false // Critical for background tracking
    // Note: allowsBackgroundLocationUpdates is set in startMonitoring() only after confirming .authorizedAlways
  }
  
  /// Configure location manager for low-power monitoring (waiting for movement).
  private func configureForMonitoring() {
    manager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
    manager.distanceFilter = 10
  }
  
  /// Configure location manager for high-accuracy tracking (active trip).
  private func configureForTracking() {
    manager.desiredAccuracy = kCLLocationAccuracyBest
    manager.distanceFilter = 10
  }

  var authorizationStatus: CLAuthorizationStatus {
    manager.authorizationStatus
  }

  func requestWhenInUse() {
    manager.requestWhenInUseAuthorization()
  }

  func requestAlwaysAuthorization() {
    manager.requestAlwaysAuthorization()
  }

  /// Start monitoring for speed-based movement detection (background capable).
  /// This continuously monitors location for speed changes without accumulating trip distance.
  func startMonitoring() {
    guard !isMonitoring else { return }
    isMonitoring = true
    isMoving = false
    lastBelowSpeedDate = nil
    consecutiveHighSpeedCount = 0
    stopConfirmationTask?.cancel()
    stopConfirmationTask = nil
    
    // Use low-power settings while just monitoring for movement
    configureForMonitoring()
    
    // Only enable background location updates if we have Always authorization
    if manager.authorizationStatus == .authorizedAlways {
      manager.allowsBackgroundLocationUpdates = true
      manager.showsBackgroundLocationIndicator = true
      // Significant-location-changes monitoring lets iOS re-launch the app after termination.
      manager.startMonitoringSignificantLocationChanges()
    }

    manager.startUpdatingLocation()
  }

  /// Stop monitoring for speed-based movement detection.
  func stopMonitoring() {
    guard isMonitoring else { return }
    stopConfirmationTask?.cancel()
    stopConfirmationTask = nil
    if !isTracking {
      manager.stopUpdatingLocation()
    }
    manager.stopMonitoringSignificantLocationChanges()
    isMonitoring = false
    isMoving = false
    lastBelowSpeedDate = nil
  }

  /// Start tracking distance. Optionally seed with pre-detection distance
  /// so miles driven before detection triggers are not silently lost.
  func startTracking(seedDistance: Double = 0, seedLocation: CLLocation? = nil) {
    guard !isTracking else { return }
    isTracking = true
    startDate = Date()
    firstLocation = seedLocation
    lastLocation = seedLocation
    lastAcceptedLocation = seedLocation
    accumulatedDistanceMeters = seedDistance
    delegate?.locationTrackingDidUpdateDistance(self, distanceMeters: accumulatedDistanceMeters)

    // Switch to high-accuracy mode for precise distance tracking
    configureForTracking()

    // If not authorized, this won't produce locations; we still keep status visible via delegate.
    if !isMonitoring {
      manager.startUpdatingLocation()
    }
  }

  func stopTracking() -> (distanceMeters: Double, startDate: Date?, endDate: Date) {
    let end = Date()
    if isTracking && !isMonitoring {
      manager.stopUpdatingLocation()
    }
    isTracking = false
    
    // Switch back to low-power mode if still monitoring
    if isMonitoring {
      configureForMonitoring()
    }
    
    let result = (distanceMeters: accumulatedDistanceMeters, startDate: startDate, endDate: end)
    startDate = nil
    lastLocation = nil
    firstLocation = nil
    lastAcceptedLocation = nil
    accumulatedDistanceMeters = 0
    return result
  }

  func stopTrackingWithEndpoints() -> (distanceMeters: Double, startDate: Date?, endDate: Date, startLocation: CLLocation?, endLocation: CLLocation?) {
    let end = Date()
    if isTracking && !isMonitoring {
      manager.stopUpdatingLocation()
    }
    isTracking = false
    
    // Switch back to low-power mode if still monitoring
    if isMonitoring {
      configureForMonitoring()
    }
    
    let result = (
      distanceMeters: accumulatedDistanceMeters,
      startDate: startDate,
      endDate: end,
      startLocation: firstLocation,
      endLocation: lastAcceptedLocation
    )
    startDate = nil
    lastLocation = nil
    firstLocation = nil
    lastAcceptedLocation = nil
    accumulatedDistanceMeters = 0
    return result
  }

  func reset() {
    stopConfirmationTask?.cancel()
    stopConfirmationTask = nil
    if isTracking || isMonitoring {
      manager.stopUpdatingLocation()
    }
    manager.stopMonitoringSignificantLocationChanges()
    isTracking = false
    isMonitoring = false
    isMoving = false
    startDate = nil
    lastLocation = nil
    firstLocation = nil
    lastAcceptedLocation = nil
    lastBelowSpeedDate = nil
    consecutiveHighSpeedCount = 0
    motionConfidence = 0.0
    accumulatedDistanceMeters = 0
    recentLocationHistory.removeAll()
  }
  
  /// Update motion confidence score from DrivingDetectionService
  func updateMotionConfidence(_ confidence: Double) {
    motionConfidence = confidence
  }
  
  /// Clean up old location history entries
  private func cleanupLocationHistory() {
    let now = Date()
    // Remove entries older than max age
    recentLocationHistory.removeAll { now.timeIntervalSince($0.timestamp) > locationHistoryMaxAge }
    // If still too many, keep only the most recent
    if recentLocationHistory.count > locationHistoryMaxCount {
      recentLocationHistory = Array(recentLocationHistory.suffix(locationHistoryMaxCount))
    }
  }
  
  /// Get the location from just before movement started (when speed was below threshold)
  /// Returns the most recent low-speed location, or nil if not found
  func getPreMovementLocation() -> CLLocation? {
    // Look for the most recent location where speed was below threshold
    // We want the last stationary location before movement began
    for entry in recentLocationHistory.reversed() {
      if entry.location.speed >= 0 && entry.location.speed <= Self.speedThresholdMPS {
        return entry.location
      }
    }
    // Fallback: return the oldest location in history (likely from before movement)
    return recentLocationHistory.first?.location
  }

}

extension LocationTrackingService: CLLocationManagerDelegate {
  nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
    let status = manager.authorizationStatus
    Task { @MainActor in
      // Enable background updates when we get Always authorization
      if status == .authorizedAlways && self.isMonitoring {
        self.manager.allowsBackgroundLocationUpdates = true
        self.manager.showsBackgroundLocationIndicator = true
        self.manager.startMonitoringSignificantLocationChanges()
      }
      self.delegate?.locationTrackingDidUpdateAuthorization(self, status: status)
    }
  }

  nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
    // Filter locations on the callback thread to minimize MainActor work
    let validLocations = locations.filter { location in
      guard location.horizontalAccuracy >= 0 else { return false }
      return location.horizontalAccuracy <= 65
    }
    guard !validLocations.isEmpty else { return }
    
    Task { @MainActor in
      for location in validLocations {
        // Maintain location history buffer when monitoring
        if self.isMonitoring {
          self.recentLocationHistory.append((location: location, timestamp: Date()))
          self.cleanupLocationHistory()
          self.handleSpeedBasedDetection(location: location)
        }

        // Distance accumulation when tracking
        if self.isTracking {
          if self.firstLocation == nil {
            self.firstLocation = location
          }
          if let last = self.lastLocation {
            let delta = location.distance(from: last)
            if delta > 0 {
              self.accumulatedDistanceMeters += delta
              self.delegate?.locationTrackingDidUpdateDistance(self, distanceMeters: self.accumulatedDistanceMeters)
            }
          }
          self.lastLocation = location
          self.lastAcceptedLocation = location
        }
      }
    }
  }

  private func handleSpeedBasedDetection(location: CLLocation) {
    let speed = location.speed
    
    // Speed < 0 means invalid/unknown (e.g., in tunnels, parking garages)
    // Ignore these readings entirely - don't let them trigger the stop timer
    guard speed >= 0 else { return }

    // Reject readings with poor speed accuracy — GPS drift produces high speedAccuracy.
    // speedAccuracy >= 0 means a valid estimate; values > 5 m/s are too uncertain to trust.
    if location.speedAccuracy >= 0, location.speedAccuracy > 5.0 { return }

    if speed > Self.speedThresholdMPS {
      // Moving above threshold
      // ENHANCEMENT: Require motion confidence > 0.2 to filter GPS drift
      // If motion confidence is very low, we might be stationary with GPS noise
      let hasMotionSupport = motionConfidence > 0.2
      
      if hasMotionSupport || motionConfidence == 0.0 {
        // Either motion confirms movement, or motion data unavailable (fallback to GPS only)
        consecutiveHighSpeedCount += 1
      }
      
      if !isMoving && consecutiveHighSpeedCount >= Self.requiredConsecutiveHighSpeedReadings {
        // Require multiple consecutive high-speed readings to filter GPS drift
        isMoving = true
        consecutiveHighSpeedCount = 0
        lastBelowSpeedDate = nil
        stopConfirmationTask?.cancel()
        stopConfirmationTask = nil
        delegate?.locationTrackingDidDetectMovementStart(self, location: location)
      } else if isMoving {
        // Already moving, reset any pending stop
        lastBelowSpeedDate = nil
        stopConfirmationTask?.cancel()
        stopConfirmationTask = nil
      }
    } else {
      // Below threshold - reset consecutive count
      consecutiveHighSpeedCount = 0
      
      if isMoving {
        // Below threshold while we think we're moving
        let now = Date()
        if lastBelowSpeedDate == nil {
          lastBelowSpeedDate = now
        }

        // Start or continue stop confirmation timer
        if stopConfirmationTask == nil {
          let capturedLocation = location
          stopConfirmationTask = Task { [weak self] in
            guard let self else { return }
            let ns = UInt64(Self.stopConfirmationSeconds * 1_000_000_000)
            try? await Task.sleep(nanoseconds: ns)

            // After sleep, check if we're still below speed and still monitoring
            guard self.isMonitoring, self.isMoving else { return }
            // If lastBelowSpeedDate is still set, we've been below threshold for the duration
            if self.lastBelowSpeedDate != nil {
              self.isMoving = false
              self.lastBelowSpeedDate = nil
              self.stopConfirmationTask = nil
              self.delegate?.locationTrackingDidDetectMovementStop(self, location: capturedLocation)
            }
          }
        }
      }
    }
  }

  nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
    let nsError = error as NSError
    
    // Handle specific CoreLocation errors
    if nsError.domain == kCLErrorDomain {
      switch CLError.Code(rawValue: nsError.code) {
      case .denied:
        // User denied location access - stop tracking
        Task { @MainActor in
          _ = self.stopTracking()
          self.delegate?.locationTrackingDidFailWithError(self, error: error)
        }
      case .network:
        // Network error - transient, will retry automatically
        break
      case .locationUnknown:
        // Temporary inability to get location - will retry automatically
        break
      default:
        // Log other errors for diagnostics
        Task { @MainActor in
          self.delegate?.locationTrackingDidFailWithError(self, error: error)
        }
      }
    }
  }
}

