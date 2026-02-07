import Foundation

struct RuleTimeWindow: Codable, Equatable {
  /// Minutes since midnight local time (0...1439).
  var startMinutes: Int
  var endMinutes: Int

  init(startMinutes: Int, endMinutes: Int) {
    self.startMinutes = max(0, min(1439, startMinutes))
    self.endMinutes = max(0, min(1439, endMinutes))
  }

  func contains(date: Date, calendar: Calendar = .current) -> Bool {
    let comps = calendar.dateComponents([.hour, .minute], from: date)
    let m = (comps.hour ?? 0) * 60 + (comps.minute ?? 0)

    if startMinutes <= endMinutes {
      return m >= startMinutes && m <= endMinutes
    }
    // Wrap-around window (e.g., 22:00–02:00).
    return m >= startMinutes || m <= endMinutes
  }
}

struct TripRuleCriteria: Codable, Equatable {
  /// Case-insensitive substring match against start/end labels.
  var containsText: String?
  /// Case-insensitive substring match against existing client (if any).
  var clientContains: String?
  var timeWindow: RuleTimeWindow?

  init(containsText: String? = nil, clientContains: String? = nil, timeWindow: RuleTimeWindow? = nil) {
    self.containsText = containsText
    self.clientContains = clientContains
    self.timeWindow = timeWindow
  }
}

struct TripRuleAction: Codable, Equatable {
  var setCategory: String?
  var setClientOrOrg: String?
  var setProjectCode: String?

  init(setCategory: String? = nil, setClientOrOrg: String? = nil, setProjectCode: String? = nil) {
    self.setCategory = setCategory
    self.setClientOrOrg = setClientOrOrg
    self.setProjectCode = setProjectCode
  }
}

struct TripRule: Identifiable, Codable, Equatable {
  var id: UUID
  var name: String
  var isEnabled: Bool
  var criteria: TripRuleCriteria
  var action: TripRuleAction

  init(
    id: UUID = UUID(),
    name: String,
    isEnabled: Bool = true,
    criteria: TripRuleCriteria,
    action: TripRuleAction
  ) {
    self.id = id
    self.name = name
    self.isEnabled = isEnabled
    self.criteria = criteria
    self.action = action
  }
}

