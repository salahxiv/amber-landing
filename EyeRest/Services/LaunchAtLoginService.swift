#if os(macOS)
import Foundation
import ServiceManagement

/// Service für Login-Item-Verwaltung (Autostart)
final class LaunchAtLoginService {
    static let shared = LaunchAtLoginService()

    private init() {}

    // MARK: - Properties

    /// Prüft ob die App beim Login startet
    var isEnabled: Bool {
        SMAppService.mainApp.status == .enabled
    }

    // MARK: - Methods

    /// Aktiviert Autostart beim Login
    func enable() throws {
        try SMAppService.mainApp.register()
    }

    /// Deaktiviert Autostart beim Login
    func disable() throws {
        try SMAppService.mainApp.unregister()
    }

    /// Schaltet Autostart um
    func toggle() throws {
        if isEnabled {
            try disable()
        } else {
            try enable()
        }
    }
}
#endif
