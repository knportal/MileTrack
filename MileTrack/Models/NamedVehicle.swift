import Foundation

struct NamedVehicle: Identifiable, Codable, Equatable {
  var id: UUID
  var name: String
  var licensePlate: String
  var notes: String

  init(id: UUID = UUID(), name: String, licensePlate: String = "", notes: String = "") {
    self.id = id
    self.name = name
    self.licensePlate = licensePlate
    self.notes = notes
  }
}
