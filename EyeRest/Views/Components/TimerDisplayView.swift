import SwiftUI

/// Kreisförmige Timer-Anzeige mit Fortschrittsbalken
struct TimerDisplayView: View {
    let remainingTime: String
    let progress: Double
    let statusText: String
    let phase: TimerPhase

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

    var body: some View {
        ZStack {
            // Hintergrund-Kreis
            Circle()
                .stroke(Color.gray.opacity(0.2), lineWidth: 8)

            // Fortschritts-Kreis
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    progressColor,
                    style: StrokeStyle(lineWidth: 8, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.linear(duration: 0.5), value: progress)

            // Zeit und Status
            VStack(spacing: 4) {
                Text(remainingTime)
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .monospacedDigit()

                Text(statusText)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .frame(width: 140, height: 140)
    }
}

#Preview {
    VStack(spacing: 20) {
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
