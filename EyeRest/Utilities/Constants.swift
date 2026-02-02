import Foundation

enum Constants {
    // Standard Timer-Einstellungen (Defaults)
    static let defaultWorkDuration: Int = 20 * 60  // 20 Minuten in Sekunden
    static let defaultRestDuration: Int = 20       // 20 Sekunden

    // Min/Max Grenzen für Timer
    static let minWorkDuration: Int = 60           // 1 Minute
    static let maxWorkDuration: Int = 60 * 60      // 60 Minuten
    static let minRestDuration: Int = 5            // 5 Sekunden
    static let maxRestDuration: Int = 120          // 2 Minuten

    // Debug-Modus (für Tests mit kürzeren Intervallen)
    static let debugWorkDuration: Int = 10  // 10 Sekunden
    static let debugRestDuration: Int = 5   // 5 Sekunden

    // UI
    static let popoverWidth: CGFloat = 280
    static let popoverHeight: CGFloat = 400  // Erhöht für erweiterte Einstellungen

    // UserDefaults Keys
    static let launchAtLoginKey = "launchAtLogin"
    static let isTimerRunningKey = "isTimerRunning"
    static let workDurationKey = "workDuration"
    static let restDurationKey = "restDuration"
    static let soundEnabledKey = "soundEnabled"
}

// Notification Names für App-Events
extension Notification.Name {
    static let breakStarted = Notification.Name("breakStarted")
    static let breakEnded = Notification.Name("breakEnded")
    static let breakSkipped = Notification.Name("breakSkipped")
    static let timerStateChanged = Notification.Name("timerStateChanged")
    static let settingsChanged = Notification.Name("settingsChanged")
    static let settingsExpandedChanged = Notification.Name("settingsExpandedChanged")
    static let statisticsUpdated = Notification.Name("statisticsUpdated")
}
