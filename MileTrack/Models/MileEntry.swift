import Foundation

struct MileEntry: Identifiable, Equatable, Codable {
  var id: UUID = UUID()
  var date: Date
  var miles: Double
  var note: String?

  var milesFormatted: String {
    let number = miles.formatted(.number.precision(.fractionLength(0...2)))
    return "\(number) mi"
  }
}

