#if os(iOS)
import Foundation
import HealthKit
import Combine

/// Service für HealthKit Integration (iOS Only)
/// Schreibt abgeschlossene Pausen als "Achtsamkeit"-Minuten in Apple Health
@MainActor
final class HealthService: ObservableObject {
    static let shared = HealthService()

    // MARK: - Properties

    @Published private(set) var isAuthorized: Bool = false
    @Published var isEnabled: Bool = false {
        didSet {
            UserDefaults.standard.set(isEnabled, forKey: "healthKitEnabled")
            if isEnabled && !isAuthorized {
                Task { await requestAuthorization() }
            }
        }
    }

    private let healthStore = HKHealthStore()
    private let mindfulType = HKCategoryType(.mindfulSession)

    // MARK: - Init

    private init() {
        isEnabled = UserDefaults.standard.bool(forKey: "healthKitEnabled")
        checkAuthorizationStatus()
        setupNotifications()
    }

    // MARK: - Authorization

    /// Prüft ob HealthKit auf diesem Gerät verfügbar ist
    var isAvailable: Bool {
        HKHealthStore.isHealthDataAvailable()
    }

    /// Fordert HealthKit-Berechtigung an
    func requestAuthorization() async {
        guard isAvailable else { return }

        let typesToShare: Set<HKSampleType> = [mindfulType]

        do {
            try await healthStore.requestAuthorization(toShare: typesToShare, read: [])
            checkAuthorizationStatus()
        } catch {
            print("HealthKit Berechtigung fehlgeschlagen: \(error)")
        }
    }

    private func checkAuthorizationStatus() {
        guard isAvailable else {
            isAuthorized = false
            return
        }
        let status = healthStore.authorizationStatus(for: mindfulType)
        isAuthorized = status == .sharingAuthorized
    }

    // MARK: - Mindfulness Session schreiben

    /// Schreibt eine abgeschlossene Pause als Achtsamkeits-Session
    func recordMindfulSession(durationSeconds: Int) {
        guard isEnabled, isAuthorized, isAvailable else { return }

        let endDate = Date()
        let startDate = endDate.addingTimeInterval(-TimeInterval(durationSeconds))

        let sample = HKCategorySample(
            type: mindfulType,
            value: HKCategoryValue.notApplicable.rawValue,
            start: startDate,
            end: endDate
        )

        healthStore.save(sample) { success, error in
            if let error = error {
                print("HealthKit Speichern fehlgeschlagen: \(error)")
            }
        }
    }

    // MARK: - Notifications

    private func setupNotifications() {
        NotificationCenter.default.addObserver(
            forName: .breakEnded,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                let duration = SettingsManager.shared.restDuration
                self?.recordMindfulSession(durationSeconds: duration)
            }
        }
    }
}
#endif
