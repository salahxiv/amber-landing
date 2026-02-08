import Foundation

/// Shared Timer-Status für App Groups (Widget-Kommunikation)
struct SharedTimerState: Codable {
    var phase: String          // "work", "rest", "idle"
    var endDate: Date
    var isPaused: Bool
    var remainingSeconds: Int
    var workDuration: Int
    var restDuration: Int
    var statusText: String
    var lastUpdated: Date
    var completedBreaksToday: Int?

    /// Fortschritt als Prozent (0.0 bis 1.0)
    var progress: Double {
        let totalDuration = phase == "work" ? workDuration : restDuration
        guard totalDuration > 0 else { return 0 }
        return Double(totalDuration - remainingSeconds) / Double(totalDuration)
    }

    /// Idle-Zustand
    static var idle: SharedTimerState {
        SharedTimerState(
            phase: "idle",
            endDate: .now,
            isPaused: false,
            remainingSeconds: 0,
            workDuration: 20 * 60,
            restDuration: 20,
            statusText: String(localized: "widget.ready"),
            lastUpdated: .now,
            completedBreaksToday: 0
        )
    }
}

enum AppGroupConstants {
    static let suiteName = "group.devsalah.com.EyeRest"
    static let sharedTimerStateKey = "sharedTimerState"
}
