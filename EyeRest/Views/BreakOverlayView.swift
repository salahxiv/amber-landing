import SwiftUI
#if os(iOS)
import UIKit
#endif

/// Vollbild-Overlay für die Augenpause
/// Zeigt Atem-Animation, Countdown und zufällige Augenübungen
struct BreakOverlayView: View {
    @ObservedObject var viewModel: TimerViewModel

    // MARK: - Animation State

    @State private var breathScale: CGFloat = 0.85
    @State private var breathOpacity: Double = 0.3
    @State private var particleRotation: Double = 0
    @State private var exerciseOpacity: Double = 0
    @State private var appeared = false

    // MARK: - Übung

    @State private var currentExercise: EyeExercise = EyeExercise.random()

    // MARK: - Theme

    private var theme: OverlayTheme {
        SettingsManager.shared.currentTheme
    }

    var body: some View {
        ZStack {
            // Gradient-Hintergrund
            background

            VStack(spacing: 0) {
                Spacer()

                // Atem-Animation mit Countdown
                breathingCircle
                    .padding(.bottom, 40)

                // Übungstext
                exerciseSection
                    .padding(.bottom, 48)

                // Skip Button (nur wenn Strict Mode nicht aktiv oder kein Pro)
                if !(SettingsManager.shared.strictModeEnabled && SettingsManager.shared.isPro) {
                    skipButton
                        .padding(.bottom, 16)
                }

                Spacer()
                    .frame(height: 60)
            }
            .padding(.horizontal, 32)
        }
        .onAppear {
            startAnimations()
            triggerHaptic(.start)
        }
        .onChange(of: viewModel.remainingSeconds) { _, newValue in
            if newValue == 0 {
                triggerHaptic(.end)
            }
        }
    }

    // MARK: - Hintergrund

    private var background: some View {
        ZStack {
            // Basis-Gradient
            LinearGradient(
                colors: theme.gradientColors,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            // Sanfter Glow hinter der Atem-Animation
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            theme.accentColor.opacity(breathOpacity * 0.15),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 20,
                        endRadius: 250
                    )
                )
                .scaleEffect(breathScale * 1.5)
                .offset(y: -40)
                .blur(radius: 40)
        }
    }

    // MARK: - Atem-Animation

    private var breathingCircle: some View {
        ZStack {
            // Äußere Partikel-Ringe
            particleRings

            // Atem-Kreis (Hintergrund)
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            theme.accentColor.opacity(0.15),
                            theme.accentColor.opacity(0.05),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 10,
                        endRadius: 100
                    )
                )
                .frame(width: 200, height: 200)
                .scaleEffect(breathScale)

            // Fortschritts-Ring
            Circle()
                .trim(from: 0, to: viewModel.progress)
                .stroke(
                    AngularGradient(
                        colors: [theme.accentColor, .green, theme.secondaryAccent, theme.accentColor],
                        center: .center,
                        startAngle: .degrees(-90),
                        endAngle: .degrees(270)
                    ),
                    style: StrokeStyle(lineWidth: 4, lineCap: .round)
                )
                .frame(width: 180, height: 180)
                .rotationEffect(.degrees(-90))
                .scaleEffect(breathScale)
                .shadow(color: theme.accentColor.opacity(0.5), radius: 12)
                .animation(.easeInOut(duration: 0.5), value: viewModel.progress)

            // Hintergrund-Ring
            Circle()
                .stroke(theme.textColor.opacity(0.08), lineWidth: 2)
                .frame(width: 180, height: 180)
                .scaleEffect(breathScale)

            // Countdown + Hinweis
            VStack(spacing: 6) {
                Text("\(viewModel.remainingSeconds)")
                    .font(.system(size: 56, weight: .thin, design: .rounded))
                    .foregroundColor(theme.textColor)
                    .monospacedDigit()
                    .contentTransition(.numericText())
                    .animation(.easeInOut(duration: 0.3), value: viewModel.remainingSeconds)

                Text(breathText)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(theme.accentColor.opacity(0.8))
                    .animation(.easeInOut(duration: 1.0), value: breathScale > 0.95)
            }
        }
    }

    /// Text der sich mit der Atmung ändert
    private var breathText: String {
        breathScale > 0.95 ? String(localized: "break.breatheIn") : String(localized: "break.breatheOut")
    }

    // MARK: - Partikel-Ringe

    private var particleRings: some View {
        ZStack {
            // Erster Ring
            ForEach(0..<8, id: \.self) { index in
                Circle()
                    .fill(theme.particleColor.opacity(0.25))
                    .frame(width: 4, height: 4)
                    .offset(x: 110 * breathScale)
                    .rotationEffect(.degrees(Double(index) * 45 + particleRotation))
            }

            // Zweiter Ring (gegenläufig)
            ForEach(0..<6, id: \.self) { index in
                Circle()
                    .fill(theme.particleSecondaryColor.opacity(0.15))
                    .frame(width: 3, height: 3)
                    .offset(x: 130 * breathScale)
                    .rotationEffect(.degrees(Double(index) * 60 - particleRotation * 0.5))
            }
        }
    }

    // MARK: - Augenübung

    private var exerciseSection: some View {
        VStack(spacing: 16) {
            // Übung Icon
            Image(systemName: currentExercise.icon)
                .font(.system(size: 28))
                .foregroundColor(theme.accentColor)
                .symbolEffect(.pulse, options: .repeating.speed(0.5))

            // Übung Text
            Text(currentExercise.instruction)
                .font(.system(size: 20, weight: .medium, design: .rounded))
                .foregroundColor(theme.textColor)
                .multilineTextAlignment(.center)
                .lineSpacing(4)

            // Zusatz-Hinweis
            Text(currentExercise.hint)
                .font(.subheadline)
                .foregroundColor(theme.subtitleColor)
                .multilineTextAlignment(.center)
        }
        .opacity(exerciseOpacity)
    }

    // MARK: - Skip Button

    private var skipButton: some View {
        Button(action: {
            triggerHaptic(.skip)
            viewModel.skip()
        }) {
            HStack(spacing: 6) {
                Image(systemName: "forward.fill")
                    .font(.system(size: 12))
                Text("break.skip")
                    .font(.system(size: 14, weight: .medium))
            }
            .foregroundColor(theme.textColor.opacity(0.4))
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .background(theme.textColor.opacity(0.06))
            .cornerRadius(20)
        }
        .buttonStyle(.plain)
        .opacity(exerciseOpacity)
    }

    // MARK: - Animationen

    private func startAnimations() {
        // Atem-Zyklus: 4 Sekunden ein, 4 Sekunden aus
        withAnimation(
            .easeInOut(duration: 4.0)
            .repeatForever(autoreverses: true)
        ) {
            breathScale = 1.05
            breathOpacity = 0.6
        }

        // Partikel-Rotation
        withAnimation(
            .linear(duration: 20)
            .repeatForever(autoreverses: false)
        ) {
            particleRotation = 360
        }

        // Übung mit Verzögerung einblenden
        withAnimation(.easeIn(duration: 0.8).delay(0.5)) {
            exerciseOpacity = 1.0
        }
    }

    // MARK: - Haptisches Feedback

    private func triggerHaptic(_ type: HapticType) {
        #if os(iOS)
        switch type {
        case .start:
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
        case .end:
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.warning)
        case .skip:
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
        }
        #endif
    }
}

