import CoreLocation
import Foundation

struct NamedLocation: Identifiable, Codable, Equatable {
  var id: UUID
  var name: String
  var address: String
  var latitude: Double?
  var longitude: Double?

  init(id: UUID = UUID(), name: String, address: String, latitude: Double? = nil, longitude: Double? = nil) {
    self.id = id
    self.name = name
    self.address = address
    self.latitude = latitude
    self.longitude = longitude
  }

  /// Returns a CLLocation if both coordinates are set.
  var coordinate: CLLocation? {
    guard let latitude, let longitude else { return nil }
    return CLLocation(latitude: latitude, longitude: longitude)
  }

  /// Distance in meters from a given location, or nil if no coordinates set.
  func distance(from location: CLLocation) -> Double? {
    coordinate?.distance(from: location)
  }
}
