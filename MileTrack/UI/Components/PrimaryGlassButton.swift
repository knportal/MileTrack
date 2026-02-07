import SwiftUI

struct PrimaryGlassButton: View {
  let title: String
  var systemImage: String?
  var isEnabled: Bool = true
  let action: () -> Void

  var body: some View {
    Button(action: action) {
      HStack(spacing: DesignConstants.Spacing.sm) {
        if let systemImage {
          Image(systemName: systemImage)
            .font(.headline)
        }
        Text(title)
          .font(.headline)
          .lineLimit(1)
          .minimumScaleFactor(0.85)
        Spacer(minLength: 0)
        Image(systemName: "chevron.right")
          .font(.subheadline.weight(.semibold))
          .foregroundStyle(.secondary)
      }
      .padding(.horizontal, DesignConstants.Spacing.md)
      .padding(.vertical, 14)
      .frame(maxWidth: .infinity)
      .background(.thinMaterial, in: RoundedRectangle(cornerRadius: DesignConstants.Radius.button, style: .continuous))
      .overlay {
        RoundedRectangle(cornerRadius: DesignConstants.Radius.button, style: .continuous)
          .strokeBorder(Color.accentColor.opacity(0.30), lineWidth: 1)
      }
    }
    .buttonStyle(.plain)
    .opacity(isEnabled ? 1 : 0.45)
    .disabled(!isEnabled)
    .accessibilityLabel(title)
    .accessibilityHint("Double tap to activate.")
  }
}

#Preview {
  VStack(spacing: 12) {
    PrimaryGlassButton(title: "Add Trip", systemImage: "plus") {}
    PrimaryGlassButton(title: "Upgrade to Pro", systemImage: "sparkles") {}
    PrimaryGlassButton(title: "Disabled", systemImage: "xmark", isEnabled: false) {}
  }
  .padding()
  .background(.ultraThinMaterial)
}