// MARK: - Haptic Type

private enum HapticType {
    case start, end, skip
}

// MARK: - Augenübungen

/// Eine einzelne Augenübung mit Anweisung und visuellem Hinweis
struct EyeExercise {
    let icon: String
    let instruction: String
    let hint: String

    static let exercises: [EyeExercise] = [
        EyeExercise(
            icon: "eyes",
            instruction: String(localized: "exercise.lookFar.instruction"),
            hint: String(localized: "exercise.lookFar.hint")
        ),
        EyeExercise(
            icon: "arrow.left.and.right",
            instruction: String(localized: "exercise.leftRight.instruction"),
            hint: String(localized: "exercise.leftRight.hint")
        ),
        EyeExercise(
            icon: "arrow.up.and.down",
            instruction: String(localized: "exercise.upDown.instruction"),
            hint: String(localized: "exercise.upDown.hint")
        ),
        EyeExercise(
            icon: "eye.slash.fill",
            instruction: String(localized: "exercise.closeEyes.instruction"),
            hint: String(localized: "exercise.closeEyes.hint")
        ),
        EyeExercise(
            icon: "circle.dotted",
            instruction: String(localized: "exercise.rollEyes.instruction"),
            hint: String(localized: "exercise.rollEyes.hint")
        ),
        EyeExercise(
            icon: "sparkles",
            instruction: String(localized: "exercise.blink.instruction"),
            hint: String(localized: "exercise.blink.hint")
        ),
        EyeExercise(
            icon: "hand.point.up.fill",
            instruction: String(localized: "exercise.focusShift.instruction"),
            hint: String(localized: "exercise.focusShift.hint")
        ),
        EyeExercise(
            icon: "face.smiling",
            instruction: String(localized: "exercise.massage.instruction"),
            hint: String(localized: "exercise.massage.hint")
        )
    ]

    static func random() -> EyeExercise {
        exercises.randomElement() ?? exercises[0]
    }
}

// MARK: - Preview

#Preview {
    BreakOverlayView(viewModel: {
        let vm = TimerViewModel()
        vm.start()
        return vm
    }())
}
