import UIKit

/// Subtle haptics for primary actions (optional polish).
enum Haptics {
  static func success() {
    let gen = UINotificationFeedbackGenerator()
    gen.prepare()
    gen.notificationOccurred(.success)
  }

  static func warning() {
    let gen = UINotificationFeedbackGenerator()
    gen.prepare()
    gen.notificationOccurred(.warning)
  }

  static func error() {
    let gen = UINotificationFeedbackGenerator()
    gen.prepare()
    gen.notificationOccurred(.error)
  }

  static func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .medium) {
    let gen = UIImpactFeedbackGenerator(style: style)
    gen.prepare()
    gen.impactOccurred()
  }
}

