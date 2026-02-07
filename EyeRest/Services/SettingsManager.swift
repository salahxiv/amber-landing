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
            }
            NotificationCenter.default.post(name: .settingsChanged, object: nil)
        }
    }

    @Published var restDuration: Int {
        didSet {
            UserDefaults.standard.set(restDuration, forKey: Constants.restDurationKey)
            if !isApplyingExternalChange {
                cloudSync.set(restDuration, forKey: Constants.restDurationKey)
            }
            NotificationCenter.default.post(name: .settingsChanged, object: nil)
        }
    }

    @Published var soundEnabled: Bool {
        didSet {
            UserDefaults.standard.set(soundEnabled, forKey: Constants.soundEnabledKey)
            if !isApplyingExternalChange {
                cloudSync.set(soundEnabled, forKey: Constants.soundEnabledKey)
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
