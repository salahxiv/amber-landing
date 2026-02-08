import SwiftUI
import StoreKit

/// Paywall-Ansicht für Pro-Upgrade
/// Erscheint wenn Free-User ein gesperrtes Feature aktivieren
struct PaywallView: View {
    @ObservedObject private var subscriptionManager = SubscriptionManager.shared
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            // Hintergrund
            LinearGradient(
                colors: [
                    Color(red: 0.05, green: 0.08, blue: 0.18),
                    Color(red: 0.08, green: 0.12, blue: 0.25)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {
                    // Close Button
                    HStack {
                        Spacer()
                        Button(action: { dismiss() }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.title2)
                                .foregroundColor(.white.opacity(0.4))
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.top, 8)

                    // Header
                    headerSection

                    // Benefits
                    benefitsSection

                    // Produkte
                    productsSection

                    // Restore
                    restoreButton

                    // Legal
                    legalText
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 32)
            }
        }
        .onAppear {
            AnalyticsService.shared.track("paywall_viewed")
        }
        #if os(macOS)
        .frame(width: 420, height: 680)
        #endif
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: 12) {
            // Pro Badge
            ZStack {
                Circle()
                    .fill(Color.yellow.opacity(0.15))
                    .frame(width: 80, height: 80)

                Image(systemName: "crown.fill")
                    .font(.system(size: 36))
                    .foregroundColor(.yellow)
            }

            Text("EyeRest Pro")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(.white)

            Text("paywall.subtitle")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.7))
        }
    }

    // MARK: - Benefits

    private var benefitsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            BenefitRow(icon: "lock.shield.fill", color: .red,
                       title: String(localized: "paywall.benefit.strictMode"),
                       subtitle: String(localized: "paywall.benefit.strictMode.detail"))

            BenefitRow(icon: "calendar.badge.checkmark", color: .blue,
                       title: String(localized: "paywall.benefit.calendarSync"),
                       subtitle: String(localized: "paywall.benefit.calendarSync.detail"))

            BenefitRow(icon: "chart.bar.fill", color: .green,
                       title: String(localized: "paywall.benefit.advancedStats"),
                       subtitle: String(localized: "paywall.benefit.advancedStats.detail"))

            BenefitRow(icon: "speaker.wave.3.fill", color: .purple,
                       title: String(localized: "paywall.benefit.customSounds"),
                       subtitle: String(localized: "paywall.benefit.customSounds.detail"))

            BenefitRow(icon: "paintbrush.fill", color: .orange,
                       title: String(localized: "paywall.benefit.themes"),
                       subtitle: String(localized: "paywall.benefit.themes.detail"))

            BenefitRow(icon: "person.2.fill", color: .cyan,
                       title: String(localized: "paywall.benefit.profiles"),
                       subtitle: String(localized: "paywall.benefit.profiles.detail"))

            BenefitRow(icon: "bell.badge.fill", color: .indigo,
                       title: String(localized: "paywall.benefit.smartReminders"),
                       subtitle: String(localized: "paywall.benefit.smartReminders.detail"))
        }
        .padding(16)
        .background(Color.white.opacity(0.06))
        .cornerRadius(16)
    }

    // MARK: - Produkte

    private var productsSection: some View {
        VStack(spacing: 10) {
            if subscriptionManager.isLoading && subscriptionManager.products.isEmpty {
                ProgressView()
                    .tint(.white)
                    .padding(.vertical, 20)
            } else if subscriptionManager.products.isEmpty {
                Text("paywall.productsUnavailable")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.5))
                    .padding(.vertical, 20)
            } else {
                ForEach(subscriptionManager.products, id: \.id) { product in
                    ProductCard(
                        product: product,
                        isLoading: subscriptionManager.isLoading
                    ) {
                        Task {
                            await subscriptionManager.purchase(product)
                            if subscriptionManager.isPro {
                                dismiss()
                            }
                        }
                    }
                }
            }

            if let error = subscriptionManager.purchaseError {
                Text(error)
                    .font(.caption)
                    .foregroundColor(.red)
                    .padding(.top, 4)
            }
        }
    }

    // MARK: - Restore

    private var restoreButton: some View {
        Button {
            Task {
                await subscriptionManager.restorePurchases()
                if subscriptionManager.isPro {
                    dismiss()
                }
            }
        } label: {
            Text("paywall.restore")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.5))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Legal

    private var legalText: some View {
        Text("paywall.legal")
            .font(.caption2)
            .foregroundColor(.white.opacity(0.3))
            .multilineTextAlignment(.center)
    }
}

// MARK: - Benefit Row

struct BenefitRow: View {
    let icon: String
    let color: Color
    let title: String
    let subtitle: String

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(color)
                .frame(width: 32, height: 32)
                .background(color.opacity(0.15))
                .cornerRadius(8)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.bold())
                    .foregroundColor(.white)

                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.6))
            }
        }
    }
}

// MARK: - Product Card

struct ProductCard: View {
    let product: Product
    let isLoading: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                // Info
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(product.subscriptionLabel)
                            .font(.headline)
                            .foregroundColor(.white)

                        if product.isRecommended {
                            Text("paywall.popular")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundColor(.black)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.yellow)
                                .cornerRadius(4)
                        }
                    }

                    Text(product.subscriptionDescription)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.6))
                }

                Spacer()

                // Preis
                if isLoading {
                    ProgressView()
                        .tint(.white)
                        .scaleEffect(0.8)
                } else {
                    VStack(alignment: .trailing, spacing: 1) {
                        Text(product.displayPrice)
                            .font(.system(.headline, design: .rounded))
                            .foregroundColor(.white)

                        if let daily = product.dailyPriceText {
                            Text(daily)
                                .font(.caption2)
                                .foregroundColor(.white.opacity(0.5))
                        }
                    }
                }
            }
            .padding(16)
            .background(
                product.isRecommended
                    ? Color.yellow.opacity(0.12)
                    : Color.white.opacity(0.06)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(
                        product.isRecommended
                            ? Color.yellow.opacity(0.4)
                            : Color.white.opacity(0.1),
                        lineWidth: product.isRecommended ? 2 : 1
                    )
            )
            .cornerRadius(14)
        }
        .buttonStyle(.plain)
        .disabled(isLoading)
    }
}

// MARK: - Preview

#Preview {
    PaywallView()
}
