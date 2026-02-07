import Foundation
#if os(macOS)
import AppKit
#else
import AVFoundation
import AudioToolbox
#endif

/// Service für Audio-Benachrichtigungen bei Pausenstart/-ende
final class AudioService {
    static let shared = AudioService()

    private let settings = SettingsManager.shared

    #if os(iOS)
    private var audioPlayer: AVAudioPlayer?
    #endif

    // MARK: - Sound Types

    enum SoundType {
        case breakStart
        case breakEnd

        #if os(macOS)
        var systemSoundName: String {
            switch self {
            case .breakStart:
                return "Glass"    // Sanfter Aufmerksamkeits-Ton
            case .breakEnd:
                return "Blow"     // Abschluss-Ton
            }
        }
        #else
        var systemSoundID: UInt32 {
            switch self {
            case .breakStart:
                return 1007  // Tink-ähnlicher Ton
            case .breakEnd:
                return 1001  // Receive-ähnlicher Ton
            }
        }
        #endif
    }

    // MARK: - Initialization

    private init() {}

    // MARK: - Public Methods

    /// Spielt einen Sound ab, wenn Sounds aktiviert sind
    func playSound(_ type: SoundType) {
        guard settings.soundEnabled else { return }

        #if os(macOS)
        if let sound = NSSound(named: NSSound.Name(type.systemSoundName)) {
            sound.play()
        }
        #else
        AudioServicesPlaySystemSound(type.systemSoundID)
        #endif
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
