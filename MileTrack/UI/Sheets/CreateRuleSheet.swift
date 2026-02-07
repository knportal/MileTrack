import SwiftUI

struct CreateRuleSheet: View {
  @Environment(\.dismiss) private var dismiss
  @EnvironmentObject private var categoriesStore: CategoriesStore
  @EnvironmentObject private var clientStore: ClientStore

  let onCreate: (TripRule) -> Void

  @State private var name: String = ""
  @State private var containsText: String = ""

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
          GlassCard {
            VStack(alignment: .leading, spacing: 12) {
              Text("Rule")
                .font(.headline)

              TextField("Name", text: $name)
                .textInputAutocapitalization(.words)
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay {
                  RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(Color.primary.opacity(0.10), lineWidth: 1)
                }
                .accessibilityLabel("Rule name")

              TextField("Keyword match (start/end contains…)", text: $containsText)
                .textInputAutocapitalization(.never)
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay {
                  RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(Color.primary.opacity(0.10), lineWidth: 1)
                }
                .accessibilityLabel("Keyword match")

              Toggle(isOn: $limitToTimeWindow) {
                Text("Limit to time window")
                  .font(.subheadline.weight(.semibold))
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

          GlassCard {
            VStack(alignment: .leading, spacing: 12) {
              Text("Suggest")
                .font(.headline)

              Picker("Category", selection: $selectedCategory) {
                Text("None").tag(String?.none)
                ForEach(categoriesStore.categories, id: \.self) { category in
                  Text(category).tag(String?.some(category))
                }
              }
              .pickerStyle(.menu)
              .accessibilityLabel("Suggested category")

              Picker("Client", selection: $selectedClient) {
                Text("None").tag(String?.none)
                ForEach(clientStore.clients, id: \.self) { client in
                  Text(client).tag(String?.some(client))
                }
              }
              .pickerStyle(.menu)
              .accessibilityLabel("Suggested client")

              TextField("Project / Job code (optional)", text: $projectCode)
                .textInputAutocapitalization(.characters)
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay {
                  RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(Color.primary.opacity(0.10), lineWidth: 1)
                }
                .accessibilityLabel("Suggested project code")
            }
          }

          if let errorMessage {
            Text(errorMessage)
              .font(.footnote)
              .foregroundStyle(.red)
              .padding(.horizontal, 4)
          }
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

  private var canCreate: Bool {
    let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
    let trimmedKeyword = containsText.trimmingCharacters(in: .whitespacesAndNewlines)
    return !trimmedName.isEmpty && !trimmedKeyword.isEmpty && (selectedCategory != nil || selectedClient != nil || !projectCode.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
  }

  private func create() {
    let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
    let trimmedKeyword = containsText.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmedName.isEmpty else { errorMessage = "Name is required."; return }
    guard !trimmedKeyword.isEmpty else { errorMessage = "Keyword is required."; return }

    let proj = projectCode.trimmingCharacters(in: .whitespacesAndNewlines)
    let window: RuleTimeWindow? = limitToTimeWindow ? RuleTimeWindow(
      startMinutes: minutesSinceMidnight(windowStart),
      endMinutes: minutesSinceMidnight(windowEnd)
    ) : nil

    let rule = TripRule(
      name: trimmedName,
      isEnabled: true,
      criteria: TripRuleCriteria(containsText: trimmedKeyword, clientContains: nil, timeWindow: window),
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
    .environmentObject(ClientStore())
}

