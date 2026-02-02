import AppKit
import SwiftUI
import Combine

final class AppDelegate: NSObject, NSApplicationDelegate {
    // MARK: - Properties

    private var statusItem: NSStatusItem?
    private var popover: NSPopover?
    private var overlayWindow: NSWindow?
    private var overlayHostingView: NSHostingView<BreakOverlayView>?

    private let timerViewModel = TimerViewModel()
    private var cancellables = Set<AnyCancellable>()

    // MARK: - App Lifecycle

    func applicationDidFinishLaunching(_ notification: Notification) {
        setupMenuBar()
        setupPopover()
        setupOverlayWindow()
        observeTimerState()
    }

    func applicationWillTerminate(_ notification: Notification) {
        timerViewModel.stop()
    }

    // MARK: - Menu Bar Setup

    private func setupMenuBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "eye", accessibilityDescription: "Augen")
            button.action = #selector(togglePopover)
            button.target = self
        }
    }

    // MARK: - Popover Setup

    private func setupPopover() {
        let popover = NSPopover()
        popover.contentSize = NSSize(
            width: Constants.popoverWidth,
            height: Constants.popoverHeight
        )
        popover.behavior = .transient
        popover.animates = true

        let menuBarView = MenuBarView(viewModel: timerViewModel) { [weak self] in
            self?.quitApp()
        }
        popover.contentViewController = NSHostingController(rootView: menuBarView)

        self.popover = popover
    }

    // MARK: - Overlay Window Setup

    private func setupOverlayWindow() {
        guard let screen = NSScreen.main else { return }

        let window = NSWindow(
            contentRect: screen.frame,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )

        window.level = .floating
        window.backgroundColor = NSColor.black.withAlphaComponent(0.85)
        window.isOpaque = false
        window.hasShadow = false
        window.ignoresMouseEvents = false
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]

        let overlayView = BreakOverlayView(viewModel: timerViewModel)
        let hostingView = NSHostingView(rootView: overlayView)
        hostingView.frame = window.contentView?.bounds ?? .zero
        hostingView.autoresizingMask = [.width, .height]

        window.contentView?.addSubview(hostingView)

        self.overlayWindow = window
        self.overlayHostingView = hostingView
    }

    // MARK: - State Observation

    private func observeTimerState() {
        // Beobachte Overlay-Status
        timerViewModel.$showBreakOverlay
            .receive(on: DispatchQueue.main)
            .sink { [weak self] showOverlay in
                if showOverlay {
                    self?.showOverlay()
                } else {
                    self?.hideOverlay()
                }
            }
            .store(in: &cancellables)

        // Beobachte Icon-Änderungen
        timerViewModel.$state
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.updateMenuBarIcon()
            }
            .store(in: &cancellables)
    }

    // MARK: - Menu Bar Actions

    @objc private func togglePopover() {
        guard let button = statusItem?.button else { return }

        if let popover = popover, popover.isShown {
            popover.performClose(nil)
        } else {
            popover?.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)

            // Fokus auf das Popover setzen
            popover?.contentViewController?.view.window?.makeKey()
        }
    }

    private func updateMenuBarIcon() {
        if let button = statusItem?.button {
            let iconName = timerViewModel.menuBarIcon
            button.image = NSImage(systemSymbolName: iconName, accessibilityDescription: "Augen")
        }
    }

    // MARK: - Overlay Actions

    private func showOverlay() {
        guard let screen = NSScreen.main else { return }

        overlayWindow?.setFrame(screen.frame, display: true)
        overlayWindow?.makeKeyAndOrderFront(nil)

        // Aktualisiere die Hosting-View-Größe
        if let contentView = overlayWindow?.contentView {
            overlayHostingView?.frame = contentView.bounds
        }
    }

    private func hideOverlay() {
        overlayWindow?.orderOut(nil)
    }

    // MARK: - App Actions

    private func quitApp() {
        NSApplication.shared.terminate(nil)
    }
}
