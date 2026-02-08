import Foundation
import Combine

/// Zentraler Manager für alle App-Einstellungen
final class SettingsManager: ObservableObject {
    static let shared = SettingsManager()

    // MARK: - iCloud Sync

    private let cloudSync = iCloudSyncService.shared
    private var isApplyingExternalChange = false

    // MARK: - Published Properties

    @Published var workDuration: Int {
        didSet {
            UserDefaults.standard.set(workDuration, forKey: Constants.workDurationKey)
            if !isApplyingExternalChange {
                cloudSync.set(workDuration, forKey: Constants.workDurationKey)
                AnalyticsService.shared.track("settings_changed", with: ["setting": "workDuration", "value": "\(workDuration)"])
            }
            NotificationCenter.default.post(name: .settingsChanged, object: nil)
        }
    }

    @Published var restDuration: Int {
        didSet {
            UserDefaults.standard.set(restDuration, forKey: Constants.restDurationKey)
            if !isApplyingExternalChange {
                cloudSync.set(restDuration, forKey: Constants.restDurationKey)
                AnalyticsService.shared.track("settings_changed", with: ["setting": "restDuration", "value": "\(restDuration)"])
            }
            NotificationCenter.default.post(name: .settingsChanged, object: nil)
        }
    }

    @Published var soundEnabled: Bool {
        didSet {
            UserDefaults.standard.set(soundEnabled, forKey: Constants.soundEnabledKey)
            if !isApplyingExternalChange {
                cloudSync.set(soundEnabled, forKey: Constants.soundEnabledKey)
                AnalyticsService.shared.track("settings_changed", with: ["setting": "soundEnabled", "value": "\(soundEnabled)"])
            }
        }
    }

    @Published var dndEnabled: Bool {
        didSet {
            UserDefaults.standard.set(dndEnabled, forKey: Constants.dndEnabledKey)
            if !isApplyingExternalChange {
                cloudSync.set(dndEnabled, forKey: Constants.dndEnabledKey)
            }
        }
    }

    @Published var calendarSyncEnabled: Bool {
        didSet {
            UserDefaults.standard.set(calendarSyncEnabled, forKey: Constants.calendarSyncEnabledKey)
            if !isApplyingExternalChange {
                cloudSync.set(calendarSyncEnabled, forKey: Constants.calendarSyncEnabledKey)
            }
        }
    }

    @Published var hasCompletedOnboarding: Bool {
        didSet {
            UserDefaults.standard.set(hasCompletedOnboarding, forKey: Constants.hasCompletedOnboardingKey)
        }
    }

    @Published var idleDetectionEnabled: Bool {
        didSet {
            UserDefaults.standard.set(idleDetectionEnabled, forKey: Constants.idleDetectionEnabledKey)
            if !isApplyingExternalChange {
                cloudSync.set(idleDetectionEnabled, forKey: Constants.idleDetectionEnabledKey)
            }
        }
    }

    @Published var idleThreshold: Int {
        didSet {
            UserDefaults.standard.set(idleThreshold, forKey: Constants.idleThresholdKey)
            if !isApplyingExternalChange {
                cloudSync.set(idleThreshold, forKey: Constants.idleThresholdKey)
            }
        }
    }

    @Published var showMenuBarCountdown: Bool {
        didSet {
            UserDefaults.standard.set(showMenuBarCountdown, forKey: Constants.showMenuBarCountdownKey)
            if !isApplyingExternalChange {
                cloudSync.set(showMenuBarCountdown, forKey: Constants.showMenuBarCountdownKey)
            }
        }
    }

    @Published var strictModeEnabled: Bool {
        didSet {
            UserDefaults.standard.set(strictModeEnabled, forKey: Constants.strictModeEnabledKey)
            if !isApplyingExternalChange {
                cloudSync.set(strictModeEnabled, forKey: Constants.strictModeEnabledKey)
            }
        }
    }

    @Published var breakStartSound: String {
        didSet {
            UserDefaults.standard.set(breakStartSound, forKey: Constants.breakStartSoundKey)
            if !isApplyingExternalChange {
                cloudSync.set(breakStartSound, forKey: Constants.breakStartSoundKey)
            }
        }
    }

    @Published var breakEndSound: String {
        didSet {
            UserDefaults.standard.set(breakEndSound, forKey: Constants.breakEndSoundKey)
            if !isApplyingExternalChange {
                cloudSync.set(breakEndSound, forKey: Constants.breakEndSoundKey)
            }
        }
    }

    @Published var overlayTheme: String {
        didSet {
            UserDefaults.standard.set(overlayTheme, forKey: Constants.overlayThemeKey)
            if !isApplyingExternalChange {
                cloudSync.set(overlayTheme, forKey: Constants.overlayThemeKey)
            }
        }
    }

