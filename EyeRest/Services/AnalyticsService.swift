import Foundation
import Aptabase

/// Zentraler Analytics-Service, wraps Aptabase SDK
/// Privacy-first, DSGVO-konform, keine persönlichen Daten
final class AnalyticsService {
    static let shared = AnalyticsService()
    private init() {}

    func initialize() {
        Aptabase.shared.initialize(appKey: "A-EU-9709679002")
    }

    func track(_ event: String, with props: [String: String] = [:]) {
        Aptabase.shared.trackEvent(event, with: props)
    }

    func track(_ event: String, with props: [String: Int]) {
        Aptabase.shared.trackEvent(event, with: props)
    }
}
