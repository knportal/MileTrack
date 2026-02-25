import SwiftUI

struct CreateRuleSheet: View {
  @Environment(\.dismiss) private var dismiss
  @EnvironmentObject private var categoriesStore: CategoriesStore
  @EnvironmentObject private var clientStore: ClientsStore
  @EnvironmentObject private var locationsStore: LocationsStore

  let onCreate: (TripRule) -> Void

  @State private var name: String = ""
  @State private var startAddress: String = ""
  @State private var endAddress: String = ""

  @State private var selectedCategory: String?
  @State private var selectedClient: String?
  @State private var projectCode: String = ""

  @State private var limitToTimeWindow: Bool = false
  @State private var windowStart: Date = Date()
  @State private var windowEnd: Date = Date()

  @State private var errorMessage: String?

  var body: some View {
    NavigationStack {
      ScrollView {
        VStack(alignment: .leading, spacing: 14) {
          ruleCard
          suggestCard
          errorMessageView
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
      }
      .background(.background)
      .navigationTitle("New Rule")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button("Cancel") { dismiss() }
        }
        ToolbarItem(placement: .confirmationAction) {
          Button("Create") { create() }
            .disabled(!canCreate)
        }
      }
    }
    .presentationBackground(.ultraThinMaterial)
  }

  // MARK: - Rule Card

  private var ruleCard: some View {
    GlassCard {
      VStack(alignment: .leading, spacing: 12) {
        Text("Rule")
          .font(.headline)
        nameField
        startAddressField
        endAddressField
        timeWindowToggle
      }
    }
  }

  private var nameField: some View {
    VStack(alignment: .leading, spacing: 6) {
      Text("Name")
        .font(.caption)
        .foregroundStyle(.secondary)
      TextField("e.g. Work commute", text: $name)
        .textInputAutocapitalization(.words)
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay {
          RoundedRectangle(cornerRadius: 12, style: .continuous)
            .strokeBorder(Color.primary.opacity(0.08), lineWidth: 1)
        }
        .accessibilityLabel("Rule name")
    }
  }

  private var startAddressField: some View {
    VStack(alignment: .leading, spacing: 6) {
      Text("Start address contains")
        .font(.caption)
        .foregroundStyle(.secondary)
      HStack(spacing: 8) {
        TextField("e.g. Home, 123 Main St", text: $startAddress)
          .textInputAutocapitalization(.never)
          .padding(.horizontal, 14)
          .padding(.vertical, 12)
          .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
          .overlay {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
              .strokeBorder(Color.primary.opacity(0.08), lineWidth: 1)
          }
          .accessibilityLabel("Start address match")

        startLocationPicker
      }
    }
  }

  @ViewBuilder
  private var startLocationPicker: some View {
    if !locationsStore.locations.isEmpty {
      Menu {
        ForEach(locationsStore.locations) { location in
          Button {
            startAddress = location.address.isEmpty ? location.name : location.address
          } label: {
            Label(location.name, systemImage: "mappin")
          }
        }
      } label: {
        Image(systemName: "mappin.circle.fill")
          .font(.title2)
          .foregroundStyle(Color.accentColor)
      }
      .accessibilityLabel("Select saved location")
    }
  }

  private var endAddressField: some View {
    VStack(alignment: .leading, spacing: 6) {
      Text("End address contains")
        .font(.caption)
        .foregroundStyle(.secondary)
      HStack(spacing: 8) {
        TextField("e.g. Office, Work", text: $endAddress)
          .textInputAutocapitalization(.never)
          .padding(.horizontal, 14)
          .padding(.vertical, 12)
          .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
          .overlay {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
              .strokeBorder(Color.primary.opacity(0.08), lineWidth: 1)
          }
          .accessibilityLabel("End address match")

        endLocationPicker
      }
      Text("Leave empty to match any address")
        .font(.caption2)
        .foregroundStyle(.tertiary)
    }
  }

  @ViewBuilder
  private var endLocationPicker: some View {
    if !locationsStore.locations.isEmpty {
      Menu {
        ForEach(locationsStore.locations) { location in
          Button {
            endAddress = location.address.isEmpty ? location.name : location.address
          } label: {
            Label(location.name, systemImage: "mappin")
          }
        }
      } label: {
        Image(systemName: "mappin.circle.fill")
          .font(.title2)
          .foregroundStyle(Color.accentColor)
      }
      .accessibilityLabel("Select saved location")
    }
  }

  private var timeWindowToggle: some View {
    VStack(alignment: .leading, spacing: 8) {
      Toggle(isOn: $limitToTimeWindow) {
        Text("Limit to time window")
          .font(.subheadline.weight(.medium))
      }
      .tint(.accentColor)

      if limitToTimeWindow {
        HStack {
          DatePicker("Start", selection: $windowStart, displayedComponents: [.hourAndMinute])
            .labelsHidden()
          Spacer()
          DatePicker("End", selection: $windowEnd, displayedComponents: [.hourAndMinute])
            .labelsHidden()
        }
        .font(.subheadline)
        .foregroundStyle(.secondary)
      }
    }
  }

  // MARK: - Suggest Card

  private var suggestCard: some View {
    GlassCard {
      VStack(alignment: .leading, spacing: 12) {
        Text("Suggest")
          .font(.headline)

        Text("When this rule matches, auto-fill these fields:")
          .font(.caption)
          .foregroundStyle(.secondary)

        categoryPicker
        clientPicker
        projectCodeField
      }
    }
  }

  private var categoryPicker: some View {
    VStack(alignment: .leading, spacing: 6) {
      Text("Category")
        .font(.caption)
        .foregroundStyle(.secondary)

      Menu {
        Button {
          selectedCategory = nil
        } label: {
          if selectedCategory == nil {
            Label("None", systemImage: "checkmark")
          } else {
            Text("None")
          }
        }

        Divider()

        ForEach(categoriesStore.categories, id: \.self) { category in
          Button {
            selectedCategory = category
          } label: {
            if selectedCategory == category {
              Label(category, systemImage: "checkmark")
            } else {
              Text(category)
            }
          }
        }
      } label: {
        categoryPickerLabel
      }
      .buttonStyle(.plain)
      .accessibilityLabel("Suggested category")
      .accessibilityValue(selectedCategory ?? "None")
    }
  }

  private var categoryPickerLabel: some View {
    HStack {
      Text(selectedCategory ?? "None")
        .foregroundStyle(selectedCategory != nil ? .primary : .secondary)
      Spacer()
      Image(systemName: "chevron.up.chevron.down")
        .font(.caption)
        .foregroundStyle(.secondary)
    }
    .padding(.horizontal, 14)
    .padding(.vertical, 12)
    .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    .overlay {
      RoundedRectangle(cornerRadius: 12, style: .continuous)
        .strokeBorder(Color.primary.opacity(0.08), lineWidth: 1)
    }
  }

  private var clientPicker: some View {
    VStack(alignment: .leading, spacing: 6) {
      Text("Client")
        .font(.caption)
        .foregroundStyle(.secondary)

      Menu {
        Button {
          selectedClient = nil
        } label: {
          if selectedClient == nil {
            Label("None", systemImage: "checkmark")
          } else {
            Text("None")
          }
        }

        Divider()

        ForEach(clientStore.clients, id: \.self) { client in
          Button {
            selectedClient = client
          } label: {
            if selectedClient == client {
              Label(client, systemImage: "checkmark")
            } else {
              Text(client)
            }
          }
        }
      } label: {
        clientPickerLabel
      }
      .buttonStyle(.plain)
      .accessibilityLabel("Suggested client")
      .accessibilityValue(selectedClient ?? "None")
    }
  }

  private var clientPickerLabel: some View {
    HStack {
      Text(selectedClient ?? "None")
        .foregroundStyle(selectedClient != nil ? .primary : .secondary)
      Spacer()
      Image(systemName: "chevron.up.chevron.down")
        .font(.caption)
        .foregroundStyle(.secondary)
    }
    .padding(.horizontal, 14)
    .padding(.vertical, 12)
    .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    .overlay {
      RoundedRectangle(cornerRadius: 12, style: .continuous)
        .strokeBorder(Color.primary.opacity(0.08), lineWidth: 1)
    }
  }

  private var projectCodeField: some View {
    VStack(alignment: .leading, spacing: 6) {
      Text("Project / Job code")
        .font(.caption)
        .foregroundStyle(.secondary)
      TextField("Optional", text: $projectCode)
        .textInputAutocapitalization(.characters)
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay {
          RoundedRectangle(cornerRadius: 12, style: .continuous)
            .strokeBorder(Color.primary.opacity(0.08), lineWidth: 1)
        }
        .accessibilityLabel("Suggested project code")
    }
  }

  // MARK: - Error Message

  @ViewBuilder
  private var errorMessageView: some View {
    if let errorMessage {
      Text(errorMessage)
        .font(.footnote)
        .foregroundStyle(.red)
        .padding(.horizontal, 4)
    }
  }

  // MARK: - Logic

  private var canCreate: Bool {
    let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
    let trimmedStart = startAddress.trimmingCharacters(in: .whitespacesAndNewlines)
    let trimmedEnd = endAddress.trimmingCharacters(in: .whitespacesAndNewlines)
    let hasAddressCriteria = !trimmedStart.isEmpty || !trimmedEnd.isEmpty
    let hasAction = selectedCategory != nil || selectedClient != nil || !projectCode.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    return !trimmedName.isEmpty && hasAddressCriteria && hasAction
  }

  private func create() {
    let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
    let trimmedStart = startAddress.trimmingCharacters(in: .whitespacesAndNewlines)
    let trimmedEnd = endAddress.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmedName.isEmpty else { errorMessage = "Name is required."; return }
    guard !trimmedStart.isEmpty || !trimmedEnd.isEmpty else { errorMessage = "At least one address is required."; return }

    let proj = projectCode.trimmingCharacters(in: .whitespacesAndNewlines)
    let window: RuleTimeWindow? = limitToTimeWindow ? RuleTimeWindow(
      startMinutes: minutesSinceMidnight(windowStart),
      endMinutes: minutesSinceMidnight(windowEnd)
    ) : nil

    let rule = TripRule(
      name: trimmedName,
      isEnabled: true,
      criteria: TripRuleCriteria(
        startContains: trimmedStart.isEmpty ? nil : trimmedStart,
        endContains: trimmedEnd.isEmpty ? nil : trimmedEnd,
        timeWindow: window
      ),
      action: TripRuleAction(
        setCategory: selectedCategory,
        setClientOrOrg: selectedClient,
        setProjectCode: proj.isEmpty ? nil : proj
      )
    )

    onCreate(rule)
    dismiss()
  }

  private func minutesSinceMidnight(_ date: Date) -> Int {
    let comps = Calendar.current.dateComponents([.hour, .minute], from: date)
    return (comps.hour ?? 0) * 60 + (comps.minute ?? 0)
  }
}

#Preview {
  CreateRuleSheet { _ in }
    .environmentObject(CategoriesStore())
    .environmentObject(ClientsStore())
    .environmentObject(LocationsStore())
}
