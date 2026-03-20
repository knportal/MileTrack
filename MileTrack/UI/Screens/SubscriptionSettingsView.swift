import SwiftUI
import StoreKit

struct SubscriptionSettingsView: View {
    @Environment(\.openURL) private var openURL
    @EnvironmentObject private var subscriptionManager: SubscriptionManager
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                currentPlanSection
                benefitsSection
                plansSection
                actionsSection
                legalSection
            }
            .frame(maxWidth: DesignConstants.iPadMaxContentWidth)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity)
        }
        .background(.background)
        .navigationTitle("Subscription & Billing")
    }
    
    // MARK: - Current Plan Section
    @ViewBuilder
    private var currentPlanSection: some View {
        if subscriptionManager.status.tier == .pro {
            VStack(alignment: .leading, spacing: 12) {
                Text("Current Plan")
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(.primary)
                
                GlassCard {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Active Subscription")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .textCase(.uppercase)
                            Text(subscriptionManager.statusDisplayName)
                                .font(.title3.weight(.bold))
                        }
                        Spacer(minLength: 0)
                        ProBadge()
                    }
                }
            }
        }
    }
    
    // MARK: - Benefits Section
    private var benefitsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("What's Included")
                .font(.title2.weight(.semibold))
                .foregroundStyle(.primary)

            GlassCard {
                VStack(alignment: .leading, spacing: 14) {
                    benefitRow(icon: "location.fill", title: "Unlimited Auto Tracking", description: "Automatic trip detection runs continuously in the background")
                    benefitRow(icon: "chart.bar.fill", title: "Advanced Reports", description: "Detailed mileage reports with filters, charts, and summaries")
                    benefitRow(icon: "doc.fill", title: "PDF Export", description: "Generate professional PDF reports for tax filing or reimbursement")
                    benefitRow(icon: "gearshape.2.fill", title: "Custom Rules", description: "Create rules and templates to automatically categorize trips")
                }
                .padding(.vertical, 4)
            }
        }
    }

    private func benefitRow(icon: String, title: String, description: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.body)
                .foregroundStyle(Color.accentColor)
                .frame(width: 24, height: 24)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Plans Section
    private var plansSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Available Plans")
                .font(.title2.weight(.semibold))
                .foregroundStyle(.primary)

            GlassCard {
                if subscriptionManager.isLoadingProducts && subscriptionManager.products.isEmpty {
                    HStack {
                        ProgressView()
                        Text("Loading plans...")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 20)
                } else if subscriptionManager.products.isEmpty {
                    Text("Plans unavailable. Please check your connection and try again.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 20)
                } else {
                    VStack(spacing: 0) {
                        if let monthly = subscriptionManager.products.first(where: { $0.id == SubscriptionProductIDs.proMonthly }) {
                            planRow(
                                product: monthly,
                                title: "Monthly",
                                subtitle: "Billed monthly",
                                isRecommended: false
                            ) {
                                Task { await subscriptionManager.purchase(product: monthly) }
                            }
                        }
                        
                        if let annual = subscriptionManager.products.first(where: { $0.id == SubscriptionProductIDs.proAnnual }) {
                            Divider()
                                .padding(.leading, 16)
                            
                            planRow(
                                product: annual,
                                title: "Annual",
                                subtitle: "Billed yearly - Save 50%",
                                isRecommended: true
                            ) {
                                Task { await subscriptionManager.purchase(product: annual) }
                            }
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Actions Section
    private var actionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Account")
                .font(.title2.weight(.semibold))
                .foregroundStyle(.primary)
            
            GlassCard {
                VStack(spacing: 12) {
                    HStack(spacing: 12) {
                        Button {
                            Task { await subscriptionManager.restorePurchases() }
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "arrow.clockwise")
                                    .font(.subheadline)
                                Text("Restore")
                                    .font(.subheadline.weight(.medium))
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                        }
                        .buttonStyle(.bordered)
                        .disabled(subscriptionManager.isProcessingPurchase)
                        .accessibilityLabel("Restore Purchases")
                        
                        Button {
                            Task { await subscriptionManager.refresh() }
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "arrow.clockwise.circle")
                                    .font(.subheadline)
                                Text("Refresh")
                                    .font(.subheadline.weight(.medium))
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                        }
                        .buttonStyle(.bordered)
                        .disabled(subscriptionManager.isProcessingPurchase || subscriptionManager.isLoadingProducts)
                        .accessibilityLabel("Refresh Status")
                    }
                    
                    if let msg = subscriptionManager.lastErrorMessage {
                        HStack(spacing: 8) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundStyle(.orange)
                            Text(msg)
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.orange.opacity(0.1), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                    }
                    
                    Button {
                        openSubscriptionManagement()
                    } label: {
                        HStack {
                            Image(systemName: "person.crop.circle")
                            Text("Manage Subscription")
                                .font(.subheadline.weight(.semibold))
                            Spacer()
                            Image(systemName: "arrow.up.right.square")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .overlay {
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .strokeBorder(Color.primary.opacity(0.10), lineWidth: 1)
                        }
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Manage Subscription")
                    
                    Text(subscriptionDebugLine)
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }
        }
    }
    
    // MARK: - Legal Section
    private var legalSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Terms")
                .font(.title2.weight(.semibold))
                .foregroundStyle(.primary)
            
            GlassCard {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Payment will be charged to your Apple ID account at confirmation of purchase. Subscription automatically renews unless it is canceled at least 24 hours before the end of the current period. You can manage or cancel in your Apple ID account settings.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    HStack(spacing: 10) {
                        Link("Privacy Policy", destination: URL(string: "https://www.plenitudo.ai/app/miletrack/privacy-policy")!)
                            .accessibilityLabel("Open Privacy Policy")
                        Text("-").foregroundStyle(.tertiary)
                        Link("Terms of Use", destination: URL(string: "https://www.plenitudo.ai/app/miletrack/terms")!)
                            .accessibilityLabel("Open Terms of Use")
                    }
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.blue)
                }
                .accessibilityElement(children: .combine)
            }
        }
    }
    
    // MARK: - Helper Views
    private func planRow(
        product: Product,
        title: String,
        subtitle: String,
        isRecommended: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button {
            action()
        } label: {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text(title)
                            .font(.body.weight(.semibold))
                        
                        if isRecommended {
                            Text("BEST VALUE")
                                .font(.caption2.weight(.bold))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.green, in: Capsule())
                        }
                    }
                    
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer(minLength: 0)
                
                Text(product.displayPrice)
                    .font(.title3.weight(.bold))
                    .foregroundStyle(.primary)
                
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }
            .padding(16)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(subscriptionManager.isProcessingPurchase)
        .opacity(subscriptionManager.isProcessingPurchase ? 0.6 : 1.0)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title) plan, \(product.displayPrice), \(subtitle)")
        .accessibilityHint("Double tap to subscribe")
    }
    
    // MARK: - Helper Methods
    private func openSubscriptionManagement() {
        let deepLink = URL(string: "itms-apps://apps.apple.com/account/subscriptions")
        let web = URL(string: "https://apps.apple.com/account/subscriptions")
        
        if let deepLink, UIApplication.shared.canOpenURL(deepLink) {
            UIApplication.shared.open(deepLink, options: [:], completionHandler: nil)
        } else if let web {
            openURL(web)
        }
    }
    
    private var subscriptionDebugLine: String {
        let updated: String = {
            guard let date = subscriptionManager.lastUpdated else { return "Updated: -" }
            return "Updated: " + date.formatted(date: .abbreviated, time: .shortened)
        }()
        let entitlement = "Entitlement: \(subscriptionManager.statusDisplayName)"
        return "\(updated) - \(entitlement)"
    }
}

private extension SubscriptionManager {
    var statusDisplayName: String {
        switch status.tier {
        case .free:
            return "Free"
        case .pro:
            return status.isAnnual ? "Pro (Annual)" : "Pro (Monthly)"
        }
    }
}

#Preview {
    NavigationStack {
        SubscriptionSettingsView()
    }
    .environmentObject(SubscriptionManager())
}
