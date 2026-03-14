import SwiftUI

struct PrimaryGlassButton: View {
  let title: String
  var systemImage: String?
  var isEnabled: Bool = true
  var isProminent: Bool = false
  let action: () -> Void

  var body: some View {
    Button(action: action) {
      HStack(spacing: DesignConstants.Spacing.sm) {
        if let systemImage {
          Image(systemName: systemImage)
            .font(.headline)
        }
        Text(title)
          .font(.subheadline.weight(.semibold))
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
      .modifier(GlassEffectModifier(
        isProminent: isProminent,
        cornerRadius: DesignConstants.Radius.button
      ))
    }
    .buttonStyle(.plain)
    .opacity(isEnabled ? 1 : 0.45)
    .disabled(!isEnabled)
    .accessibilityLabel(title)
    .accessibilityHint("Double tap to activate.")
  }
}

private struct GlassEffectModifier: ViewModifier {
  let isProminent: Bool
  let cornerRadius: CGFloat
  
  func body(content: Content) -> some View {
    if #available(iOS 26.0, *) {
      content
        .glassEffect(
          isProminent ? .regular.tint(.accentColor).interactive() : .regular.interactive(),
          in: .rect(cornerRadius: cornerRadius)
        )
    } else {
      // Fallback for iOS 25 and earlier
      content
        .background {
          RoundedRectangle(cornerRadius: cornerRadius)
            .fill(isProminent ? .ultraThinMaterial : .thinMaterial)
            .overlay {
              if isProminent {
                RoundedRectangle(cornerRadius: cornerRadius)
                  .fill(.tint.opacity(0.15))
              }
            }
        }
    }
  }
}

#Preview {
  ZStack {
    LinearGradient(
      colors: [Color.blue.opacity(0.3), Color.purple.opacity(0.3)],
      startPoint: .topLeading,
      endPoint: .bottomTrailing
    )
    .ignoresSafeArea()

    VStack(spacing: 12) {
      PrimaryGlassButton(title: "Add Trip", systemImage: "plus") {}
      PrimaryGlassButton(title: "Upgrade to Pro", systemImage: "sparkles", isProminent: true) {}
      PrimaryGlassButton(title: "Disabled", systemImage: "xmark", isEnabled: false) {}
    }
    .padding()
  }
}

