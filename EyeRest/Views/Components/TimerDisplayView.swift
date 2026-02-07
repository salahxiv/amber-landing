import SwiftUI

/// Kreisförmige Timer-Anzeige mit Fortschrittsbalken
struct TimerDisplayView: View {
    let remainingTime: String
    let progress: Double
    let statusText: String
    let phase: TimerPhase

    // Breathing Animation State
    @State private var breathingScale: CGFloat = 1.0
    @State private var breathingOpacity: Double = 0.2

    private var progressColor: Color {
        switch phase {
        case .work:
            return .blue
        case .rest:
            return .green
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
                colors: [.green, .mint, .green],
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

    var body: some View {
        ZStack {
            // Breathing Glow für Idle-Zustand
            if phase == .idle {
                Circle()
                    .fill(Color.blue.opacity(breathingOpacity * 0.3))
                    .scaleEffect(breathingScale)
                    .blur(radius: 20)
            }

            // Hintergrund-Kreis
            Circle()
                .stroke(Color.gray.opacity(phase == .idle ? breathingOpacity : 0.2), lineWidth: 8)
                .scaleEffect(phase == .idle ? breathingScale : 1.0)

            // Fortschritts-Kreis mit Gradient und Glow
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    progressGradient,
                    style: StrokeStyle(lineWidth: 8, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .shadow(color: progressColor.opacity(0.5), radius: 8)
                .animation(.easeInOut(duration: 0.3), value: progress)

            // Zeit und Status
            VStack(spacing: 4) {
                Text(remainingTime)
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .opacity(phase == .idle ? (0.6 + breathingOpacity) : 1.0)

                Text(statusText)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .frame(width: 140, height: 140)
        .onAppear {
            startBreathingAnimation()
        }
        .onChange(of: phase) { _, newPhase in
            if newPhase == .idle {
                startBreathingAnimation()
            } else {
                stopBreathingAnimation()
            }
        }
    }

    // MARK: - Breathing Animation

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
}

#Preview {
    VStack(spacing: 20) {
        TimerDisplayView(
            remainingTime: "20:00",
            progress: 1.0,
            statusText: "Bereit",
            phase: .idle
        )

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
    .padding()
}
