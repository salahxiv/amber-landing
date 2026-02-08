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

    // MARK: - Sound Option

    struct SoundOption: Identifiable {
        let id: String
        let label: String
        #if os(macOS)
        let soundName: String
        #else
        let soundID: UInt32
        #endif
    }

    // MARK: - Verfügbare Sounds

    #if os(macOS)
    static let availableSounds: [SoundOption] = [
        SoundOption(id: "default", label: "Standard", soundName: "Glass"),
        SoundOption(id: "blow", label: "Blow", soundName: "Blow"),
        SoundOption(id: "bottle", label: "Bottle", soundName: "Bottle"),
        SoundOption(id: "frog", label: "Frog", soundName: "Frog"),
        SoundOption(id: "funk", label: "Funk", soundName: "Funk"),
        SoundOption(id: "glass", label: "Glass", soundName: "Glass"),
        SoundOption(id: "hero", label: "Hero", soundName: "Hero"),
        SoundOption(id: "morse", label: "Morse", soundName: "Morse"),
        SoundOption(id: "ping", label: "Ping", soundName: "Ping"),
        SoundOption(id: "pop", label: "Pop", soundName: "Pop"),
        SoundOption(id: "purr", label: "Purr", soundName: "Purr"),
        SoundOption(id: "sosumi", label: "Sosumi", soundName: "Sosumi"),
        SoundOption(id: "submarine", label: "Submarine", soundName: "Submarine"),
        SoundOption(id: "tink", label: "Tink", soundName: "Tink")
    ]
    #else
    static let availableSounds: [SoundOption] = [
        SoundOption(id: "default", label: "Standard", soundID: 1007),
        SoundOption(id: "chime", label: "Chime", soundID: 1025),
        SoundOption(id: "glass", label: "Glass", soundID: 1054),
        SoundOption(id: "bell", label: "Bell", soundID: 1013),
        SoundOption(id: "bloom", label: "Bloom", soundID: 1021),
        SoundOption(id: "calypso", label: "Calypso", soundID: 1022),
        SoundOption(id: "choo", label: "Choo Choo", soundID: 1023),
        SoundOption(id: "descent", label: "Descent", soundID: 1024),
        SoundOption(id: "fanfare", label: "Fanfare", soundID: 1026),
        SoundOption(id: "ladder", label: "Ladder", soundID: 1027),
        SoundOption(id: "minuet", label: "Minuet", soundID: 1028),
        SoundOption(id: "news", label: "News Flash", soundID: 1029),
        SoundOption(id: "noir", label: "Noir", soundID: 1030)
    ]
    #endif

    // MARK: - Initialization

    private init() {}

    // MARK: - Public Methods

    /// Spielt den Sound für Pausenbeginn
    func playBreakStartSound() {
        guard settings.soundEnabled else { return }

        let soundId = (SubscriptionManager.shared.isPro) ? settings.breakStartSound : "default"
        playSound(id: soundId, fallbackDefault: true)
    }

    /// Spielt den Sound für Pausenende
    func playBreakEndSound() {
        guard settings.soundEnabled else { return }

        let soundId = (SubscriptionManager.shared.isPro) ? settings.breakEndSound : "default"
        playSound(id: soundId, fallbackDefault: false)
    }

    /// Spielt einen Sound zur Vorschau in den Einstellungen
    func previewSound(id: String) {
        playSound(id: id, fallbackDefault: true)
    }

    // MARK: - Private

    private func playSound(id: String, fallbackDefault: Bool) {
        guard let option = Self.availableSounds.first(where: { $0.id == id })
                ?? Self.availableSounds.first else { return }

        #if os(macOS)
        if let sound = NSSound(named: NSSound.Name(option.soundName)) {
            sound.play()
        }
        #else
        AudioServicesPlaySystemSound(option.soundID)
        #endif
    }
}
