import SwiftUI

struct GlassCard<Content: View>: View {
  private let cornerRadius: CGFloat
  private let isInteractive: Bool
  private let showGlow: Bool
  private let depth: DesignConstants.CardDepth
  private let content: Content

  init(
    cornerRadius: CGFloat = DesignConstants.Radius.card,
    isInteractive: Bool = false,
    showGlow: Bool = false,
    depth: DesignConstants.CardDepth = .surface,
    @ViewBuilder content: () -> Content
  ) {
    self.cornerRadius = cornerRadius
    self.isInteractive = isInteractive
    self.showGlow = showGlow
    self.depth = depth
    self.content = content()
  }

  var body: some View {
    content
      .padding(DesignConstants.Spacing.md)
      .frame(maxWidth: .infinity, alignment: .leading)
      .modifier(GlassEffectModifier(
        cornerRadius: cornerRadius,
        isInteractive: isInteractive,
        depth: depth
      ))
      .background {
        if showGlow {
          RoundedRectangle(cornerRadius: cornerRadius)
            .fill(.clear)
            .shadow(
              color: Color.accentColor.opacity(DesignConstants.Glow.opacity),
              radius: DesignConstants.Glow.radius
            )
        }
      }
      .accessibilityElement(children: .contain)
  }
}

private struct GlassEffectModifier: ViewModifier {
  let cornerRadius: CGFloat
  let isInteractive: Bool
  let depth: DesignConstants.CardDepth

  @Environment(\.colorScheme) private var colorScheme

  private var gradientBorder: some ShapeStyle {
    LinearGradient(
      colors: colorScheme == .dark
        ? [Color.white.opacity(0.14), Color.white.opacity(0.03)]
        : [Color.black.opacity(0.10), Color.black.opacity(0.02)],
      startPoint: .topLeading,
      endPoint: .bottomTrailing
    )
  }

  func body(content: Content) -> some View {
    if #available(iOS 26.0, *) {
      content
        .glassEffect(
          isInteractive ? .regular.interactive() : .regular,
          in: .rect(cornerRadius: cornerRadius)
        )
        .overlay {
          RoundedRectangle(cornerRadius: cornerRadius)
            .strokeBorder(gradientBorder, lineWidth: 0.5)
        }
        .overlay {
          if depth != .base {
            RoundedRectangle(cornerRadius: cornerRadius)
              .fill(
                colorScheme == .dark
                  ? Color.white.opacity(depth.overlayOpacity)
                  : Color.black.opacity(depth.overlayOpacity * 0.03)
              )
              .allowsHitTesting(false)
          }
        }
    } else {
      content
        .background {
          RoundedRectangle(cornerRadius: cornerRadius)
            .fill(colorScheme == .dark ? .ultraThinMaterial : .thinMaterial)
        }
        .overlay {
          RoundedRectangle(cornerRadius: cornerRadius)
            .strokeBorder(gradientBorder, lineWidth: 0.5)
        }
        .overlay {
          if depth != .base {
            RoundedRectangle(cornerRadius: cornerRadius)
              .fill(
                colorScheme == .dark
                  ? Color.white.opacity(depth.overlayOpacity)
                  : Color.black.opacity(depth.overlayOpacity * 0.03)
              )
              .allowsHitTesting(false)
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

    VStack(spacing: 16) {
      GlassCard(showGlow: true, depth: .elevated) {
        VStack(alignment: .leading, spacing: 8) {
          Text("Elevated + Glow")
            .font(.headline)
          Text("Ambient accent glow + elevated depth layer.")
            .foregroundStyle(.secondary)
        }
      }

      GlassCard(depth: .surface) {
        VStack(alignment: .leading, spacing: 8) {
          Text("Surface Depth")
            .font(.headline)
          Text("Subtle depth with gradient border.")
            .foregroundStyle(.secondary)
        }
      }

      GlassCard(isInteractive: true) {
        VStack(alignment: .leading, spacing: 8) {
          Text("Interactive Card")
            .font(.headline)
          Text("Responds to touch with fluid animations.")
            .foregroundStyle(.secondary)
        }
      }
    }
    .padding()
  }
}
