import SwiftUI

/// Kreisförmige Timer-Anzeige mit Fortschrittsbalken
struct TimerDisplayView: View {
    let remainingTime: String
    let progress: Double
    let statusText: String
    let phase: TimerPhase
    var size: CGFloat = 140

    // Breathing Animation State
    @State private var breathingScale: CGFloat = 1.0
    @State private var breathingOpacity: Double = 0.2
    // Rest-Phase Glow Pulse
    @State private var restGlowPulse: CGFloat = 0.5

    private var theme: OverlayTheme {
        SettingsManager.shared.currentTheme
    }

    private var progressColor: Color {
        switch phase {
        case .work:
            return .blue
        case .rest:
            return theme.accentColor
        case .idle:
            return .gray
        }
    }

    private var progressGradient: AngularGradient {
        switch phase {
        case .work:
            return AngularGradient(
                colors: [.blue, .cyan, .blue],
                center: .center,
                startAngle: .degrees(-90),
                endAngle: .degrees(270)
            )
        case .rest:
            return AngularGradient(
                colors: [theme.accentColor, theme.secondaryAccent, theme.accentColor],
                center: .center,
                startAngle: .degrees(-90),
                endAngle: .degrees(270)
            )
        case .idle:
            return AngularGradient(
                colors: [.gray, .gray.opacity(0.7), .gray],
                center: .center,
                startAngle: .degrees(-90),
                endAngle: .degrees(270)
            )
        }
    }

    private var ringWidth: CGFloat { 12 }
    private var timerFontSize: CGFloat { size * 0.22 }

    var body: some View {
        ZStack {
            // Breathing Glow für Idle-Zustand
            if phase == .idle {
                Circle()
                    .fill(Color.blue.opacity(breathingOpacity * 0.3))
                    .scaleEffect(breathingScale)
                    .blur(radius: 20)
            }

            // Äußerer feiner Ring (Depth)
            Circle()
                .stroke(Color.primary.opacity(0.1), lineWidth: 1)
                .padding(-4)

            // Hintergrund-Track (dicker)
            Circle()
                .stroke(Color.gray.opacity(phase == .idle ? breathingOpacity * 0.4 : 0.08), lineWidth: ringWidth)
                .scaleEffect(phase == .idle ? breathingScale : 1.0)

            // Fortschritts-Kreis mit Gradient und Glow
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    progressGradient,
                    style: StrokeStyle(lineWidth: ringWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .shadow(color: progressColor.opacity(phase == .rest ? restGlowPulse : 0.5), radius: 12)
                .animation(.spring(duration: 0.4), value: progress)
                .animation(.spring(duration: 0.5), value: phase)

            // Zeit-Anzeige (Status-Text wird extern dargestellt)
            Text(remainingTime)
                .font(.system(size: timerFontSize, weight: .bold, design: .rounded))
                .monospacedDigit()
                .opacity(phase == .idle ? (0.6 + breathingOpacity) : 1.0)
        }
        .frame(width: size, height: size)
        .onAppear {
            startBreathingAnimation()
            startRestGlowIfNeeded()
        }
        .onChange(of: phase) { _, newPhase in
            if newPhase == .idle {
                startBreathingAnimation()
            } else {
                stopBreathingAnimation()
            }
            if newPhase == .rest {
                startRestGlow()
            } else {
                stopRestGlow()
            }
        }
    }

    // MARK: - Breathing Animation (Idle)

    private func startBreathingAnimation() {
        guard phase == .idle else { return }
        withAnimation(
            .easeInOut(duration: 2.0)
            .repeatForever(autoreverses: true)
        ) {
            breathingScale = 1.05
            breathingOpacity = 0.4
        }
    }

    private func stopBreathingAnimation() {
        withAnimation(.easeOut(duration: 0.3)) {
            breathingScale = 1.0
            breathingOpacity = 0.2
        }
    }

    // MARK: - Rest Glow Pulse

    private func startRestGlowIfNeeded() {
        guard phase == .rest else { return }
        startRestGlow()
    }

    private func startRestGlow() {
        withAnimation(
            .easeInOut(duration: 1.5)
            .repeatForever(autoreverses: true)
        ) {
            restGlowPulse = 0.8
        }
    }

    private func stopRestGlow() {
        withAnimation(.easeOut(duration: 0.3)) {
            restGlowPulse = 0.5
        }
    }
}

#Preview {
    VStack(spacing: 30) {
        TimerDisplayView(
            remainingTime: "20:00",
            progress: 1.0,
            statusText: "Bereit",
            phase: .idle,
            size: 240
        )

        HStack(spacing: 20) {
            TimerDisplayView(
                remainingTime: "19:45",
                progress: 0.3,
                statusText: "Arbeiten",
                phase: .work
            )

            TimerDisplayView(
                remainingTime: "15",
                progress: 0.75,
                statusText: "Pause machen",
                phase: .rest
            )
        }
    }
    .padding()
}
