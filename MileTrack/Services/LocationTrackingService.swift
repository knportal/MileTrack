import CoreLocation
import Foundation

protocol LocationTrackingServiceDelegate: AnyObject {
  func locationTrackingDidUpdateAuthorization(_ service: LocationTrackingService, status: CLAuthorizationStatus)
  func locationTrackingDidUpdateDistance(_ service: LocationTrackingService, distanceMeters: Double)
}

/// Minimal distance accumulator using CoreLocation updates.
final class LocationTrackingService: NSObject {
  weak var delegate: LocationTrackingServiceDelegate?

  private let manager: CLLocationManager
  private(set) var isTracking: Bool = false

  private var lastLocation: CLLocation?
  private var firstLocation: CLLocation?
  private var lastAcceptedLocation: CLLocation?
  private var accumulatedDistanceMeters: Double = 0
  private(set) var startDate: Date?

  init(manager: CLLocationManager = CLLocationManager()) {
    self.manager = manager
    super.init()
    self.manager.delegate = self
    self.manager.activityType = .automotiveNavigation
    self.manager.desiredAccuracy = kCLLocationAccuracyBest
    self.manager.distanceFilter = 15 // meters
    self.manager.pausesLocationUpdatesAutomatically = true
  }

  var authorizationStatus: CLAuthorizationStatus {
    manager.authorizationStatus
  }

  func requestWhenInUse() {
    manager.requestWhenInUseAuthorization()
  }

  func startTracking() {
    guard !isTracking else { return }
    isTracking = true
    startDate = Date()
    lastLocation = nil
    firstLocation = nil
    lastAcceptedLocation = nil
    accumulatedDistanceMeters = 0
    delegate?.locationTrackingDidUpdateDistance(self, distanceMeters: accumulatedDistanceMeters)

    // If not authorized, this won't produce locations; we still keep status visible via delegate.
    manager.startUpdatingLocation()
  }

  func stopTracking() -> (distanceMeters: Double, startDate: Date?, endDate: Date) {
    let end = Date()
    if isTracking {
      manager.stopUpdatingLocation()
    }
    isTracking = false
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
    if isTracking {
      manager.stopUpdatingLocation()
    }
    isTracking = false
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
    if isTracking {
      manager.stopUpdatingLocation()
    }
    isTracking = false
    startDate = nil
    lastLocation = nil
    firstLocation = nil
    lastAcceptedLocation = nil
    accumulatedDistanceMeters = 0
  }

  private func acceptLocation(_ location: CLLocation) -> Bool {
    // MVP filters: ignore invalid/very inaccurate locations.
    guard location.horizontalAccuracy >= 0 else { return false }
    return location.horizontalAccuracy <= 65
  }
}

extension LocationTrackingService: CLLocationManagerDelegate {
  func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
    delegate?.locationTrackingDidUpdateAuthorization(self, status: manager.authorizationStatus)
  }

  func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
    guard isTracking else { return }
    for location in locations where acceptLocation(location) {
      if firstLocation == nil {
        firstLocation = location
      }
      if let last = lastLocation {
        let delta = location.distance(from: last)
        if delta > 0 {
          accumulatedDistanceMeters += delta
          delegate?.locationTrackingDidUpdateDistance(self, distanceMeters: accumulatedDistanceMeters)
        }
      }
      lastLocation = location
      lastAcceptedLocation = location
    }
  }

  func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
    // MVP: best-effort, ignore.
  }
}

