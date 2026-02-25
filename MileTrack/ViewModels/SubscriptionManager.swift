import Combine
import Foundation
import StoreKit

/*
 StoreKit 2 setup (IMPORTANT)

 - Set your product IDs in `SubscriptionProductIDs` below:
   - monthly: com.yourcompany.yourapp.pro.monthly
   - annual:  com.yourcompany.yourapp.pro.annual

 - Testing in Xcode:
   - Create a StoreKit Configuration file (e.g. `MileTrack.storekit`) in Xcode
     and add the two subscription products with matching IDs.
   - In your scheme: Run → Options → StoreKit Configuration → select that file.
   - Purchases and entitlements are determined from VERIFIED transactions only.
 */

@MainActor
final class SubscriptionManager: ObservableObject {
  /// Public API (kept stable): current tier + annual flag derived from active entitlement.
  @Published private(set) var status: SubscriptionStatus

  /// Products loaded from the App Store (StoreKit 2).
  @Published private(set) var products: [Product] = []
  @Published private(set) var isLoadingProducts: Bool = false
  @Published private(set) var isProcessingPurchase: Bool = false
  @Published private(set) var lastErrorMessage: String?
  @Published private(set) var lastUpdated: Date?

  private var transactionUpdatesTask: Task<Void, Never>?

  init(status: SubscriptionStatus? = nil) {
    self.status = status ?? SubscriptionStatus(tier: .free)

    // Avoid spamming StoreKit when SwiftUI previews are rendering.
    let isPreview = ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"
    if !isPreview {
      start()
    }
  }

  deinit {
    transactionUpdatesTask?.cancel()
  }

  // MARK: - Entitlement helpers (kept stable)

  var canUseUnlimitedAutoMode: Bool { status.tier == .pro }
  var canAccessAdvancedReports: Bool { status.tier == .pro }
  var canExportPDF: Bool { status.tier == .pro }
  var canCreateRulesTemplates: Bool { status.tier == .pro }

  // MARK: - StoreKit lifecycle

  func start() {
    guard transactionUpdatesTask == nil else { return }

    transactionUpdatesTask = Task { [weak self] in
      guard let self else { return }

      await self.loadProducts()
      await self.refreshEntitlements()

      for await result in Transaction.updates {
        guard !Task.isCancelled else { break }
        switch result {
        case .verified(let transaction):
          await transaction.finish()
          await self.refreshEntitlements()
        case .unverified:
          // Ignore unverified transactions.
          break
        }
      }
    }
  }

  /// Explicit, user-initiated refresh (safe to call repeatedly).
  func refresh() async {
    // Keep UI responsive and state consistent.
    if products.isEmpty {
      await loadProducts()
    }
    await refreshEntitlements()
  }

  func loadProducts() async {
    isLoadingProducts = true
    defer { isLoadingProducts = false }

    do {
      let fetched = try await Product.products(for: SubscriptionProductIDs.all)
      // Keep a deterministic order for UI.
      products = fetched.sorted(by: { a, b in
        let order: (String) -> Int = { id in
          switch id {
          case SubscriptionProductIDs.proMonthly: return 0
          case SubscriptionProductIDs.proAnnual: return 1
          default: return 2
          }
        }
        let oa = order(a.id)
        let ob = order(b.id)
        if oa != ob { return oa < ob }
        return a.id < b.id
      })
      lastErrorMessage = nil
      lastUpdated = Date()
    } catch {
      products = []
      lastErrorMessage = "Plans are currently unavailable. Please try again."
      lastUpdated = Date()
    }
  }

  func refreshEntitlements() async {
    var best: Transaction?
    let now = Date()

    for await result in Transaction.currentEntitlements {
      guard !Task.isCancelled else { break }
      guard case .verified(let transaction) = result else { continue }
      guard SubscriptionProductIDs.all.contains(transaction.productID) else { continue }
      guard transaction.revocationDate == nil else { continue }
      if let expiry = transaction.expirationDate, expiry <= now { continue }

      // For subscriptions, currentEntitlements should already be active.
      // If multiple are present, prefer the one with the latest expiration date (or purchase date).
      if let currentBest = best {
        let bestExpiry = currentBest.expirationDate ?? .distantPast
        let txExpiry = transaction.expirationDate ?? .distantPast
        if txExpiry > bestExpiry {
          best = transaction
        }
      } else {
        best = transaction
      }
    }

    if let best {
      status = SubscriptionStatus(tier: .pro, isAnnual: best.productID == SubscriptionProductIDs.proAnnual)
    } else {
      status = SubscriptionStatus(tier: .free, isAnnual: false)
    }

    lastUpdated = Date()
  }

  // MARK: - Purchase / Restore

  func purchaseMonthly() async {
    guard let product = products.first(where: { $0.id == SubscriptionProductIDs.proMonthly }) else {
      lastErrorMessage = "Monthly plan is not available right now."
      return
    }
    await purchase(product: product)
  }

  func purchaseAnnual() async {
    guard let product = products.first(where: { $0.id == SubscriptionProductIDs.proAnnual }) else {
      lastErrorMessage = "Annual plan is not available right now."
      return
    }
    await purchase(product: product)
  }

  func purchase(product: Product) async {
    isProcessingPurchase = true
    defer { isProcessingPurchase = false }

    do {
      let result = try await product.purchase()
      switch result {
      case .success(let verification):
        switch verification {
        case .verified(let transaction):
          await transaction.finish()
          lastErrorMessage = nil
          await refreshEntitlements()
        case .unverified:
          lastErrorMessage = "Purchase couldn’t be verified."
        }
      case .userCancelled:
        lastErrorMessage = "Purchase cancelled."
      case .pending:
        lastErrorMessage = "Purchase pending approval."
      @unknown default:
        lastErrorMessage = "Purchase did not complete."
      }
    } catch {
      lastErrorMessage = "Purchase failed. Please try again."
    }
  }

  func restorePurchases() async {
    isProcessingPurchase = true
    defer { isProcessingPurchase = false }

    do {
      try await AppStore.sync()
      lastErrorMessage = nil
      await refreshEntitlements()
    } catch {
      lastErrorMessage = "Restore failed. Please try again."
    }
  }

  #if DEBUG
  /// Debug-only: resets to free tier for testing. Does not revoke real App Store entitlements.
  func resetToFree() {
    status = SubscriptionStatus(tier: .free, isAnnual: false)
    lastErrorMessage = nil
    lastUpdated = Date()
  }
  #endif
}

enum SubscriptionProductIDs {
  static let proMonthly = "ai.plenitudo.MileTrack.pro.monthly"
  static let proAnnual = "ai.plenitudo.MileTrack.pro.annual"

  // Backwards-compatible aliases (if any UI code still uses these names).
  static let monthly = proMonthly
  static let annual = proAnnual

  static let all: [String] = [proMonthly, proAnnual]
}

