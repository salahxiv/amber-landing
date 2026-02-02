import Foundation

/// Die verschiedenen Phasen des Timers
enum TimerPhase {
    case work   // Arbeitsphase (20 Minuten)
    case rest   // Pausenphase (20 Sekunden)
    case idle   // Timer gestoppt
}

/// Status-Information für den Timer
struct TimerState {
    var phase: TimerPhase
    var remainingSeconds: Int
    var isPaused: Bool

    /// Gesamtdauer der aktuellen Phase in Sekunden
    var totalDuration: Int {
        switch phase {
        case .work:
            return Constants.workDuration
        case .rest:
            return Constants.restDuration
        case .idle:
            return 0
        }
    }

    /// Fortschritt als Prozent (0.0 bis 1.0)
    var progress: Double {
        guard totalDuration > 0 else { return 0 }
        return Double(totalDuration - remainingSeconds) / Double(totalDuration)
    }

    /// Formatierte Zeit als String (MM:SS oder S)
    var formattedTime: String {
        if phase == .rest {
            return "\(remainingSeconds)"
        }
        let minutes = remainingSeconds / 60
        let seconds = remainingSeconds % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    /// Status-Text für die UI
    var statusText: String {
        switch phase {
        case .work:
            return isPaused ? "Pausiert" : "Arbeiten"
        case .rest:
            return "Pause machen"
        case .idle:
            return "Bereit"
        }
    }

    /// Initial-Zustand
    static var initial: TimerState {
        TimerState(
            phase: .idle,
            remainingSeconds: Constants.workDuration,
            isPaused: false
        )
    }
}
