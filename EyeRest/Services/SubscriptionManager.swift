import Foundation
import StoreKit
import Combine
#if os(macOS)
import AppKit
#endif

/// Verwaltet Pro-Subscriptions via StoreKit 2
/// Ersetzt den alten TipJarService mit nachhaltigem Abo-Modell
@MainActor
final class SubscriptionManager: ObservableObject {
    static let shared = SubscriptionManager()

    // MARK: - Published Properties

    @Published private(set) var products: [Product] = []
    @Published private(set) var isPro: Bool = false
    @Published private(set) var isLoading = false
    @Published private(set) var purchaseError: String?
    @Published private(set) var currentSubscription: Product?

    // MARK: - Private Properties

    private let productIDs = [
        Constants.subscriptionMonthly,
        Constants.subscriptionYearly,
        Constants.subscriptionLifetime
    ]

    private var transactionListener: Task<Void, Error>?
    #if os(macOS)
    private var purchaseWindow: NSWindow?
    #endif

    // MARK: - Initialization

    private init() {
        transactionListener = listenForTransactions()

        Task {
            await loadProducts()
            await updateProStatus()
        }
    }

    deinit {
        transactionListener?.cancel()
    }

    // MARK: - Transaction Listener

    private func listenForTransactions() -> Task<Void, Error> {
        return Task { @MainActor in
            for await result in Transaction.updates {
                await self.handleTransaction(result)
                await self.updateProStatus()
            }
        }
    }

    private func handleTransaction(_ result: VerificationResult<Transaction>) async {
        switch result {
        case .verified(let transaction):
            await transaction.finish()
        case .unverified:
            break
        }
    }

    // MARK: - Pro Status

    /// Prüft ob der Nutzer ein aktives Abo oder Lifetime-Kauf hat
    func updateProStatus() async {
        var hasPro = false

        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result {
                if productIDs.contains(transaction.productID) {
                    // Prüfe ob Subscription noch gültig oder Lifetime
                    if transaction.productType == .nonConsumable {
                        hasPro = true
                        break
                    }
                    if transaction.revocationDate == nil,
                       transaction.expirationDate ?? .distantFuture > Date() {
                        hasPro = true
                        break
                    }
                }
            }
        }

        if isPro != hasPro {
            isPro = hasPro
            NotificationCenter.default.post(name: .proStatusChanged, object: nil)
        }
    }

    // MARK: - Products

    func loadProducts() async {
        isLoading = true
        purchaseError = nil

        do {
            let storeProducts = try await Product.products(for: productIDs)
            // Sortierung: Monthly, Yearly, Lifetime
            products = storeProducts.sorted { a, b in
                productSortOrder(a) < productSortOrder(b)
            }
        } catch {
            purchaseError = String(localized: "subscription.error.loadFailed")
            print("SubscriptionManager: Fehler beim Laden: \(error)")
        }

        isLoading = false
    }

    private func productSortOrder(_ product: Product) -> Int {
        switch product.id {
        case Constants.subscriptionMonthly: return 0
        case Constants.subscriptionYearly: return 1
        case Constants.subscriptionLifetime: return 2
        default: return 3
        }
    }

    // MARK: - Purchase

    #if os(macOS)
    private class KeyableWindow: NSWindow {
        override var canBecomeKey: Bool { true }
        override var canBecomeMain: Bool { true }
    }

    private func showPurchaseWindow() {
        let window = KeyableWindow(
            contentRect: NSRect(x: 0, y: 0, width: 1, height: 1),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        window.isOpaque = false
        window.backgroundColor = .clear
        window.hasShadow = false
        window.level = .floating
        window.setFrameOrigin(NSPoint(x: -100, y: -100))
        window.orderFrontRegardless()
        window.makeKey()
        purchaseWindow = window
    }

    private func hidePurchaseWindow() {
        purchaseWindow?.orderOut(nil)
        purchaseWindow = nil
    }
    #endif

    func purchase(_ product: Product) async {
        isLoading = true
        purchaseError = nil

        #if os(macOS)
        showPurchaseWindow()
        NSApp.activate(ignoringOtherApps: true)
        #endif

        let purchaseResult = await Task.detached { () -> Result<Product.PurchaseResult, Error> in
            do {
                let result = try await product.purchase()
                return .success(result)
            } catch {
                return .failure(error)
            }
        }.value

        switch purchaseResult {
        case .success(let result):
            await handlePurchaseResult(result)
        case .failure:
            purchaseError = String(localized: "subscription.error.purchaseFailed")
        }

        isLoading = false
        #if os(macOS)
        hidePurchaseWindow()
        #endif
    }

    private func handlePurchaseResult(_ result: Product.PurchaseResult) async {
        switch result {
        case .success(let verification):
            switch verification {
            case .verified(let transaction):
                await transaction.finish()
                await updateProStatus()
                AnalyticsService.shared.track("subscription_purchased", with: ["product": transaction.productID])
            case .unverified:
                purchaseError = String(localized: "subscription.error.verificationFailed")
            }
        case .userCancelled:
            break
        case .pending:
            purchaseError = String(localized: "subscription.error.pending")
        @unknown default:
            break
        }
    }

    // MARK: - Restore

    func restorePurchases() async {
        isLoading = true
        purchaseError = nil

        do {
            try await AppStore.sync()
            await updateProStatus()
        } catch {
            purchaseError = String(localized: "subscription.error.restoreFailed")
        }

        isLoading = false
    }
}

// MARK: - Product Helpers

extension Product {
    /// Anzeigename für das Produkt
    var subscriptionLabel: String {
        switch id {
        case Constants.subscriptionMonthly: return String(localized: "subscription.monthly")
        case Constants.subscriptionYearly: return String(localized: "subscription.yearly")
        case Constants.subscriptionLifetime: return String(localized: "subscription.lifetime")
        default: return displayName
        }
    }

    /// Kurzbeschreibung
    var subscriptionDescription: String {
        switch id {
        case Constants.subscriptionMonthly: return String(localized: "subscription.monthly.description")
        case Constants.subscriptionYearly: return String(localized: "subscription.yearly.description")
        case Constants.subscriptionLifetime: return String(localized: "subscription.lifetime.description")
        default: return description
        }
    }

    /// Ob dieses Produkt das empfohlene ist
    var isRecommended: Bool {
        id == Constants.subscriptionYearly
    }

    /// Täglicher Preis als String (nur für Abos)
    var dailyPriceText: String? {
        switch id {
        case Constants.subscriptionMonthly:
            let daily = price / 30
            return String(format: "%.2f€/Tag", NSDecimalNumber(decimal: daily).doubleValue)
        case Constants.subscriptionYearly:
            let daily = price / 365
            return String(format: "%.2f€/Tag", NSDecimalNumber(decimal: daily).doubleValue)
        default:
            return nil
        }
    }
}
