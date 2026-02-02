import SwiftUI

@main
struct EyeRestApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        // Keine sichtbaren Fenster - alles läuft über die Menüleiste
        Settings {
            EmptyView()
        }
    }
}