    var currentTheme: OverlayTheme {
        OverlayTheme(rawValue: overlayTheme) ?? .ocean
    }

    @Published var preBreakWarningEnabled: Bool {
        didSet {
            UserDefaults.standard.set(preBreakWarningEnabled, forKey: Constants.preBreakWarningEnabledKey)
            if !isApplyingExternalChange {
                cloudSync.set(preBreakWarningEnabled, forKey: Constants.preBreakWarningEnabledKey)
            }
        }
    }

    @Published var preBreakWarningSeconds: Int {
        didSet {
            UserDefaults.standard.set(preBreakWarningSeconds, forKey: Constants.preBreakWarningSecondsKey)
            if !isApplyingExternalChange {
                cloudSync.set(preBreakWarningSeconds, forKey: Constants.preBreakWarningSecondsKey)
            }
        }
    }

    @Published var crossDeviceSyncEnabled: Bool {
        didSet {
            UserDefaults.standard.set(crossDeviceSyncEnabled, forKey: Constants.crossDeviceSyncEnabledKey)
            if !isApplyingExternalChange {
                cloudSync.set(crossDeviceSyncEnabled, forKey: Constants.crossDeviceSyncEnabledKey)
            }
        }
    }

    // MARK: - Initialization

    private init() {
        // Gespeicherte Werte laden oder Defaults verwenden
        self.workDuration = UserDefaults.standard.object(forKey: Constants.workDurationKey) as? Int
            ?? Constants.defaultWorkDuration
        self.restDuration = UserDefaults.standard.object(forKey: Constants.restDurationKey) as? Int
            ?? Constants.defaultRestDuration
        self.soundEnabled = UserDefaults.standard.object(forKey: Constants.soundEnabledKey) as? Bool
            ?? true
        self.dndEnabled = UserDefaults.standard.object(forKey: Constants.dndEnabledKey) as? Bool
            ?? false
        self.calendarSyncEnabled = UserDefaults.standard.object(forKey: Constants.calendarSyncEnabledKey) as? Bool
            ?? false
        self.hasCompletedOnboarding = UserDefaults.standard.bool(forKey: Constants.hasCompletedOnboardingKey)
        self.idleDetectionEnabled = UserDefaults.standard.object(forKey: Constants.idleDetectionEnabledKey) as? Bool
            ?? false
        self.idleThreshold = UserDefaults.standard.object(forKey: Constants.idleThresholdKey) as? Int
            ?? Constants.defaultIdleThreshold
        self.showMenuBarCountdown = UserDefaults.standard.object(forKey: Constants.showMenuBarCountdownKey) as? Bool
            ?? false
        self.strictModeEnabled = UserDefaults.standard.object(forKey: Constants.strictModeEnabledKey) as? Bool
            ?? false
        self.breakStartSound = UserDefaults.standard.string(forKey: Constants.breakStartSoundKey)
            ?? Constants.defaultBreakStartSound
        self.breakEndSound = UserDefaults.standard.string(forKey: Constants.breakEndSoundKey)
            ?? Constants.defaultBreakEndSound
        self.overlayTheme = UserDefaults.standard.string(forKey: Constants.overlayThemeKey)
            ?? Constants.defaultOverlayTheme
        self.preBreakWarningEnabled = UserDefaults.standard.object(forKey: Constants.preBreakWarningEnabledKey) as? Bool
            ?? false
        self.preBreakWarningSeconds = UserDefaults.standard.object(forKey: Constants.preBreakWarningSecondsKey) as? Int
            ?? Constants.defaultPreBreakWarningSeconds
        self.crossDeviceSyncEnabled = UserDefaults.standard.object(forKey: Constants.crossDeviceSyncEnabledKey) as? Bool
            ?? false

        setupCloudSync()
        pushToCloudIfNeeded()
    }

    // MARK: - Cloud Sync Setup

    private func setupCloudSync() {
        cloudSync.onExternalChange = { [weak self] key, value in
            self?.handleExternalChange(key: key, value: value)
        }
    }

