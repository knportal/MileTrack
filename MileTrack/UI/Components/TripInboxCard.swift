import SwiftUI

struct TripInboxCard: View {
  @EnvironmentObject private var categoriesStore: CategoriesStore

  let trip: Trip
  let selectedCategory: String?
  let onSelectCategory: (String) -> Void
  let onEdit: () -> Void

  @AppStorage("useMetricUnits") private var useMetricUnits = false

  @State private var isPresentingAddCategory: Bool = false
  @State private var newCategoryName: String = ""
  @State private var addCategoryError: String?

  var body: some View {
    GlassCard {
      VStack(alignment: .leading, spacing: DesignConstants.Spacing.sm) {
        header
        if let suggestedLine {
          Text(suggestedLine)
            .font(.footnote.weight(.semibold))
            .foregroundStyle(.secondary)
            .accessibilityLabel("Suggested")
            .accessibilityValue(suggestedLine)
        }
        categoryDropdown
      }
    }
    .accessibilityElement(children: .contain)
    .accessibilityLabel("Inbox trip, \(trip.routeLabel), \(distanceLabel)")
    .accessibilityValue(selectedCategoryLabel)
    .alert("Add New Category", isPresented: $isPresentingAddCategory) {
      TextField("Category name", text: $newCategoryName)
      Button("Add") { addCategory() }
      Button("Cancel", role: .cancel) {}
    } message: {
      Text("Names can't be empty or duplicates.")
    }
  }

  // MARK: - Header (route + metadata + distance/edit)

