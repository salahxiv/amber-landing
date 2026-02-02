import Foundation

enum Constants {
    // Timer-Einstellungen
    static let workDuration: Int = 20 * 60  // 20 Minuten in Sekunden
    static let restDuration: Int = 20       // 20 Sekunden

    // Debug-Modus (für Tests mit kürzeren Intervallen)
    static let debugWorkDuration: Int = 10  // 10 Sekunden
    static let debugRestDuration: Int = 5   // 5 Sekunden

    // UI
    static let popoverWidth: CGFloat = 280
    static let popoverHeight: CGFloat = 320

    // UserDefaults Keys
    static let launchAtLoginKey = "launchAtLogin"
    static let isTimerRunningKey = "isTimerRunning"
}

// Notification Names für App-Events
extension Notification.Name {
    static let breakStarted = Notification.Name("breakStarted")
    static let breakEnded = Notification.Name("breakEnded")
    static let timerStateChanged = Notification.Name("timerStateChanged")
}
