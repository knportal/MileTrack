import Foundation

/// A typed wrapper for trip categories.
/// For UI/storage simplicity, the `Trip` model stores `category` as a `String?` for now.
enum TripCategory: Hashable {
  case business
  case volunteer
  case medical
  case education
  case personal
  case custom(String)
}

extension TripCategory {
  /// Canonical display/storage string.
  var stringValue: String {
    switch self {
    case .business: return "Business"
    case .volunteer: return "Volunteer"
    case .medical: return "Medical"
    case .education: return "Education"
    case .personal: return "Personal"
    case .custom(let value):
      let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
      return trimmed.isEmpty ? "Custom" : trimmed
    }
  }

  init(stringValue: String) {
    let trimmed = stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
    switch trimmed.lowercased() {
    case "business": self = .business
    case "volunteer": self = .volunteer
    case "medical": self = .medical
    case "education": self = .education
    case "personal": self = .personal
    default: self = .custom(trimmed)
    }
  }
}

