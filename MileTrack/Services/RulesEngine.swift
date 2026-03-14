import Foundation

struct RulesEngine {
  struct MatchResult: Equatable {
    var appliedRuleName: String
  }

  func applyFirstMatch(
    to trip: Trip,
    rules: [TripRule],
    calendar: Calendar = .current
  ) -> (Trip, MatchResult?) {
    guard trip.source == .auto, trip.state == .pendingCategory else {
      return (trip, nil)
    }

    for rule in rules where rule.isEnabled {
      if matches(trip: trip, criteria: rule.criteria, calendar: calendar) {
        let updated = apply(action: rule.action, to: trip, ruleName: rule.name)
        return (updated, MatchResult(appliedRuleName: rule.name))
      }
    }
    return (trip, nil)
  }

  private func matches(trip: Trip, criteria: TripRuleCriteria, calendar: Calendar) -> Bool {
    if let window = criteria.timeWindow {
      guard window.contains(date: trip.date, calendar: calendar) else { return false }
    }

    // Legacy: containsText matches either start or end
    if let containsText = normalized(criteria.containsText) {
      let start = normalized(trip.startLabel) ?? ""
      let end = normalized(trip.endLabel) ?? ""
      guard start.contains(containsText) || end.contains(containsText) else { return false }
    }
    
    // New: startContains matches only start address
    if let startContains = normalized(criteria.startContains) {
      let start = normalized(trip.startLabel) ?? ""
      guard start.contains(startContains) else { return false }
    }
    
    // New: endContains matches only end address
    if let endContains = normalized(criteria.endContains) {
      let end = normalized(trip.endLabel) ?? ""
      guard end.contains(endContains) else { return false }
    }

    if let clientContains = normalized(criteria.clientContains) {
      let client = normalized(trip.clientOrOrg) ?? ""
      guard client.contains(clientContains) else { return false }
    }

    // If all provided criteria passed, it's a match.
    return true
  }

  private func apply(action: TripRuleAction, to trip: Trip, ruleName: String) -> Trip {
    var t = trip

    if let category = normalizedPreserveCase(action.setCategory) {
      t.category = category
    }
    if let client = normalizedPreserveCase(action.setClientOrOrg) {
      t.clientOrOrg = client
    }
    if let project = normalizedPreserveCase(action.setProjectCode) {
      t.projectCode = project
    }

    t.suggestedByRuleName = ruleName
    return t
  }

  private func normalized(_ s: String?) -> String? {
    let trimmed = s?.trimmingCharacters(in: .whitespacesAndNewlines)
    guard let trimmed, !trimmed.isEmpty else { return nil }
    return trimmed.lowercased()
  }

  private func normalizedPreserveCase(_ s: String?) -> String? {
    let trimmed = s?.trimmingCharacters(in: .whitespacesAndNewlines)
    guard let trimmed, !trimmed.isEmpty else { return nil }
    return trimmed
  }
}

