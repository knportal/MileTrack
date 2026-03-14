import Foundation

/// Represents an expense receipt attachment for a trip.
struct TripReceipt: Identifiable, Codable, Equatable {
  var id: UUID
  var tripId: UUID
  var type: ReceiptType
  var amount: Decimal?
  var currency: String
  var date: Date
  var notes: String?
  /// File name of the stored image (stored in app's Documents/Receipts folder)
  var imageFileName: String?
  
  init(
    id: UUID = UUID(),
    tripId: UUID,
    type: ReceiptType,
    amount: Decimal? = nil,
    currency: String = "USD",
    date: Date = Date(),
    notes: String? = nil,
    imageFileName: String? = nil
  ) {
    self.id = id
    self.tripId = tripId
    self.type = type
    self.amount = amount
    self.currency = currency
    self.date = date
    self.notes = notes
    self.imageFileName = imageFileName
  }
}

enum ReceiptType: String, CaseIterable, Codable {
  case parking = "Parking"
  case toll = "Toll"
  case fuel = "Fuel"
  case maintenance = "Maintenance"
  case other = "Other"
  
  var displayName: String {
    rawValue
  }
  
  var systemImage: String {
    switch self {
    case .parking: return "parkingsign.circle"
    case .toll: return "road.lanes"
    case .fuel: return "fuelpump"
    case .maintenance: return "wrench.and.screwdriver"
    case .other: return "doc.text"
    }
  }
}
