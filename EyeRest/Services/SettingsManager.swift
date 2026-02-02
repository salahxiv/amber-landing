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

    // MARK: - Initialization

    private init() {
        // Gespeicherte Werte laden oder Defaults verwenden
        self.workDuration = UserDefaults.standard.object(forKey: Constants.workDurationKey) as? Int
            ?? Constants.defaultWorkDuration
        self.restDuration = UserDefaults.standard.object(forKey: Constants.restDurationKey) as? Int
            ?? Constants.defaultRestDuration
        self.soundEnabled = UserDefaults.standard.object(forKey: Constants.soundEnabledKey) as? Bool
            ?? true
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
