import SwiftUI

@main
struct EyeRestApp: App {
    #if os(macOS)
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    #else
    @UIApplicationDelegateAdaptor(AppDelegate_iOS.self) var appDelegate
    @StateObject private var timerViewModel = TimerViewModel()
    @ObservedObject private var settings = SettingsManager.shared
    #endif

    // MARK: - Deep Link Handling (iOS Live Activity Buttons)

    #if os(iOS)
    private func handleDeepLink(_ url: URL) {
        guard url.scheme == "eyerest" else { return }

        switch url.host {
        case "skip":
            timerViewModel.skip()
        case "pause":
            timerViewModel.pause()
        case "resume":
            timerViewModel.resume()
        case "toggle":
            timerViewModel.togglePause()
        default:
            break
        }
    }
    #endif

    var body: some Scene {
        #if os(macOS)
        // Keine sichtbaren Fenster - alles läuft über die Menüleiste
        Settings {
            EmptyView()
        }
        #else
        WindowGroup {
            if settings.hasCompletedOnboarding {
                MainTabView(viewModel: timerViewModel)
                    .onOpenURL { url in
                        handleDeepLink(url)
                    }
            } else {
                OnboardingView {
                    timerViewModel.start()
                }
            }
        }
        #endif
    }
}
