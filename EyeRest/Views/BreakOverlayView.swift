import SwiftUI

/// Vollbild-Overlay für die 20-Sekunden-Pause
struct BreakOverlayView: View {
    @ObservedObject var viewModel: TimerViewModel

    var body: some View {
        ZStack {
            // Halbtransparenter Hintergrund
            Color.black.opacity(0.85)
                .ignoresSafeArea()

            // Inhalt
            VStack(spacing: 40) {
                Spacer()

                // Icon
                Image(systemName: "eye.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.white)
                    .symbolEffect(.pulse, options: .repeating)

                // Titel
                Text("Zeit für eine Pause")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)

                // Anweisung
                Text("Schau auf etwas 6 Meter entferntes")
                    .font(.title2)
                    .foregroundColor(.white.opacity(0.8))

                // Countdown
                ZStack {
                    // Hintergrund-Kreis
                    Circle()
                        .stroke(Color.white.opacity(0.2), lineWidth: 6)
                        .frame(width: 120, height: 120)

                    // Fortschritts-Kreis mit Gradient und Glow
                    Circle()
                        .trim(from: 0, to: viewModel.progress)
                        .stroke(
                            AngularGradient(
                                colors: [.green, .mint, .green],
                                center: .center,
                                startAngle: .degrees(-90),
                                endAngle: .degrees(270)
                            ),
                            style: StrokeStyle(lineWidth: 6, lineCap: .round)
                        )
                        .frame(width: 120, height: 120)
                        .rotationEffect(.degrees(-90))
                        .shadow(color: .green.opacity(0.6), radius: 10)
                        .animation(.easeInOut(duration: 0.3), value: viewModel.progress)

                    // Zeit
                    VStack(spacing: 2) {
                        Text("\(viewModel.remainingSeconds)")
                            .font(.system(size: 48, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .monospacedDigit()

                        Text("Sekunden")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.6))
                    }
                }
                .padding(.vertical, 20)

                // Skip Button
                Button(action: {
                    viewModel.skip()
                }) {
                    HStack {
                        Image(systemName: "forward.fill")
                        Text("Überspringen")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color.white.opacity(0.2))
                    .cornerRadius(25)
                }
                .buttonStyle(.plain)

                Spacer()
            }
            .padding()
        }
    }
}

#Preview {
    BreakOverlayView(viewModel: {
        let vm = TimerViewModel()
        vm.start()
        return vm
    }())
}
