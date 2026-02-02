import SwiftUI
import StoreKit

/// Ansicht für Tip Jar im Menüleisten-Popover
struct TipJarView: View {
    @Binding var isExpanded: Bool
    @StateObject private var tipJar = TipJarService.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header mit Toggle
            Button(action: {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isExpanded.toggle()
                }
                NotificationCenter.default.post(name: .settingsExpandedChanged, object: nil)
            }) {
                HStack {
                    Image(systemName: "heart.fill")
                        .foregroundColor(.pink)

                    Text("Tip Jar")
                        .font(.subheadline)
                        .fontWeight(.medium)

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)

            // Erweiterte Optionen
            if isExpanded {
                VStack(spacing: 10) {
                    if tipJar.showThankYou {
                        // Danke-Nachricht
                        thankYouView
                    } else if tipJar.isLoading && tipJar.tips.isEmpty {
                        // Laden
                        ProgressView()
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 20)
                    } else if tipJar.tips.isEmpty {
                        // Keine Produkte
                        Text("Nicht verfügbar")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                    } else {
                        // Tip Buttons
                        ForEach(tipJar.tips, id: \.id) { product in
                            TipButton(product: product, isLoading: tipJar.isLoading) {
                                Task {
                                    await tipJar.purchase(product)
                                }
                            }
                        }
                    }

                    // Fehlermeldung
                    if let error = tipJar.purchaseError {
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 8)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }

    private var thankYouView: some View {
        VStack(spacing: 8) {
            Image(systemName: "heart.circle.fill")
                .font(.largeTitle)
                .foregroundColor(.pink)

            Text("Vielen Dank!")
                .font(.headline)

            Text("Deine Unterstützung bedeutet mir viel")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
    }
}

/// Button für einen einzelnen Tip
struct TipButton: View {
    let product: Product
    let isLoading: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Text(product.tipEmoji)
                    .font(.title3)

                VStack(alignment: .leading, spacing: 2) {
                    Text(product.tipDescription)
                        .font(.subheadline)
                        .fontWeight(.medium)
                }

                Spacer()

                if isLoading {
                    ProgressView()
                        .scaleEffect(0.7)
                } else {
                    Text(product.displayPrice)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.blue)
                }
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(Color.primary.opacity(0.05))
            .cornerRadius(8)
        }
        .buttonStyle(.plain)
        .disabled(isLoading)
    }
}

#Preview {
    TipJarView(isExpanded: .constant(true))
        .frame(width: 280)
        .padding()
}
