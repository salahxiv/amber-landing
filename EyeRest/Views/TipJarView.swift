import SwiftUI
import StoreKit

/// Ansicht für Tip Jar im Menüleisten-Popover
struct TipJarView: View {
    @Binding var isExpanded: Bool
    @ObservedObject private var tipJar = TipJarService.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header mit Toggle
            Button(action: {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isExpanded.toggle()
                }
                NotificationCenter.default.post(name: .settingsExpandedChanged, object: nil)
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "heart.fill")
                        .font(.system(size: 13))
                        .foregroundColor(.pink)
                        .frame(width: 16)

                    Text("Tip Jar")
                        .font(.system(size: 13))

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(.secondary)
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            // Erweiterte Optionen
            if isExpanded {
                VStack(spacing: 6) {
                    if tipJar.showThankYou {
                        // Danke-Nachricht
                        thankYouView
                    } else if tipJar.isLoading && tipJar.tips.isEmpty {
                        // Laden
                        ProgressView()
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                    } else if tipJar.tips.isEmpty {
                        // Keine Produkte
                        Text("Nicht verfügbar")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
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
                .padding(.horizontal, 12)
                .padding(.bottom, 6)
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
