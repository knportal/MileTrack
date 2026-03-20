import SwiftUI

enum DesignConstants {
  enum Spacing {
    static let xs: CGFloat = 8
    static let sm: CGFloat = 12
    static let md: CGFloat = 16
    static let lg: CGFloat = 24
    static let xl: CGFloat = 32
  }

  enum Radius {
    static let small: CGFloat = 12
    static let button: CGFloat = 18
    static let card: CGFloat = 24
    static let large: CGFloat = 28
  }

  enum Stroke {
    static let opacity: CGFloat = 0.08
    static let width: CGFloat = 0.5
  }

  enum Shadow {
    static let color: Color = .black
    static let opacity: CGFloat = 0.08
    static let radius: CGFloat = 20
    static let y: CGFloat = 12
  }

  enum Glow {
    static let color: Color = .accentColor
    static let opacity: Double = 0.20
    static let radius: CGFloat = 14
  }

  enum Typography {
    static let largeTitle: Font = Font.custom("Manrope", size: 34, relativeTo: .largeTitle).weight(.bold)
    static let title: Font = Font.custom("Manrope", size: 22, relativeTo: .title2).weight(.semibold)
    static let headline: Font = Font.custom("Manrope", size: 17, relativeTo: .headline).weight(.semibold)
    static let body: Font = Font.custom("Manrope", size: 17, relativeTo: .body)
    static let caption: Font = Font.custom("Manrope", size: 12, relativeTo: .caption).weight(.medium)
  }

  enum GlassEffect {
    static let containerSpacing: CGFloat = 20
  }

  enum CardDepth {
    case base, surface, elevated

    var overlayOpacity: Double {
      switch self {
      case .base: return 0.0
      case .surface: return 0.04
      case .elevated: return 0.08
      }
    }
  }

  /// Maximum content width on iPad to prevent overly wide layouts.
  static let iPadMaxContentWidth: CGFloat = 600

  enum TextLimits {
    static let shortName: Int = 50       // Category, client, location names
    static let mediumText: Int = 100     // Vehicle names, license plates
    static let notes: Int = 500          // Notes, descriptions
    static let address: Int = 200        // Address fields
  }
}

// MARK: - Text Field Length Limiting

extension Binding where Value == String {
  /// Returns a new Binding that limits the string to a maximum length.
  func max(_ limit: Int) -> Binding<String> {
    Binding<String>(
      get: { self.wrappedValue },
      set: { newValue in
        if newValue.count > limit {
          self.wrappedValue = String(newValue.prefix(limit))
        } else {
          self.wrappedValue = newValue
        }
      }
    )
  }
}
