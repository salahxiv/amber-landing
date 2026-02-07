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
            statusText: "Bereit",
            lastUpdated: .now
        )
    }
}

enum AppGroupConstants {
    static let suiteName = "group.devsalah.com.EyeRest"
    static let sharedTimerStateKey = "sharedTimerState"
}
