#if os(macOS)
import AppKit
import CoreGraphics

final class DndService {
    static let shared = DndService()
    private init() {}

    // MARK: - Fullscreen Detection

    /// Prüft ob eine Fullscreen-App aktiv ist
    func isFullscreenAppActive() -> Bool {
        let result = checkFullscreen()
        print("DND Fullscreen Check: \(result)")
        return result
    }

    private func checkFullscreen() -> Bool {
        guard let screen = NSScreen.main else { return false }

        let frame = screen.frame
        let visible = screen.visibleFrame
        let menuBarHeight = frame.height - visible.height - visible.origin.y

        return menuBarHeight < 10
    }

    // MARK: - Idle Detection

    /// Sekunden seit letzter Benutzeraktivität (Maus/Tastatur)
    var secondsSinceLastUserActivity: TimeInterval {
        let mouseMoved = CGEventSource.secondsSinceLastEventType(.combinedSessionState, eventType: .mouseMoved)
        let keyDown = CGEventSource.secondsSinceLastEventType(.combinedSessionState, eventType: .keyDown)
        let mouseDown = CGEventSource.secondsSinceLastEventType(.combinedSessionState, eventType: .leftMouseDown)
        let scrollWheel = CGEventSource.secondsSinceLastEventType(.combinedSessionState, eventType: .scrollWheel)

        // Kürzeste Zeit seit letzter Aktivität
        return min(mouseMoved, keyDown, mouseDown, scrollWheel)
    }

    /// Prüft ob der Benutzer idle ist (länger als Schwellenwert inaktiv)
    func isUserIdle(threshold: TimeInterval) -> Bool {
        return secondsSinceLastUserActivity >= threshold
    }
}
#endif
