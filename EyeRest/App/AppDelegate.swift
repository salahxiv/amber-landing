import AppKit
import SwiftUI
import Combine

final class AppDelegate: NSObject, NSApplicationDelegate {
    // MARK: - Properties

    private var statusItem: NSStatusItem?
    private var menuPanel: NSPanel?
    private var menuHostingView: NSHostingView<MenuBarView>?
    private var overlayWindow: NSWindow?
    private var overlayHostingView: NSHostingView<BreakOverlayView>?
    private var eventMonitor: Any?
    private var localEventMonitor: Any?

    private let timerViewModel = TimerViewModel()
    private var cancellables = Set<AnyCancellable>()

    // MARK: - App Lifecycle

    func applicationDidFinishLaunching(_ notification: Notification) {
        setupMenuBar()
        setupMenuPanel()
        setupOverlayWindow()
        observeTimerState()
    }

    func applicationWillTerminate(_ notification: Notification) {
        timerViewModel.stop()
        stopEventMonitors()
    }

    // MARK: - Menu Bar Setup

    private func setupMenuBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "eye", accessibilityDescription: "Augen")
            button.action = #selector(toggleMenu)
            button.target = self
        }
    }

    // MARK: - Menu Panel Setup

    private func setupMenuPanel() {
        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: Constants.popoverWidth, height: Constants.popoverHeight),
            styleMask: [.borderless, .nonactivatingPanel, .hudWindow],
            backing: .buffered,
            defer: false
        )

        // Konfiguration für Vollbild-Kompatibilität
        panel.level = .mainMenu + 1
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = true
        panel.hidesOnDeactivate = false
        panel.worksWhenModal = true
        panel.becomesKeyOnlyIfNeeded = true

        // Visual Effect Hintergrund
        let visualEffect = NSVisualEffectView(frame: NSRect(x: 0, y: 0, width: Constants.popoverWidth, height: Constants.popoverHeight))
        visualEffect.material = .popover
        visualEffect.blendingMode = .behindWindow
        visualEffect.state = .active
        visualEffect.wantsLayer = true
        visualEffect.layer?.cornerRadius = 10
        visualEffect.layer?.masksToBounds = true

        panel.contentView = visualEffect

        let menuBarView = MenuBarView(viewModel: timerViewModel) { [weak self] in
            self?.quitApp()
        }
        let hostingView = NSHostingView(rootView: menuBarView)
        hostingView.frame = visualEffect.bounds
        hostingView.autoresizingMask = [.width, .height]

        visualEffect.addSubview(hostingView)

        self.menuPanel = panel
        self.menuHostingView = hostingView
    }

    // MARK: - Overlay Window Setup

    private func setupOverlayWindow() {
        guard let screen = NSScreen.main else { return }

        // NSPanel für bessere Vollbild-Kompatibilität
        let window = NSPanel(
            contentRect: screen.frame,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        // Gleiche Konfiguration wie menuPanel für Vollbild-Support
        window.level = .mainMenu + 2
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        window.backgroundColor = NSColor.black.withAlphaComponent(0.85)
        window.isOpaque = false
        window.hasShadow = false
        window.ignoresMouseEvents = false
        window.hidesOnDeactivate = false
        window.worksWhenModal = true

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

        timerViewModel.$state
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.updateMenuBarIcon()
            }
            .store(in: &cancellables)
    }

    // MARK: - Menu Actions

    @objc private func toggleMenu() {
        guard let button = statusItem?.button,
              let panel = menuPanel else { return }

        if panel.isVisible {
            hideMenu()
        } else {
            showMenu(relativeTo: button)
        }
    }

    private func showMenu(relativeTo button: NSStatusBarButton) {
        guard let panel = menuPanel else { return }

        // Position berechnen
        let buttonRect = button.window?.convertToScreen(button.convert(button.bounds, to: nil)) ?? .zero
        let panelOrigin = NSPoint(
            x: buttonRect.midX - panel.frame.width / 2,
            y: buttonRect.minY - panel.frame.height - 4
        )

        panel.setFrameOrigin(panelOrigin)
        panel.orderFrontRegardless()

        startEventMonitors()
    }

    private func hideMenu() {
        menuPanel?.orderOut(nil)
        stopEventMonitors()
    }

    private func updateMenuBarIcon() {
        if let button = statusItem?.button {
            let iconName = timerViewModel.menuBarIcon
            button.image = NSImage(systemSymbolName: iconName, accessibilityDescription: "Augen")
        }
    }

    // MARK: - Event Monitors

    private func startEventMonitors() {
        // Global: Klicks außerhalb der App
        eventMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
            self?.hideMenu()
        }

        // Lokal: Escape-Taste
        localEventMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            if event.keyCode == 53 { // Escape
                self?.hideMenu()
                return nil
            }
            return event
        }
    }

    private func stopEventMonitors() {
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
            eventMonitor = nil
        }
        if let monitor = localEventMonitor {
            NSEvent.removeMonitor(monitor)
            localEventMonitor = nil
        }
    }

    // MARK: - Overlay Actions

    private func showOverlay() {
        guard let window = overlayWindow else { return }

        let mouseLocation = NSEvent.mouseLocation
        let currentScreen = NSScreen.screens.first { $0.frame.contains(mouseLocation) } ?? NSScreen.main

        guard let screen = currentScreen else { return }

        window.setFrame(screen.frame, display: true)

        if let contentView = window.contentView {
            overlayHostingView?.frame = contentView.bounds
        }

        window.orderFrontRegardless()

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { [weak self] in
            NSApp.activate(ignoringOtherApps: true)
            self?.overlayWindow?.makeKeyAndOrderFront(nil)
            self?.overlayWindow?.orderFrontRegardless()
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
