import SwiftUI

struct MetricTile: View {
  let title: String
  let value: String
  var systemImage: String?
  var footnote: String?

  var body: some View {
    VStack(alignment: .leading, spacing: 10) {
      HStack(alignment: .firstTextBaseline, spacing: 8) {
        if let systemImage {
          Image(systemName: systemImage)
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(.secondary)
            .accessibilityHidden(true)
        }
        Text(title)
          .font(.subheadline.weight(.medium))
          .foregroundStyle(.secondary)
          .lineLimit(2)
        Spacer(minLength: 0)
      }

      Text(value)
        .font(.title2.weight(.bold))
        .foregroundStyle(.primary)
        .lineLimit(1)
        .minimumScaleFactor(0.7)
        .contentTransition(.numericText())
        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: value)

      if let footnote {
        Text(footnote)
          .font(.caption)
          .foregroundStyle(.tertiary)
          .lineLimit(2)
      }
    }
    .padding(DesignConstants.Spacing.md)
    .frame(maxWidth: .infinity, alignment: .leading)
    .modifier(GlassEffectModifier(cornerRadius: DesignConstants.Radius.card))
    .accessibilityElement(children: .ignore)
    .accessibilityLabel("\(title), \(value)\(footnote.map { ", \($0)" } ?? "")")
  }
}

private struct GlassEffectModifier: ViewModifier {
  let cornerRadius: CGFloat
  
  func body(content: Content) -> some View {
    if #available(iOS 26.0, *) {
      content
        .glassEffect(.regular, in: .rect(cornerRadius: cornerRadius))
    } else {
      // Fallback for iOS 25 and earlier
      content
        .background {
          RoundedRectangle(cornerRadius: cornerRadius)
            .fill(.ultraThinMaterial)
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
      HStack(spacing: 12) {
        MetricTile(title: "This Week", value: "42.7 mi", systemImage: "calendar", footnote: "Confirmed trips only")
        MetricTile(title: "Inbox", value: "3", systemImage: "tray", footnote: "Needs category")
      }
    }
    .padding()
  }
}

