#if os(macOS)
import SwiftUI

/// Hauptansicht im Menüleisten-Popover
struct MenuBarView: View {
    @ObservedObject var viewModel: TimerViewModel
    @State private var settingsExpanded = false
    @State private var statisticsExpanded = false
    @State private var showPaywall = false

    let onQuit: () -> Void

    private var maxPanelHeight: CGFloat {
        (NSScreen.main?.visibleFrame.height ?? 800) - 20
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            headerView
                .padding(.vertical, 12)

            Divider()

            // Timer Display
            VStack(spacing: 16) {
                // Status Text (extern, nicht mehr im Ring)
                Text(viewModel.statusText)
                    .font(.caption)
                    .foregroundColor(.secondary)

                TimerDisplayView(
                    remainingTime: viewModel.formattedTime,
                    progress: viewModel.progress,
                    statusText: viewModel.statusText,
                    phase: viewModel.currentPhase
                )

                ControlButtonsView(viewModel: viewModel)
            }
            .padding(.vertical, 24)

            Divider()

            // Scrollbarer Bereich für Statistiken, Einstellungen, Pro Upgrade
            ScrollView(.vertical, showsIndicators: true) {
                VStack(spacing: 0) {
                    StatisticsView(isExpanded: $statisticsExpanded)

                    Divider()

                    SettingsView(isExpanded: $settingsExpanded)

                    Divider()

                    ProUpgradeRow(showPaywall: $showPaywall)
                }
            }

            Divider()

            // Beenden Button
            quitButton
        }
        .frame(width: Constants.popoverWidth)
        .frame(maxHeight: maxPanelHeight)
        .onAppear {
            SettingsManager.shared.recordFirstLaunchIfNeeded()
            if SettingsManager.shared.shouldShowPaywallReminder() {
                SettingsManager.shared.markPaywallReminderShown()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    NotificationCenter.default.post(name: .closeMenuPanel, object: nil)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        PaywallWindowController.shared.show()
                    }
                }
            }
        }
    }

    // MARK: - Subviews

    private var headerView: some View {
        HStack {
            Image(systemName: "eye.fill")
                .font(.title2)
                .foregroundColor(.blue)

            Text("EyeRest")
                .font(.headline)
        }
    }

    private var quitButton: some View {
        MenuBarHoverButton(action: onQuit) {
            HStack(spacing: 8) {
                Image(systemName: "xmark.circle")
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
                    .frame(width: 16)
                Text("menubar.quit")
                    .font(.system(size: 13))
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .contentShape(Rectangle())
        }
    }
}

// MARK: - Hover Button für Menübar-Elemente

struct MenuBarHoverButton<Label: View>: View {
    let action: () -> Void
    @ViewBuilder let label: Label
    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            label
        }
        .buttonStyle(.plain)
        .background(
            RoundedRectangle(cornerRadius: 4)
                .fill(Color.primary.opacity(isHovered ? 0.06 : 0))
                .padding(.horizontal, 4)
        )
        .onHover { hovering in
            isHovered = hovering
        }
    }
}

#Preview {
    MenuBarView(viewModel: TimerViewModel()) {
        print("Quit pressed")
    }
}
#endif
