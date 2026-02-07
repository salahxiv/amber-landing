import Foundation
import Combine

/// Zentraler Manager für alle App-Einstellungen
final class SettingsManager: ObservableObject {
    static let shared = SettingsManager()

    // MARK: - Published Properties

    @Published var workDuration: Int {
        didSet {
            UserDefaults.standard.set(workDuration, forKey: Constants.workDurationKey)
            NotificationCenter.default.post(name: .settingsChanged, object: nil)
        }
    }

    @Published var restDuration: Int {
        didSet {
            UserDefaults.standard.set(restDuration, forKey: Constants.restDurationKey)
            NotificationCenter.default.post(name: .settingsChanged, object: nil)
        }
    }

    @Published var soundEnabled: Bool {
        didSet {
            UserDefaults.standard.set(soundEnabled, forKey: Constants.soundEnabledKey)
        }
    }

    @Published var dndEnabled: Bool {
        didSet {
            UserDefaults.standard.set(dndEnabled, forKey: Constants.dndEnabledKey)
        }
    }

    @Published var calendarSyncEnabled: Bool {
        didSet {
            UserDefaults.standard.set(calendarSyncEnabled, forKey: Constants.calendarSyncEnabledKey)
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
