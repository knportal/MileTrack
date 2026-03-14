import Foundation

struct NamedLocation: Identifiable, Codable, Equatable {
  var id: UUID
  var name: String
  var address: String

  init(id: UUID = UUID(), name: String, address: String) {
    self.id = id
    self.name = name
    self.address = address
  }
}
