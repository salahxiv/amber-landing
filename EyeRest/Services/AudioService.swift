import Foundation
import AppKit

/// Service für Audio-Benachrichtigungen bei Pausenstart/-ende
final class AudioService {
    static let shared = AudioService()

    private let settings = SettingsManager.shared

    // MARK: - Sound Types

    enum SoundType {
        case breakStart
        case breakEnd

        var systemSoundName: String {
            switch self {
            case .breakStart:
                return "Glass"    // Sanfter Aufmerksamkeits-Ton
            case .breakEnd:
                return "Blow"     // Abschluss-Ton
            }
        }
    }

    // MARK: - Initialization

    private init() {}

    // MARK: - Public Methods

    /// Spielt einen System-Sound ab, wenn Sounds aktiviert sind
    func playSound(_ type: SoundType) {
        guard settings.soundEnabled else { return }

        if let sound = NSSound(named: NSSound.Name(type.systemSoundName)) {
            sound.play()
        }
    }

    /// Spielt den Sound für Pausenbeginn
    func playBreakStartSound() {
        playSound(.breakStart)
    }

    /// Spielt den Sound für Pausenende
    func playBreakEndSound() {
        playSound(.breakEnd)
    }
}
