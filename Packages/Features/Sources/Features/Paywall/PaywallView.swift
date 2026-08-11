import DesignSystem
import SwiftUI

/// Subscription screen.
///
/// The copy sells training features — more levels, progress history, dim mode.
/// It must never promise a clinical outcome (CLAUDE.md section 1): no
/// "treats", no condition names. That constraint is why the strings here are
/// deliberately plain.
struct PaywallView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss

    /// Called after the sheet closes, so the caller can continue its own flow.
    let onFinished: () -> Void

    /// Placeholder identifier. Real product IDs come from App Store Connect
    /// once RevenueCat is wired up (M3) — nothing here can complete a purchase yet.
    private let productID = "pelvic.pro.yearly"

    var body: some View {
        VStack(alignment: .leading, spacing: SpacingToken.lg) {
            HStack {
                Spacer()
                Button("common.close") { close() }
                    .frame(minHeight: SpacingToken.minTouchTarget)
            }

            ScreenTitle("paywall.title")

            VStack(alignment: .leading, spacing: SpacingToken.md) {
                benefit("paywall.benefit.levels")
                benefit("paywall.benefit.progress")
                benefit("paywall.benefit.dim")
                benefit("paywall.benefit.private")
            }

            Spacer()

            PrimaryButton("paywall.subscribe") {
                Task {
                    await model.subscription.purchase(productID: productID)
                    if model.subscription.isSubscribed {
                        model.analytics.track(.paywallConverted)
                    }
                    close()
                }
            }
            .disabled(model.subscription.isWorking)

            Button("paywall.restore") {
                Task { await model.subscription.restore() }
            }
            .font(TypographyToken.body)
            .frame(maxWidth: .infinity, minHeight: SpacingToken.minTouchTarget)
            .disabled(model.subscription.isWorking)
        }
        .padding(SpacingToken.lg)
        .background(ColorToken.background)
        .onAppear { model.analytics.track(.paywallSeen) }
    }

    private func benefit(_ key: LocalizedStringKey) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: SpacingToken.sm) {
            Image(systemName: "checkmark")
                .foregroundStyle(ColorToken.accent)
            Text(key)
                .font(TypographyToken.body)
                .foregroundStyle(ColorToken.primaryText)
        }
        .accessibilityElement(children: .combine)
    }

    private func close() {
        dismiss()
        onFinished()
    }
}
