import SwiftUI

struct EmptyStateView: View {
  let systemImage: String
  let title: String
  let subtitle: String
  var actionTitle: String?
  var action: (() -> Void)?

  var body: some View {
    GlassCard(cornerRadius: 24) {
      VStack(alignment: .center, spacing: 14) {
        Image(systemName: systemImage)
          .font(.system(size: 34, weight: .semibold))
          .foregroundStyle(.secondary)
          .accessibilityHidden(true)

        VStack(spacing: 6) {
          Text(title)
            .font(.headline)
            .multilineTextAlignment(.center)
          Text(subtitle)
            .font(.subheadline)
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.center)
        }

        if let actionTitle, let action {
          PrimaryGlassButton(title: actionTitle, systemImage: "sparkles", action: action)
            .padding(.top, 4)
        }
      }
      .frame(maxWidth: .infinity)
    }
    .accessibilityElement(children: .ignore)
    .accessibilityLabel(title)
    .accessibilityValue(subtitle)
  }
}

#Preview {
  VStack(spacing: 16) {
    EmptyStateView(
      systemImage: "tray",
      title: "Inbox is clear",
      subtitle: "Auto-detected trips will appear here until you categorize them.",
      actionTitle: nil,
      action: nil
    )
    EmptyStateView(
      systemImage: "sparkles",
      title: "Unlock advanced reports",
      subtitle: "Get breakdowns, exports, and templates with Pro.",
      actionTitle: "Upgrade to Pro",
      action: {}
    )
  }
  .padding()
  .background(.ultraThinMaterial)
}

