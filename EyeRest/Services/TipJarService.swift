import Foundation
import StoreKit
import Combine
#if os(macOS)
import AppKit
#endif

/// Service für In-App Purchase Tip Jar
@MainActor
final class TipJarService: ObservableObject {
    static let shared = TipJarService()

    // MARK: - Published Properties

    @Published private(set) var tips: [Product] = []
    @Published private(set) var isLoading = false
    @Published private(set) var purchaseError: String?
    @Published var showThankYou = false

    // MARK: - Private Properties

    private let productIDs = [
        Constants.tipSmall,
        Constants.tipMedium,
        Constants.tipLarge
    ]

    private var transactionListener: Task<Void, Error>?
    #if os(macOS)
    private var purchaseWindow: NSWindow?
    #endif

    // MARK: - Initialization

    private init() {
        // Transaction Listener starten
        transactionListener = listenForTransactions()

        Task {
            await loadProducts()
        }
    }

    deinit {
        transactionListener?.cancel()
    }

    // MARK: - Transaction Listener

    /// Lauscht auf Transaction-Updates (wichtig für StoreKit 2)
    private func listenForTransactions() -> Task<Void, Error> {
        return Task { @MainActor in
            for await result in Transaction.updates {
                await self.handleTransaction(result)
            }
        }
    }

    /// Verarbeitet eine Transaction
    private func handleTransaction(_ result: VerificationResult<Transaction>) async {
        switch result {
        case .verified(let transaction):
            // Transaktion abschließen
            await transaction.finish()

            // UI aktualisieren
            showThankYou = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                self.showThankYou = false
            }

        case .unverified(_, _):
            break
        }
    }

    // MARK: - Public Methods

    /// Lädt die verfügbaren Tip-Produkte
    func loadProducts() async {
        isLoading = true
        purchaseError = nil

        do {
            let products = try await Product.products(for: productIDs)
            tips = products.sorted { $0.price < $1.price }
        } catch {
            purchaseError = "Produkte konnten nicht geladen werden"
            print("TipJarService: Fehler beim Laden der Produkte: \(error)")
        }

        isLoading = false
    }

    // MARK: - Purchase Window Helper (macOS only)

    #if os(macOS)
    /// Hilfsklasse für ein Fenster das Key werden kann
    private class KeyableWindow: NSWindow {
        override var canBecomeKey: Bool { true }
        override var canBecomeMain: Bool { true }
    }

    /// Erstellt ein unsichtbares Fenster für StoreKit-Dialog
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
        window.setFrameOrigin(NSPoint(x: -100, y: -100)) // Außerhalb des Bildschirms
        window.orderFrontRegardless()
        window.makeKey()

        purchaseWindow = window
    }

    private func hidePurchaseWindow() {
        purchaseWindow?.orderOut(nil)
        purchaseWindow = nil
    }
    #endif

    /// Kauft ein Tip-Produkt
    func purchase(_ product: Product) async {
        isLoading = true
        purchaseError = nil

        #if os(macOS)
        // Unsichtbares Fenster für StoreKit-Dialog
        showPurchaseWindow()

        // App aktivieren
        NSApp.activate(ignoringOtherApps: true)
        #endif

        // Purchase in einem separaten Task ohne MainActor ausführen
        let purchaseResult = await Task.detached { () -> Result<Product.PurchaseResult, Error> in
            do {
                let result = try await product.purchase()
                return .success(result)
            } catch {
                return .failure(error)
            }
        }.value

        // Ergebnis verarbeiten
        switch purchaseResult {
        case .success(let result):
            await handlePurchaseResult(result)
        case .failure:
            purchaseError = "Kauf fehlgeschlagen"
        }

        isLoading = false
        #if os(macOS)
        hidePurchaseWindow()
        #endif
    }

    /// Verarbeitet das Kaufergebnis
    private func handlePurchaseResult(_ result: Product.PurchaseResult) async {
        switch result {
        case .success(let verification):
            switch verification {
            case .verified(let transaction):
                await transaction.finish()

                showThankYou = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    self.showThankYou = false
                }

            case .unverified:
                purchaseError = "Kauf konnte nicht verifiziert werden"
            }

        case .userCancelled:
            // Benutzer hat abgebrochen - kein Fehler
            break

        case .pending:
            purchaseError = "Kauf ausstehend"

        @unknown default:
            break
        }
    }
}

// MARK: - Tip Model Helper

extension Product {
    /// Emoji basierend auf dem Preis
    var tipEmoji: String {
        if price < 2 {
            return "☕️"
        } else if price < 4 {
            return "🍕"
        } else {
            return "🎉"
        }
    }

    /// Beschreibung des Tips
    var tipDescription: String {
        if price < 2 {
            return "Kleiner Tipp"
        } else if price < 4 {
            return "Netter Tipp"
        } else {
            return "Großzügiger Tipp"
        }
    }
}
