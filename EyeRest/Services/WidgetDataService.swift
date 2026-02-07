#if os(iOS)
import Foundation
import WidgetKit

/// Schreibt Timer-Status in Shared UserDefaults für das Homescreen Widget
final class WidgetDataService {
    static let shared = WidgetDataService()

    private let defaults: UserDefaults?

    private init() {
        defaults = UserDefaults(suiteName: AppGroupConstants.suiteName)
    }

    // MARK: - Timer-Status aktualisieren

    func updateTimerState(
        phase: String,
        endDate: Date,
        isPaused: Bool,
        remainingSeconds: Int,
        workDuration: Int,
        restDuration: Int,
        statusText: String
    ) {
        let state = SharedTimerState(
            phase: phase,
            endDate: endDate,
            isPaused: isPaused,
            remainingSeconds: remainingSeconds,
            workDuration: workDuration,
            restDuration: restDuration,
            statusText: statusText,
            lastUpdated: .now
        )

        save(state)
        WidgetCenter.shared.reloadAllTimelines()
    }

    // MARK: - Timer zurücksetzen

    func resetToIdle() {
        save(.idle)
        WidgetCenter.shared.reloadAllTimelines()
    }

    // MARK: - Privat

    private func save(_ state: SharedTimerState) {
        guard let data = try? JSONEncoder().encode(state) else { return }
        defaults?.set(data, forKey: AppGroupConstants.sharedTimerStateKey)
    }
}
#endif
