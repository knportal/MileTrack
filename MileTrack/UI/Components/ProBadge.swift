import SwiftUI

struct ProBadge: View {
  var body: some View {
    Text("PRO")
      .font(.caption2.weight(.bold))
      .tracking(0.6)
      .padding(.horizontal, 8)
      .padding(.vertical, 5)
      .background(.thinMaterial, in: Capsule())
      .overlay {
        Capsule()
          .strokeBorder(Color.primary.opacity(0.14), lineWidth: DesignConstants.Stroke.width)
      }
      .accessibilityLabel("Pro")
      .accessibilityHint("Indicates a Pro feature.")
  }
}

struct LockedOverlay: View {
  var message: String = "Pro feature"

  var body: some View {
    ZStack {
      RoundedRectangle(cornerRadius: DesignConstants.Radius.card, style: .continuous)
        .fill(.ultraThinMaterial)
        .overlay {
          RoundedRectangle(cornerRadius: DesignConstants.Radius.card, style: .continuous)
            .strokeBorder(Color.primary.opacity(DesignConstants.Stroke.opacity), lineWidth: DesignConstants.Stroke.width)
        }

      VStack(spacing: 10) {
        HStack(spacing: 8) {
          Image(systemName: "lock.fill")
            .font(.footnote.weight(.semibold))
            .foregroundStyle(.secondary)
            .accessibilityHidden(true)
          Text(message)
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(.secondary)
          ProBadge()
            .accessibilityHidden(true)
        }
      }
      .padding(14)
    }
    .accessibilityElement(children: .ignore)
    .accessibilityLabel(message)
    .accessibilityValue("Locked")
  }
}

#Preview {
  VStack(spacing: 14) {
    ProBadge()
    ZStack {
      GlassCard {
        VStack(alignment: .leading, spacing: 8) {
          Text("Advanced Reports")
            .font(.headline)
          Text("Export, breakdowns, and more.")
            .foregroundStyle(.secondary)
        }
      }
      LockedOverlay(message: "Advanced Reports")
        .padding(6)
    }
  }
  .padding()
  .background(.ultraThinMaterial)
}

