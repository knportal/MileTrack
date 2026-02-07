import SwiftUI

struct CategoryChip: View {
  let title: String
  var isSelected: Bool
  var action: () -> Void

  var body: some View {
    Button(action: action) {
      HStack(spacing: 8) {
        if isSelected {
          Image(systemName: "checkmark.circle.fill")
            .imageScale(.small)
        }
        Text(title)
          .font(.subheadline.weight(.semibold))
          .lineLimit(1)
      }
      .padding(.horizontal, 12)
      .padding(.vertical, 8)
      .background(backgroundMaterial, in: Capsule())
      .overlay {
        Capsule()
          .strokeBorder(borderColor, lineWidth: 1)
      }
      .foregroundStyle(foregroundStyle)
    }
    .buttonStyle(.plain)
    .accessibilityLabel(title)
    .accessibilityValue(isSelected ? "Selected" : "Not selected")
    .accessibilityHint("Double tap to select category.")
  }

  private var backgroundMaterial: Material {
    isSelected ? .thinMaterial : .ultraThinMaterial
  }

  private var borderColor: Color {
    isSelected ? Color.accentColor.opacity(0.35) : Color.primary.opacity(0.10)
  }

  private var foregroundStyle: some ShapeStyle {
    isSelected ? AnyShapeStyle(Color.primary) : AnyShapeStyle(Color.primary)
  }
}

#Preview {
  VStack(alignment: .leading, spacing: 12) {
    HStack {
      CategoryChip(title: "Business", isSelected: true) {}
      CategoryChip(title: "Volunteer", isSelected: false) {}
      CategoryChip(title: "Medical", isSelected: false) {}
    }
    HStack {
      CategoryChip(title: "Education", isSelected: true) {}
      CategoryChip(title: "Personal", isSelected: false) {}
      CategoryChip(title: "Custom", isSelected: false) {}
    }
  }
  .padding()
  .background(.ultraThinMaterial)
}

