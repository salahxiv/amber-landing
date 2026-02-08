import SwiftUI

/// Kompakte Pro-Upgrade Zeile für Menüleiste (macOS) und Einstellungen
/// Zeigt sich nur wenn der Nutzer kein Pro-Abo hat
struct ProUpgradeRow: View {
    @ObservedObject private var subscriptionManager = SubscriptionManager.shared
    @Binding var showPaywall: Bool

    var body: some View {
        if !subscriptionManager.isPro {
            #if os(macOS)
            macOSRow
            #else
            iOSRow
            #endif
        }
    }

    // MARK: - macOS (kompakt für Popover)

    #if os(macOS)
    private var macOSRow: some View {
        Button(action: openPaywall) {
            HStack(spacing: 8) {
                Image(systemName: "crown.fill")
                    .font(.system(size: 13))
                    .foregroundColor(.yellow)
                    .frame(width: 16)

                Text("pro.unlock")
                    .font(.system(size: 13))

                Spacer()

                Text("PRO")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(.black)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.yellow)
                    .cornerRadius(4)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
    #endif

    // MARK: - iOS (für List-Kontext)

    #if os(iOS)
    private var iOSRow: some View {
        Button(action: openPaywall) {
            HStack(spacing: 12) {
                Image(systemName: "crown.fill")
                    .font(.title3)
                    .foregroundColor(.yellow)

                VStack(alignment: .leading, spacing: 2) {
                    Text("pro.upgrade")
                        .font(.subheadline.bold())
                    Text("pro.unlockAll")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .foregroundColor(.primary)
    }
    #endif

    private func openPaywall() {
        #if os(macOS)
        // Auf macOS öffnen wir die Paywall als eigenes Fenster
        NotificationCenter.default.post(name: .closeMenuPanel, object: nil)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            PaywallWindowController.shared.show()
        }
        #else
        showPaywall = true
        #endif
    }
}

// MARK: - macOS Paywall Window Controller

#if os(macOS)
import AppKit

/// Verwaltet das Paywall-Fenster auf macOS
final class PaywallWindowController {
    static let shared = PaywallWindowController()
    private var window: NSWindow?

    func show() {
        if let existing = window, existing.responds(to: #selector(getter: NSWindow.isVisible)), existing.isVisible {
            existing.makeKeyAndOrderFront(nil)
            return
        }
        window = nil

        let paywallView = PaywallView()
        let hostingView = NSHostingView(rootView: paywallView)
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 420, height: 680),
            styleMask: [.titled, .closable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )

        window.contentView = hostingView
        window.titlebarAppearsTransparent = true
        window.titleVisibility = .hidden
        window.isMovableByWindowBackground = true
        window.center()
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)

        self.window = window
    }
}
#endif
