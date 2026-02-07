#if os(iOS)
import ActivityKit
import Foundation

struct EyeRestActivityAttributes: ActivityAttributes {
    /// Statische Daten (beim Start festgelegt)
    var workDurationMinutes: Int

    struct ContentState: Codable, Hashable {
        var phase: String          // "work", "rest", "idle"
        var endDate: Date          // Zielzeit für Countdown
        var isPaused: Bool
        var remainingSeconds: Int  // Für Pause-Anzeige (kein Live-Countdown)
        var statusText: String     // "Arbeiten", "Pause machen", etc.
    }
}
#endif
