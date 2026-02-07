import Foundation

enum SubscriptionTier: String, Codable, CaseIterable {
  case free
  case pro
}

struct SubscriptionStatus: Codable, Equatable {
  var tier: SubscriptionTier
  var isAnnual: Bool

  init(tier: SubscriptionTier, isAnnual: Bool = false) {
    self.tier = tier
    self.isAnnual = isAnnual
  }
}

