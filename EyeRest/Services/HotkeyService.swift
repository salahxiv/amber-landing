import Foundation
import AppKit
import Carbon.HIToolbox

/// Service für globale Tastaturkürzel
/// Ermöglicht das Starten/Pausieren des Timers per Hotkey (Standard: ⌘⇧E)
final class HotkeyService {
    static let shared = HotkeyService()

    // MARK: - Properties

    private var eventHandler: EventHandlerRef?
    private var hotKeyRef: EventHotKeyRef?
    private var callback: (() -> Void)?

    // Hotkey-Konfiguration: ⌘⇧E
    private let keyCode: UInt32 = UInt32(kVK_ANSI_E)
    private let modifiers: UInt32 = UInt32(cmdKey | shiftKey)

    // MARK: - Initialization

    private init() {}

    deinit {
        unregister()
    }

    // MARK: - Public Methods

    /// Registriert den globalen Hotkey
    /// - Parameter action: Die Aktion, die beim Drücken ausgeführt wird
    func register(action: @escaping () -> Void) {
        self.callback = action

        // Event-Typ für Hotkey
        var eventType = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )

        // Event-Handler installieren
        let status = InstallEventHandler(
            GetApplicationEventTarget(),
            { (_, event, userData) -> OSStatus in
                guard let userData = userData else { return OSStatus(eventNotHandledErr) }
                let service = Unmanaged<HotkeyService>.fromOpaque(userData).takeUnretainedValue()
                service.handleHotkey()
                return noErr
            },
            1,
            &eventType,
            Unmanaged.passUnretained(self).toOpaque(),
            &eventHandler
        )

        guard status == noErr else {
            print("HotkeyService: Fehler beim Installieren des Event-Handlers: \(status)")
            return
        }

        // Hotkey registrieren
        let hotKeyID = EventHotKeyID(signature: OSType(0x4552_5354), id: 1)  // "ERST"
        let registerStatus = RegisterEventHotKey(
            keyCode,
            modifiers,
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &hotKeyRef
        )

        if registerStatus != noErr {
            print("HotkeyService: Fehler beim Registrieren des Hotkeys: \(registerStatus)")
        } else {
            print("HotkeyService: Hotkey ⌘⇧E registriert")
        }
    }

    /// Deregistriert den globalen Hotkey
    func unregister() {
        if let hotKeyRef = hotKeyRef {
            UnregisterEventHotKey(hotKeyRef)
            self.hotKeyRef = nil
        }

        if let eventHandler = eventHandler {
            RemoveEventHandler(eventHandler)
            self.eventHandler = nil
        }

        callback = nil
    }

    // MARK: - Private Methods

    private func handleHotkey() {
        DispatchQueue.main.async { [weak self] in
            self?.callback?()
        }
    }
}
