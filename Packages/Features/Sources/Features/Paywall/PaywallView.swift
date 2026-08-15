import DesignSystem
import Purchases
import SwiftUI

/// Subscription screen with the monthly and yearly plans.
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

    @State private var selectedPlanID: String?

    private var store: SubscriptionStore {
        model.subscription
    }

    var body: some View {
        VStack(alignment: .leading, spacing: SpacingToken.lg) {
            header
            benefits
            Spacer(minLength: SpacingToken.md)
            plans
            actions
        }
        .padding(SpacingToken.lg)
        .background(ColorToken.background)
        .task {
            model.analytics.track(.paywallSeen)
            await store.loadPlans()
            selectedPlanID = store.plans.first { $0.period == .yearly }?.id ?? store.plans.first?.id
        }
        .alert(
            "paywall.error.title",
            isPresented: Binding(get: { store.lastError != nil }, set: {
                if !$0 {
                    store.clearError()
                }
            })
        ) {
            Button("common.close") { store.clearError() }
        } message: {
            Text("paywall.error.body")
        }
    }

    // MARK: Sections

    private var header: some View {
        HStack {
            ScreenTitle("paywall.title")
            Spacer()
            Button("common.close") { close() }
                .frame(minHeight: SpacingToken.minTouchTarget)
        }
    }

    private var benefits: some View {
        VStack(alignment: .leading, spacing: SpacingToken.md) {
            benefit("paywall.benefit.levels")
            benefit("paywall.benefit.progress")
            benefit("paywall.benefit.dim")
            benefit("paywall.benefit.private")
        }
    }

    @ViewBuilder
    private var plans: some View {
        if store.plans.isEmpty {
            // Offerings not loaded — no network, or products not configured
            // yet. Showing a dead "Subscribe" button would be worse.
            Text("paywall.unavailable")
                .font(TypographyToken.body)
                .foregroundStyle(ColorToken.secondaryText)
                .frame(maxWidth: .infinity, alignment: .leading)
        } else {
            VStack(spacing: SpacingToken.sm) {
                ForEach(store.plans) { plan in
                    planRow(plan)
                }
            }
        }
    }

    private func planRow(_ plan: SubscriptionPlan) -> some View {
        let isSelected = plan.id == selectedPlanID
        return Button {
            selectedPlanID = plan.id
        } label: {
            HStack(spacing: SpacingToken.md) {
                VStack(alignment: .leading, spacing: SpacingToken.xs) {
                    Text(plan.period == .yearly ? "paywall.plan.yearly" : "paywall.plan.monthly")
                        .font(TypographyToken.bodyEmphasized)
                        .foregroundStyle(ColorToken.primaryText)
                    if let monthly = plan.localizedMonthlyEquivalent {
                        Text("paywall.plan.perMonth \(monthly)")
                            .font(TypographyToken.caption)
                            .foregroundStyle(ColorToken.secondaryText)
                    }
                }
                Spacer(minLength: SpacingToken.sm)
                Text(verbatim: plan.localizedPrice)
                    .font(TypographyToken.bodyEmphasized)
                    .foregroundStyle(ColorToken.primaryText)
                Image(systemName: isSelected ? "largecircle.fill.circle" : "circle")
                    .foregroundStyle(isSelected ? ColorToken.accent : ColorToken.border)
            }
            .padding(SpacingToken.md)
            .frame(minHeight: SpacingToken.minTouchTarget)
            .background(isSelected ? ColorToken.accentSoft : ColorToken.surface)
            .overlay {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(isSelected ? ColorToken.accent : ColorToken.cardBorder, lineWidth: isSelected ? 2 : 1)
            }
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .cardElevation()
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(isSelected ? [.isSelected, .isButton] : .isButton)
    }

    private var actions: some View {
        VStack(spacing: SpacingToken.sm) {
            PrimaryButton("paywall.subscribe") { purchase() }
                .disabled(store.isWorking || selectedPlan == nil)

            Button("paywall.restore") {
                Task { await store.restore() }
            }
            .font(TypographyToken.body)
            .frame(maxWidth: .infinity, minHeight: SpacingToken.minTouchTarget)
            .disabled(store.isWorking)

            Text("paywall.terms")
                .font(TypographyToken.caption)
                .foregroundStyle(ColorToken.secondaryText)
                .multilineTextAlignment(.center)
        }
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

    // MARK: Behaviour

    private var selectedPlan: SubscriptionPlan? {
        store.plans.first { $0.id == selectedPlanID }
    }

    private func purchase() {
        guard let plan = selectedPlan else { return }
        Task {
            await store.purchase(plan)
            if store.isSubscribed {
                model.analytics.track(.paywallConverted)
                close()
            }
        }
    }

    private func close() {
        dismiss()
        onFinished()
    }
}