  private var header: some View {
    HStack(alignment: .top, spacing: 12) {
      VStack(alignment: .leading, spacing: 6) {
        routeSection
        dateTimeRow
      }

      Spacer(minLength: 0)

      VStack(alignment: .trailing, spacing: 6) {
        Text(distanceLabel)
          .font(.subheadline.weight(.semibold))

        Button {
          onEdit()
        } label: {
          Image(systemName: "pencil")
            .font(.footnote.weight(.semibold))
            .padding(8)
            .background(.thinMaterial, in: Circle())
            .overlay {
              Circle()
                .strokeBorder(Color.primary.opacity(0.10), lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Edit")
        .accessibilityHint("Opens categorize trip sheet.")
      }
    }
  }

  // MARK: - Route Section
  // Shows full addresses (with colored dots) when both are available.
  // Falls back to a single-line label route when addresses are missing.

  @ViewBuilder
  private var routeSection: some View {
    let startAddr = trip.startAddress?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    let endAddr   = trip.endAddress?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

    if !startAddr.isEmpty && !endAddr.isEmpty {
      VStack(alignment: .leading, spacing: 4) {
        locationLine(startAddr, isStart: true)
        if let stops = trip.waypoints?.filter({ !$0.isEmpty }), !stops.isEmpty {
          ForEach(stops, id: \.self) { stop in
            HStack(alignment: .top, spacing: 8) {
              Circle()
                .fill(Color.secondary.opacity(0.35))
                .frame(width: 6, height: 6)
                .padding(.top, 5)
                .padding(.leading, 1)
              Text(stop)
                .font(.footnote)
                .foregroundStyle(.secondary)
                .lineLimit(1)
            }
          }
        }
        locationLine(endAddr, isStart: false)
      }
    } else {
      Text(trip.routeLabel)
        .font(.subheadline.weight(.semibold))
        .lineLimit(2)
        .minimumScaleFactor(0.85)
    }
  }

  private func locationLine(_ text: String, isStart: Bool) -> some View {
    HStack(alignment: .top, spacing: 8) {
      Circle()
        .fill(isStart ? Color.green : Color.red)
        .frame(width: 7, height: 7)
        .padding(.top, 4)
      Text(text)
        .font(.footnote.weight(.medium))
        .lineLimit(2)
    }
  }

  private var dateTimeRow: some View {
    HStack(spacing: 6) {
      Text(trip.date, format: .dateTime.month(.abbreviated).day().hour().minute())
        .foregroundStyle(.secondary)
      if let seconds = trip.durationSeconds, seconds > 0 {
        Text("·")
          .foregroundStyle(.tertiary)
        Text(durationLabel(seconds))
          .foregroundStyle(.secondary)
      }
    }
    .font(.footnote)
  }

  // MARK: - Category Dropdown

  private var categoryDropdown: some View {
    VStack(alignment: .leading, spacing: 8) {
      Text("Category required to confirm")
        .font(.footnote.weight(.semibold))
        .foregroundStyle(.secondary)
        .accessibilityHidden(true)

      Menu {
        ForEach(categoriesStore.categories, id: \.self) { category in
          Button(category) {
            onSelectCategory(category)
          }
        }
        Divider()
        Button("+ Add New Category…") {
          newCategoryName = ""
          addCategoryError = nil
          isPresentingAddCategory = true
        }
      } label: {
        HStack(spacing: 10) {
          Text(selectedCategoryDisplay)
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(selectedCategory == nil ? .secondary : .primary)
          Spacer(minLength: 0)
          Image(systemName: "chevron.up.chevron.down")
            .font(.footnote.weight(.semibold))
            .foregroundStyle(.secondary)
            .accessibilityHidden(true)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay {
          RoundedRectangle(cornerRadius: 14, style: .continuous)
            .strokeBorder(Color.primary.opacity(DesignConstants.Stroke.opacity), lineWidth: DesignConstants.Stroke.width)
        }
      }
      .buttonStyle(.plain)
      .accessibilityLabel("Category")
      .accessibilityValue(selectedCategoryDisplay)
      .accessibilityHint("Double tap to choose a category.")

      if let addCategoryError {
        Text(addCategoryError)
          .font(.footnote)
          .foregroundStyle(.red)
      }
    }
  }

  // MARK: - Helpers

  private var canConfirm: Bool {
    guard let selectedCategory else { return false }
    return !selectedCategory.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
  }

  private var selectedCategoryDisplay: String {
    let trimmed = selectedCategory?.trimmingCharacters(in: .whitespacesAndNewlines)
    if let trimmed, !trimmed.isEmpty { return trimmed }
    return "Select category"
  }

  private var selectedCategoryLabel: String {
    if canConfirm, let selectedCategory {
      return "Category \(selectedCategory)"
    }
    return "No category selected"
  }

  private var distanceLabel: String {
    DistanceFormatter.format(trip.distanceMiles)
  }

  private func durationLabel(_ seconds: Int) -> String {
    let minutes = max(0, seconds / 60)
    if minutes < 60 { return "\(minutes)m" }
    let hours = minutes / 60
    let rem = minutes % 60
    return rem == 0 ? "\(hours)h" : "\(hours)h \(rem)m"
  }

  private func addCategory() {
    let trimmed = newCategoryName.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty else {
      addCategoryError = "Please enter a category name."
      return
    }

    if categoriesStore.add(trimmed) {
      onSelectCategory(trimmed)
      addCategoryError = nil
    } else {
      addCategoryError = "That category already exists."
    }
  }

  private var suggestedLine: String? {
    guard trip.source == .auto, trip.state == .pendingCategory else { return nil }
    guard trip.suggestedByRuleName != nil else { return nil }

    var parts: [String] = []
    if let category = trip.category?.trimmingCharacters(in: .whitespacesAndNewlines), !category.isEmpty {
      parts.append(category)
    }
    if let client = trip.clientOrOrg?.trimmingCharacters(in: .whitespacesAndNewlines), !client.isEmpty {
      parts.append(client)
    }
    if let project = trip.projectCode?.trimmingCharacters(in: .whitespacesAndNewlines), !project.isEmpty {
      parts.append(project)
    }
    guard !parts.isEmpty else { return nil }
    return "Suggested: " + parts.joined(separator: " • ")
  }
}

#if DEBUG
#Preview {
  TripInboxCard(
    trip: TripStore.makeMockTrips().first { $0.state == .pendingCategory }!,
    selectedCategory: nil,
    onSelectCategory: { _ in },
    onEdit: {}
  )
  .padding()
  .background(.ultraThinMaterial)
  .environmentObject(CategoriesStore())
  .environmentObject(ClientsStore())
}
#endif
