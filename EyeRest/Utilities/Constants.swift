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
    static let dndEnabledKey = "dndEnabled"
    static let calendarSyncEnabledKey = "calendarSyncEnabled"
    static let hasCompletedOnboardingKey = "hasCompletedOnboarding"
    static let idleDetectionEnabledKey = "idleDetectionEnabled"
    static let idleThresholdKey = "idleThreshold"
    static let showMenuBarCountdownKey = "showMenuBarCountdown"
    static let strictModeEnabledKey = "strictModeEnabled"
    static let breakStartSoundKey = "breakStartSound"
    static let breakEndSoundKey = "breakEndSound"
    static let overlayThemeKey = "overlayTheme"
    static let preBreakWarningEnabledKey = "preBreakWarningEnabled"
    static let preBreakWarningSecondsKey = "preBreakWarningSeconds"

    // Sound Defaults
    static let defaultBreakStartSound = "default"
    static let defaultBreakEndSound = "default"

    // Theme Default
    static let defaultOverlayTheme = "ocean"

    // Pre-Break Warning Default
    static let defaultPreBreakWarningSeconds: Int = 60  // 1 Minute

    // Idle Detection Defaults (macOS)
    static let defaultIdleThreshold: Int = 5 * 60  // 5 Minuten in Sekunden

    // Cross-Device Sync Keys
    static let crossDeviceSyncEnabledKey = "crossDeviceSyncEnabled"
    static let crossDeviceBreakTimestampKey = "crossDeviceBreakTimestamp"
    static let crossDeviceBreakDeviceIDKey = "crossDeviceBreakDeviceID"
    static let crossDeviceBreakDeviceNameKey = "crossDeviceBreakDeviceName"
    static let localDeviceIDKey = "localDeviceID"

    // Review Prompting
    static let lastReviewPromptDateKey = "lastReviewPromptDate"
    static let reviewPromptMinimumDays: Int = 30

    // Paywall Reminder
    static let firstLaunchDateKey = "firstLaunchDate"
    static let lastPaywallReminderDateKey = "lastPaywallReminderDate"
    static let paywallReminderInitialDays: Int = 3     // Erste Erinnerung nach 3 Tagen
    static let paywallReminderRepeatDays: Int = 7      // Danach alle 7 Tage

    // Subscription Product IDs (App Store Connect)
    static let subscriptionMonthly = "com.devsalah.eyerest.pro.monthly"    // 1,99€/Monat
    static let subscriptionYearly = "com.devsalah.eyerest.pro.yearly"      // 14,99€/Jahr
    static let subscriptionLifetime = "com.devsalah.eyerest.pro.lifetime"  // 39,99€ einmalig

    // Subscription Group ID
    static let subscriptionGroupID = "eyerest_pro"
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
    static let closeMenuPanel = Notification.Name("closeMenuPanel")
    static let proStatusChanged = Notification.Name("proStatusChanged")
    static let crossDeviceBreakReceived = Notification.Name("crossDeviceBreakReceived")
}
