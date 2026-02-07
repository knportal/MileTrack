import SwiftUI

struct MetricTile: View {
  let title: String
  let value: String
  var systemImage: String?
  var footnote: String?

  var body: some View {
    GlassCard(cornerRadius: 20) {
      VStack(alignment: .leading, spacing: 10) {
        HStack(alignment: .firstTextBaseline, spacing: 10) {
          if let systemImage {
            Image(systemName: systemImage)
              .font(.headline)
              .foregroundStyle(.secondary)
              .accessibilityHidden(true)
          }
          Text(title)
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(.secondary)
            .lineLimit(2)
          Spacer(minLength: 0)
        }

        Text(value)
          .font(.title2.weight(.bold))
          .foregroundStyle(.primary)
          .lineLimit(1)
          .minimumScaleFactor(0.7)

        if let footnote {
          Text(footnote)
            .font(.footnote)
            .foregroundStyle(.secondary)
            .lineLimit(2)
        }
      }
    }
    .accessibilityElement(children: .ignore)
    .accessibilityLabel("\(title), \(value)\(footnote.map { ", \($0)" } ?? "")")
  }
}

#Preview {
  VStack(spacing: 12) {
    MetricTile(title: "This Week", value: "42.7 mi", systemImage: "calendar", footnote: "Confirmed trips only")
    MetricTile(title: "Inbox", value: "3", systemImage: "tray", footnote: "Needs category")
  }
  .padding()
  .background(.ultraThinMaterial)
}

