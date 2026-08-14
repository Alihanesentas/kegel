import Core
import DesignSystem
import SwiftUI
import UIKit

/// Settings.
///
/// There is no account to manage (CLAUDE.md section 5) — the anonymous ID is
/// shown here so support can identify an install, and it's copyable because
/// reading a UUID aloud is nobody's idea of a good time.
public struct SettingsView: View {
    @Environment(AppModel.self) private var model

    @State private var showHealthNotice = false
    @State private var showMuscleGuide = false
    @State private var showPaywall = false
    @State private var didCopyID = false

    @State private var remindersOn = false
    @State private var reminderTime = Date()
    /// Guards against the initial sync writing preferences straight back.
    @State private var hasLoadedReminder = false

    @State private var vibrationOn = true

    public init() {}

    public var body: some View {
        NavigationStack {
            Form {
                subscriptionSection
                reminderSection
                feedbackSection
                aboutSection
                supportSection
            }
            .navigationTitle("settings.title")
            .task {
                syncReminderFromPreferences()
                vibrationOn = model.preferences.preferences.isVibrationEnabled
            }
            .onChange(of: remindersOn) { _, _ in persistReminder() }
            .onChange(of: reminderTime) { _, _ in persistReminder() }
            .onChange(of: vibrationOn) { _, newValue in
                Task { await model.setVibrationEnabled(newValue) }
            }
            .sheet(isPresented: $showHealthNotice) {
                sheet { HealthNoticeView() }
            }
            .sheet(isPresented: $showMuscleGuide) {
                sheet { MuscleGuideView(guide: model.content.muscleGuide) }
            }
            .sheet(isPresented: $showPaywall) {
                PaywallView {}
            }
        }
    }

    // MARK: Sections

    private var subscriptionSection: some View {
        Section("settings.subscription") {
            LabeledContent("settings.status") {
                Text(model.subscription.isSubscribed ? "settings.status.active" : "settings.status.free")
            }
            .frame(minHeight: SpacingToken.minTouchTarget)

            if !model.subscription.isSubscribed {
                Button("settings.subscribe") { showPaywall = true }
                    .frame(minHeight: SpacingToken.minTouchTarget)
            }

            Button("settings.restore") {
                Task { await model.subscription.restore() }
            }
            .disabled(model.subscription.isWorking)
            .frame(minHeight: SpacingToken.minTouchTarget)
        }
    }

    private var reminderSection: some View {
        Section("settings.reminders") {
            Toggle("settings.reminder.enabled", isOn: $remindersOn)
                .frame(minHeight: SpacingToken.minTouchTarget)

            if remindersOn {
                DatePicker(
                    "settings.reminder.time",
                    selection: $reminderTime,
                    displayedComponents: .hourAndMinute
                )
                .frame(minHeight: SpacingToken.minTouchTarget)
            }
        }
    }

    private var feedbackSection: some View {
        Section {
            Toggle("settings.vibration", isOn: $vibrationOn)
                .frame(minHeight: SpacingToken.minTouchTarget)
        } footer: {
            Text("settings.vibration.footer")
        }
    }

    private var aboutSection: some View {
        Section("settings.about") {
            Button("settings.muscleGuide") { showMuscleGuide = true }
                .frame(minHeight: SpacingToken.minTouchTarget)
            Button("settings.healthNotice") { showHealthNotice = true }
                .frame(minHeight: SpacingToken.minTouchTarget)
        }
    }

    private var supportSection: some View {
        Section {
            Button {
                UIPasteboard.general.string = model.preferences.preferences.anonymousID
                didCopyID = true
            } label: {
                VStack(alignment: .leading, spacing: SpacingToken.xs) {
                    Text(didCopyID ? "settings.id.copied" : "settings.id.copy")
                    Text(verbatim: model.preferences.preferences.anonymousID)
                        .font(TypographyToken.caption)
                        .foregroundStyle(ColorToken.secondaryText)
                        .textSelection(.enabled)
                }
            }
            .frame(minHeight: SpacingToken.minTouchTarget)
        } header: {
            Text("settings.support")
        } footer: {
            Text("settings.support.footer")
        }
    }

    // MARK: Reminder plumbing

    private func syncReminderFromPreferences() {
        let saved = model.preferences.preferences
        remindersOn = saved.reminderTime != nil
        if let hour = saved.reminderHour {
            reminderTime = Calendar.current.date(
                bySettingHour: hour, minute: saved.reminderMinute ?? 0, second: 0, of: Date()
            ) ?? Date()
        }
        hasLoadedReminder = true
    }

    private func persistReminder() {
        guard hasLoadedReminder else { return }
        let components = Calendar.current.dateComponents([.hour, .minute], from: reminderTime)
        Task {
            await model.setReminder(
                hour: remindersOn ? components.hour : nil,
                minute: remindersOn ? components.minute : nil
            )
        }
    }

    private func sheet(@ViewBuilder content: () -> some View) -> some View {
        NavigationStack {
            ScrollView {
                content()
                    .padding(SpacingToken.lg)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .background(ColorToken.background)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("common.close") {
                        showHealthNotice = false
                        showMuscleGuide = false
                    }
                }
            }
        }
    }
}
