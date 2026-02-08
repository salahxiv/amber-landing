import StoreKit

/// Intelligenter Review-Prompt Service
/// Fragt Nutzer nach positivem Erlebnis (Achievement) um eine App Store Bewertung
final class ReviewService {
    static let shared = ReviewService()

    private init() {}

    // MARK: - Public

    /// Prüft Berechtigung und zeigt Review-Dialog wenn angemessen
    func requestReviewIfEligible() {
        guard shouldRequestReview() else { return }

        #if os(iOS)
        if let windowScene = UIApplication.shared.connectedScenes
            .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene {
            SKStoreReviewController.requestReview(in: windowScene)
        }
        #elseif os(macOS)
        SKStoreReviewController.requestReview()
        #endif

        UserDefaults.standard.set(Date(), forKey: Constants.lastReviewPromptDateKey)
    }

    // MARK: - Private

    private func shouldRequestReview() -> Bool {
        // Cooldown prüfen (90 Tage)
        if let lastDate = UserDefaults.standard.object(forKey: Constants.lastReviewPromptDateKey) as? Date {
            let daysSince = Calendar.current.dateComponents([.day], from: lastDate, to: Date()).day ?? 0
            return daysSince >= Constants.reviewPromptMinimumDays
        }
        return true
    }
}
