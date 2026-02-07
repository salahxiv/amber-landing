import AppKit

final class DndService {
    static let shared = DndService()
    private init() {}

    /// Prüft ob eine Fullscreen-App aktiv ist
    func isFullscreenAppActive() -> Bool {
        // Debug
        let result = checkFullscreen()
        print("DND Fullscreen Check: \(result)")
        return result
    }

    private func checkFullscreen() -> Bool {
        guard let screen = NSScreen.main else { return false }

        // Berechne Menüleisten-Höhe
        let frame = screen.frame
        let visible = screen.visibleFrame

        // visibleFrame.origin.y = Dock-Höhe (wenn unten)
        // frame.height - visible.height - visible.origin.y = Menüleisten-Höhe
        let menuBarHeight = frame.height - visible.height - visible.origin.y

        print("Screen: \(frame.width)x\(frame.height)")
        print("Visible: \(visible.width)x\(visible.height) at y=\(visible.origin.y)")
        print("MenuBar Height: \(menuBarHeight)")

        // Im Fullscreen-Modus ist menuBarHeight = 0 (oder sehr klein)
        // Normal ist sie ca. 24-37 Pixel
        return menuBarHeight < 10
    }
}
