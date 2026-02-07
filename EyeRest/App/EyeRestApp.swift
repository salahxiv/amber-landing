import SwiftUI

@main
struct EyeRestApp: App {
    #if os(macOS)
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    #else
    @UIApplicationDelegateAdaptor(AppDelegate_iOS.self) var appDelegate
    @StateObject private var timerViewModel = TimerViewModel()
    #endif

    var body: some Scene {
        #if os(macOS)
        // Keine sichtbaren Fenster - alles läuft über die Menüleiste
        Settings {
            EmptyView()
        }
        #else
        WindowGroup {
            MainTabView(viewModel: timerViewModel)
        }
        #endif
    }
}
