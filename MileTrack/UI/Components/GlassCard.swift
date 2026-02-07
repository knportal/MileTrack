import SwiftUI

struct GlassCard<Content: View>: View {
  private let cornerRadius: CGFloat
  private let content: Content

  init(
    cornerRadius: CGFloat = DesignConstants.Radius.card,
    @ViewBuilder content: () -> Content
  ) {
    self.cornerRadius = cornerRadius
    self.content = content()
  }

  var body: some View {
    content
      .padding(DesignConstants.Spacing.md)
      .frame(maxWidth: .infinity, alignment: .leading)
      .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
      .overlay {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
          .strokeBorder(Color.primary.opacity(DesignConstants.Stroke.opacity), lineWidth: DesignConstants.Stroke.width)
      }
      .shadow(
        color: DesignConstants.Shadow.color.opacity(DesignConstants.Shadow.opacity),
        radius: DesignConstants.Shadow.radius,
        y: DesignConstants.Shadow.y
      )
      .accessibilityElement(children: .contain)
  }
}

#Preview {
  ZStack {
    LinearGradient(
      colors: [Color.primary.opacity(0.06), Color.secondary.opacity(0.08)],
      startPoint: .topLeading,
      endPoint: .bottomTrailing
    )
    .ignoresSafeArea()

    GlassCard {
      VStack(alignment: .leading, spacing: 8) {
        Text("GlassCard")
          .font(.headline)
        Text("Material background, hairline stroke, subtle shadow.")
          .foregroundStyle(.secondary)
      }
    }
    .padding()
  }
}