    private func handleExternalChange(key: String, value: Any?) {
        isApplyingExternalChange = true
        defer { isApplyingExternalChange = false }

        switch key {
        case Constants.workDurationKey:
            if let intValue = value as? Int64 {
                workDuration = Int(intValue)
            }
        case Constants.restDurationKey:
            if let intValue = value as? Int64 {
                restDuration = Int(intValue)
            }
        case Constants.soundEnabledKey:
            if let boolValue = value as? Bool {
                soundEnabled = boolValue
            }
        case Constants.dndEnabledKey:
            if let boolValue = value as? Bool {
                dndEnabled = boolValue
            }
        case Constants.calendarSyncEnabledKey:
            if let boolValue = value as? Bool {
                calendarSyncEnabled = boolValue
            }
        case Constants.idleDetectionEnabledKey:
            if let boolValue = value as? Bool {
                idleDetectionEnabled = boolValue
            }
        case Constants.idleThresholdKey:
            if let intValue = value as? Int64 {
                idleThreshold = Int(intValue)
            }
        case Constants.showMenuBarCountdownKey:
            if let boolValue = value as? Bool {
                showMenuBarCountdown = boolValue
            }
        case Constants.strictModeEnabledKey:
            if let boolValue = value as? Bool {
                strictModeEnabled = boolValue
            }
        case Constants.breakStartSoundKey:
            if let stringValue = value as? String {
                breakStartSound = stringValue
            }
        case Constants.breakEndSoundKey:
            if let stringValue = value as? String {
                breakEndSound = stringValue
            }
        case Constants.overlayThemeKey:
            if let stringValue = value as? String {
                overlayTheme = stringValue
            }
        case Constants.preBreakWarningEnabledKey:
            if let boolValue = value as? Bool {
                preBreakWarningEnabled = boolValue
            }
        case Constants.preBreakWarningSecondsKey:
            if let intValue = value as? Int64 {
                preBreakWarningSeconds = Int(intValue)
            }
        case Constants.crossDeviceSyncEnabledKey:
            if let boolValue = value as? Bool {
                crossDeviceSyncEnabled = boolValue
            }
        default:
            break
        }
    }

    /// Initiale Werte in Cloud schreiben falls leer
    private func pushToCloudIfNeeded() {
        if cloudSync.integer(forKey: Constants.workDurationKey) == nil {
            cloudSync.set(workDuration, forKey: Constants.workDurationKey)
        }
        if cloudSync.integer(forKey: Constants.restDurationKey) == nil {
            cloudSync.set(restDuration, forKey: Constants.restDurationKey)
        }
        if cloudSync.bool(forKey: Constants.soundEnabledKey) == nil {
            cloudSync.set(soundEnabled, forKey: Constants.soundEnabledKey)
        }
        if cloudSync.bool(forKey: Constants.dndEnabledKey) == nil {
            cloudSync.set(dndEnabled, forKey: Constants.dndEnabledKey)
        }
        if cloudSync.bool(forKey: Constants.calendarSyncEnabledKey) == nil {
            cloudSync.set(calendarSyncEnabled, forKey: Constants.calendarSyncEnabledKey)
        }
    }

    // MARK: - Pro Status

    /// Prüft ob der Nutzer Pro ist (delegiert an SubscriptionManager)
    var isPro: Bool {
        SubscriptionManager.shared.isPro
    }

    // MARK: - Paywall Reminder

    /// Setzt das erste Start-Datum, falls noch nicht gesetzt
    func recordFirstLaunchIfNeeded() {
        if UserDefaults.standard.object(forKey: Constants.firstLaunchDateKey) == nil {
            UserDefaults.standard.set(Date(), forKey: Constants.firstLaunchDateKey)
        }
    }

    /// Prüft ob eine sanfte Paywall-Erinnerung angezeigt werden soll
    func shouldShowPaywallReminder() -> Bool {
        guard !isPro else { return false }

        guard let firstLaunch = UserDefaults.standard.object(forKey: Constants.firstLaunchDateKey) as? Date else {
            return false
        }

        let daysSinceFirstLaunch = Calendar.current.dateComponents([.day], from: firstLaunch, to: Date()).day ?? 0

        // Noch zu früh für die erste Erinnerung
        if daysSinceFirstLaunch < Constants.paywallReminderInitialDays {
            return false
        }

        // Letzte Erinnerung prüfen
        if let lastReminder = UserDefaults.standard.object(forKey: Constants.lastPaywallReminderDateKey) as? Date {
            let daysSinceLastReminder = Calendar.current.dateComponents([.day], from: lastReminder, to: Date()).day ?? 0
            return daysSinceLastReminder >= Constants.paywallReminderRepeatDays
        }

        // Erste Erinnerung — noch nie gezeigt
        return true
    }

    /// Markiert, dass die Paywall-Erinnerung gerade angezeigt wurde
    func markPaywallReminderShown() {
        UserDefaults.standard.set(Date(), forKey: Constants.lastPaywallReminderDateKey)
    }

    // MARK: - Helper Methods

    /// Formatierte Arbeitszeit als String
    var formattedWorkDuration: String {
        let minutes = workDuration / 60
        return "\(minutes) Min"
    }

    /// Formatierte Pausenzeit als String
    var formattedRestDuration: String {
        return "\(restDuration) Sek"
    }

    /// Setzt alle Einstellungen auf Standardwerte zurück
    func resetToDefaults() {
        workDuration = Constants.defaultWorkDuration
        restDuration = Constants.defaultRestDuration
        soundEnabled = true
    }

}
