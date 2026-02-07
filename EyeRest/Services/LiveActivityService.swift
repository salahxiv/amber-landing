#if os(iOS)
import ActivityKit
import Foundation

@available(iOS 16.2, *)
final class LiveActivityService {
    static let shared = LiveActivityService()
    private var currentActivity: Activity<EyeRestActivityAttributes>?

    private init() {}

    // MARK: - Live Activity starten

    func startActivity(phase: String, endDate: Date, statusText: String, workMinutes: Int) {
        // Bestehende Activity beenden
        endActivity()

        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }

        let attributes = EyeRestActivityAttributes(workDurationMinutes: workMinutes)
        let state = EyeRestActivityAttributes.ContentState(
            phase: phase,
            endDate: endDate,
            isPaused: false,
            remainingSeconds: Int(endDate.timeIntervalSinceNow),
            statusText: statusText
        )

        do {
            let content = ActivityContent(state: state, staleDate: endDate.addingTimeInterval(30))
            currentActivity = try Activity.request(
                attributes: attributes,
                content: content,
                pushType: nil
            )
        } catch {
            print("Live Activity konnte nicht gestartet werden: \(error)")
        }
    }

    // MARK: - Live Activity aktualisieren

    func updateActivity(phase: String, endDate: Date, isPaused: Bool, remainingSeconds: Int, statusText: String) {
        guard let activity = currentActivity else { return }

        let state = EyeRestActivityAttributes.ContentState(
            phase: phase,
            endDate: endDate,
            isPaused: isPaused,
            remainingSeconds: remainingSeconds,
            statusText: statusText
        )

        let content = ActivityContent(state: state, staleDate: endDate.addingTimeInterval(30))

        Task {
            await activity.update(content)
        }
    }

    // MARK: - Live Activity beenden

    func endActivity() {
        guard let activity = currentActivity else { return }

        let state = EyeRestActivityAttributes.ContentState(
            phase: "idle",
            endDate: .now,
            isPaused: false,
            remainingSeconds: 0,
            statusText: "Bereit"
        )

        let content = ActivityContent(state: state, staleDate: nil)

        Task {
            await activity.end(content, dismissalPolicy: .immediate)
        }

        currentActivity = nil
    }
}
#endif
