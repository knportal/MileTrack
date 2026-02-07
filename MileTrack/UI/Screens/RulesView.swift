import SwiftUI

struct RulesView: View {
  @EnvironmentObject private var subscriptionManager: SubscriptionManager
  @EnvironmentObject private var rulesStore: RulesStore
  @EnvironmentObject private var categoriesStore: CategoriesStore
  @EnvironmentObject private var clientStore: ClientStore

  @State private var isPresentingCreate: Bool = false

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 14) {
        headerCard

        if subscriptionManager.status.tier == .free {
          ZStack {
            listCard
            LockedOverlay(message: "Rules")
              .padding(6)
          }
          PrimaryGlassButton(title: "Upgrade to Pro", systemImage: "sparkles") {
            // Future: Navigate to subscription options (kept minimal).
          }
        } else {
          listCard
        }
      }
      .padding(.horizontal, 16)
      .padding(.vertical, 12)
    }
    .background(.background)
    .navigationTitle("Rules")
    .toolbar {
      ToolbarItem(placement: .topBarTrailing) {
        Button {
          isPresentingCreate = true
        } label: {
          Image(systemName: "plus")
        }
        .disabled(subscriptionManager.status.tier == .free)
        .accessibilityLabel("Add rule")
      }
    }
    .sheet(isPresented: $isPresentingCreate) {
      CreateRuleSheet { rule in
        rulesStore.add(rule)
      }
      .environmentObject(categoriesStore)
      .environmentObject(clientStore)
    }
  }

  private var headerCard: some View {
    GlassCard {
      VStack(alignment: .leading, spacing: 8) {
        Text("Rules & Templates (MVP)")
          .font(.headline)
        Text("Rules can suggest category/client/project for auto-detected trips. Trips still require confirmation in Inbox.")
          .font(.footnote)
          .foregroundStyle(.secondary)
      }
    }
  }

  private var listCard: some View {
    GlassCard {
      VStack(alignment: .leading, spacing: 10) {
        HStack {
          Text("Rules")
            .font(.headline)
          Spacer(minLength: 0)
          Text("\(rulesStore.rules.count)")
            .foregroundStyle(.secondary)
            .font(.subheadline)
            .accessibilityHidden(true)
        }

        if rulesStore.rules.isEmpty {
          EmptyStateView(
            systemImage: "wand.and.stars",
            title: "No rules yet",
            subtitle: "Create a rule to prefill category, client, or project for auto trips.",
            actionTitle: subscriptionManager.status.tier == .free ? nil : "Add Rule",
            action: subscriptionManager.status.tier == .free ? nil : { isPresentingCreate = true }
          )
        } else {
          VStack(spacing: 10) {
            ForEach(rulesStore.rules, id: \.id) { rule in
              ruleRow(rule)
            }
          }
        }
      }
    }
  }

  private func ruleRow(_ rule: TripRule) -> some View {
    VStack(alignment: .leading, spacing: 8) {
      HStack(alignment: .firstTextBaseline) {
        Text(rule.name)
          .font(.subheadline.weight(.semibold))
          .lineLimit(1)
        Spacer(minLength: 0)
        Toggle("", isOn: Binding(
          get: { rule.isEnabled },
          set: { rulesStore.toggleEnabled(ruleID: rule.id, isEnabled: $0) }
        ))
        .labelsHidden()
        .disabled(subscriptionManager.status.tier == .free)
        .accessibilityLabel("Enabled")
        .accessibilityValue(rule.isEnabled ? "On" : "Off")
      }

      Text(ruleSummary(rule))
        .font(.footnote)
        .foregroundStyle(.secondary)

      HStack(spacing: 10) {
        Button(role: .destructive) {
          rulesStore.remove(ruleID: rule.id)
        } label: {
          HStack {
            Image(systemName: "trash")
              .accessibilityHidden(true)
            Text("Delete")
              .font(.footnote.weight(.semibold))
          }
          .padding(.horizontal, 12)
          .padding(.vertical, 10)
          .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
          .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
              .strokeBorder(Color.primary.opacity(0.10), lineWidth: 1)
          }
        }
        .buttonStyle(.plain)
        .disabled(subscriptionManager.status.tier == .free)
      }
    }
    .accessibilityElement(children: .contain)
  }

  private func ruleSummary(_ rule: TripRule) -> String {
    var parts: [String] = []
    if let keyword = rule.criteria.containsText?.trimmingCharacters(in: .whitespacesAndNewlines), !keyword.isEmpty {
      parts.append("When label contains “\(keyword)”")
    }
    if let client = rule.criteria.clientContains?.trimmingCharacters(in: .whitespacesAndNewlines), !client.isEmpty {
      parts.append("and client contains “\(client)”")
    }
    if let window = rule.criteria.timeWindow {
      parts.append("and time \(fmt(window.startMinutes))–\(fmt(window.endMinutes))")
    }

    var actions: [String] = []
    if let c = rule.action.setCategory?.trimmingCharacters(in: .whitespacesAndNewlines), !c.isEmpty { actions.append("Category: \(c)") }
    if let c = rule.action.setClientOrOrg?.trimmingCharacters(in: .whitespacesAndNewlines), !c.isEmpty { actions.append("Client: \(c)") }
    if let p = rule.action.setProjectCode?.trimmingCharacters(in: .whitespacesAndNewlines), !p.isEmpty { actions.append("Project: \(p)") }

    let when = parts.isEmpty ? "When (always)" : parts.joined(separator: " ")
    let then = actions.isEmpty ? "do nothing" : actions.joined(separator: " • ")
    return "\(when) → Suggest \(then)"
  }

  private func fmt(_ minutes: Int) -> String {
    let m = max(0, min(1439, minutes))
    let h = m / 60
    let min = m % 60
    return String(format: "%02d:%02d", h, min)
  }
}

#Preview {
  NavigationStack {
    RulesView()
  }
  .environmentObject(SubscriptionManager(status: SubscriptionStatus(tier: .pro)))
  .environmentObject(RulesStore(rules: [
    TripRule(
      name: "Airport",
      isEnabled: true,
      criteria: TripRuleCriteria(containsText: "airport"),
      action: TripRuleAction(setCategory: "Business", setClientOrOrg: "Acme Co.", setProjectCode: nil)
    )
  ]))
  .environmentObject(CategoriesStore())
  .environmentObject(ClientStore())
}

