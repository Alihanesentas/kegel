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
    @State private var showPaywall = false
    @State private var didCopyID = false

    public init() {}

    public var body: some View {
        NavigationStack {
            Form {
                subscriptionSection
                reminderSection
                aboutSection
                supportSection
            }
            .navigationTitle("settings.title")
            .sheet(isPresented: $showHealthNotice) {
                NavigationStack {
                    HealthNoticeView()
                        .padding(SpacingToken.lg)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                        .background(ColorToken.background)
                        .toolbar {
                            ToolbarItem(placement: .topBarTrailing) {
                                Button("common.close") { showHealthNotice = false }
                            }
                        }
                }
            }
            .sheet(isPresented: $showPaywall) {
                PaywallView {}
            }
        }
    }

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
            LabeledContent("settings.reminder.time") {
                Text(verbatim: reminderText)
            }
            .frame(minHeight: SpacingToken.minTouchTarget)
        }
    }

    private var aboutSection: some View {
        Section("settings.about") {
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

    private var reminderText: String {
        guard let time = model.preferences.preferences.reminderTime,
              let hour = time.hour else {
            return String(localized: "settings.reminder.off", bundle: .module)
        }
        return String(format: "%02d:%02d", hour, time.minute ?? 0)
    }
}
