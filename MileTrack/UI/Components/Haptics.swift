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
}

