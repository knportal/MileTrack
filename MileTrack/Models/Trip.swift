import Foundation

enum TripSource: String, Codable, CaseIterable {
  case manual
  case auto
}

enum TripState: String, Codable, CaseIterable {
  case pendingCategory = "pending_category"
  case confirmed
  case ignored
}

struct Trip: Identifiable, Codable, Equatable {
  var id: UUID
  var date: Date
  var distanceMiles: Double
  var durationSeconds: Int?
  var startLabel: String?
  var endLabel: String?
  var source: TripSource
  var state: TripState
  /// Category is kept as a simple string for UI friendliness; see `TripCategory` for typed options.
  var category: String?
  var clientOrOrg: String?
  /// Optional project/job code (free text MVP).
  var projectCode: String?
  /// If present, the trip was prefilled by this rule and should show as a suggestion in Inbox.
  var suggestedByRuleName: String?
  var notes: String?

  init(
    id: UUID = UUID(),
    date: Date,
    distanceMiles: Double,
    durationSeconds: Int? = nil,
    startLabel: String? = nil,
    endLabel: String? = nil,
    source: TripSource,
    state: TripState,
    category: String? = nil,
    clientOrOrg: String? = nil,
    projectCode: String? = nil,
    suggestedByRuleName: String? = nil,
    notes: String? = nil
  ) {
    self.id = id
    self.date = date
    self.distanceMiles = distanceMiles
    self.durationSeconds = durationSeconds
    self.startLabel = startLabel
    self.endLabel = endLabel
    self.source = source
    self.state = state
    self.category = category
    self.clientOrOrg = clientOrOrg
    self.projectCode = projectCode
    self.suggestedByRuleName = suggestedByRuleName
    self.notes = notes
  }
}

