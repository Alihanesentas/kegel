import DesignSystem
import SwiftUI

/// Four screens, then straight into training.
///
/// CLAUDE.md section 5 keeps onboarding short and non-branching: health notice
/// → muscle guide → how it works → reminder time. No questionnaire, no
/// screening, nothing that could read as assessing the user.
public struct OnboardingView: View {
    @Environment(AppModel.self) private var model

    @State private var step = Step.disclaimer
    @State private var reminderTime = Calendar.current.date(
        bySettingHour: 9, minute: 0, second: 0, of: Date()
    ) ?? Date()
    @State private var wantsReminder = true

    private enum Step: Int, CaseIterable {
        case disclaimer, muscleGuide, goal, reminder
    }

    public init() {}

    public var body: some View {
        ScrollView {
            VStack(spacing: SpacingToken.lg) {
                switch step {
                case .disclaimer: HealthNoticeView(onContinue: advance)
                case .muscleGuide: MuscleGuideView(guide: model.content.muscleGuide, onContinue: advance)
                case .goal: goalStep
                case .reminder: reminderStep
                }
            }
            .padding(SpacingToken.lg)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(ColorToken.background)
    }

    // MARK: Steps

    private var goalStep: some View {
        VStack(alignment: .leading, spacing: SpacingToken.lg) {
            ScreenTitle("onboarding.goal.title")
            Text("onboarding.goal.body \(model.content.weeklySessionGoal)")
                .font(TypographyToken.body)
                .foregroundStyle(ColorToken.secondaryText)
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

            PrimaryButton("onboarding.finish") { finish() }
        }
    }

    // MARK: Behaviour

    private func advance() {
        guard let next = Step(rawValue: step.rawValue + 1) else { return }
        withAnimation { step = next }
    }

    private func finish() {
        let components = Calendar.current.dateComponents([.hour, .minute], from: reminderTime)
        Task {
            await model.setReminder(
                hour: wantsReminder ? components.hour : nil,
                minute: wantsReminder ? components.minute : nil
            )
            await model.preferences.update { $0.hasCompletedOnboarding = true }
            model.analytics.track(.onboardingCompleted)
        }
    }
}
