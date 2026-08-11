import DesignSystem
import SwiftUI

/// Three screens, then straight into training.
///
/// CLAUDE.md section 5 is explicit that onboarding stays short and does not
/// branch: health notice → goal → reminder time. No questionnaire, no
/// screening, nothing that could read as assessing the user.
public struct OnboardingView: View {
    @Environment(AppModel.self) private var model

    @State private var step = Step.disclaimer
    @State private var reminderTime = Calendar.current.date(
        bySettingHour: 9, minute: 0, second: 0, of: Date()
    ) ?? Date()
    @State private var wantsReminder = true

    private enum Step: Int, CaseIterable {
        case disclaimer, goal, reminder
    }

    public init() {}

    public var body: some View {
        VStack(spacing: SpacingToken.lg) {
            switch step {
            case .disclaimer: HealthNoticeView(onContinue: advance)
            case .goal: goalStep
            case .reminder: reminderStep
            }
        }
        .padding(SpacingToken.lg)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(ColorToken.background)
    }

    // MARK: Steps

    private var goalStep: some View {
        VStack(alignment: .leading, spacing: SpacingToken.lg) {
            ScreenTitle("onboarding.goal.title")
            Text("onboarding.goal.body \(model.content.weeklySessionGoal)")
                .font(TypographyToken.body)
                .foregroundStyle(ColorToken.secondaryText)
            Spacer()
            PrimaryButton("common.continue", action: advance)
        }
    }

    private var reminderStep: some View {
        VStack(alignment: .leading, spacing: SpacingToken.lg) {
            ScreenTitle("onboarding.reminder.title")
            Text("onboarding.reminder.body")
                .font(TypographyToken.body)
                .foregroundStyle(ColorToken.secondaryText)

            Toggle("onboarding.reminder.toggle", isOn: $wantsReminder)
                .font(TypographyToken.body)
                .frame(minHeight: SpacingToken.minTouchTarget)

            if wantsReminder {
                DatePicker(
                    "onboarding.reminder.time",
                    selection: $reminderTime,
                    displayedComponents: .hourAndMinute
                )
                .font(TypographyToken.body)
                .frame(minHeight: SpacingToken.minTouchTarget)
            }

            Spacer()
            PrimaryButton("onboarding.finish") { finish() }
        }
    }

    // MARK: Behaviour

    private func advance() {
        guard let next = Step(rawValue: step.rawValue + 1) else { return }
        withAnimation { step = next }
    }

    private func finish() {
        Task {
            let components = Calendar.current.dateComponents([.hour, .minute], from: reminderTime)
            await model.preferences.update {
                $0.hasCompletedOnboarding = true
                $0.setReminder(
                    hour: wantsReminder ? components.hour : nil,
                    minute: wantsReminder ? components.minute : nil
                )
            }
            if wantsReminder {
                await model.scheduleReminder()
            }
            model.analytics.track(.onboardingCompleted)
        }
    }
}
