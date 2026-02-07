import Combine
import Foundation
import SwiftUI

final class MileStore: ObservableObject {
  @Published var entries: [MileEntry] = []

  func add(date: Date, miles: Double, note: String?) {
    let trimmedNote = note?.trimmingCharacters(in: .whitespacesAndNewlines)
    let normalizedNote = (trimmedNote?.isEmpty ?? true) ? nil : trimmedNote

    entries.insert(MileEntry(date: date, miles: miles, note: normalizedNote), at: 0)
  }

  func delete(at offsets: IndexSet) {
    entries.remove(atOffsets: offsets)
  }

  var totalMiles: Double {
    entries.reduce(0) { $0 + $1.miles }
  }

  var totalMilesFormatted: String {
    let number = totalMiles.formatted(.number.precision(.fractionLength(0...1)))
    return "\(number) mi"
  }
}

