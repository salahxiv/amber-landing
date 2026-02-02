import Foundation
import StoreKit
import Combine

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

    // MARK: - Initialization

    private init() {
        Task {
            await loadProducts()
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

    /// Kauft ein Tip-Produkt
    func purchase(_ product: Product) async {
        isLoading = true
        purchaseError = nil

        do {
            let result = try await product.purchase()

            switch result {
            case .success(let verification):
                switch verification {
                case .verified(_):
                    // Kauf erfolgreich
                    showThankYou = true
                    await MainActor.run {
                        // Nach 3 Sekunden ausblenden
                        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                            self.showThankYou = false
                        }
                    }

                case .unverified(_, _):
                    purchaseError = "Kauf konnte nicht verifiziert werden"
                }

            case .userCancelled:
                break

            case .pending:
                purchaseError = "Kauf ausstehend"

            @unknown default:
                break
            }
        } catch {
            purchaseError = "Kauf fehlgeschlagen"
            print("TipJarService: Fehler beim Kauf: \(error)")
        }

        isLoading = false
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
