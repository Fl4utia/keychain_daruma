//
//  OnboardingKeepVisiblePage.swift
//  ximena
//
//  Created by Salvatore De Rosa on 01/04/26.
//

import SwiftUI
import UserNotifications

/// Page 4 – "Keep it Where You Can See It"
/// Lets the user add a Home Screen widget and enable daily reminders.
struct OnboardingKeepVisiblePage: View {
    @Environment(SettingsManager.self) private var settings

    @Binding var reminderEnabled: Bool
    @Binding var reminderTime: Date

    @State private var notificationStatus: UNAuthorizationStatus = .notDetermined
    @State private var showTimePickerSheet = false
    @State private var widgetHighlighted = false

    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(spacing: 32) {

                    VStack(spacing: 10) {
                        Text("Keep it Visible")
                            .font(settings.currentFont.largeTitleFont)
                            .bold()
                            .multilineTextAlignment(.center)
                            .accessibilityAddTraits(.isHeader)

                        Text("A Daruma works best when it's always in sight. Add a widget to your Home Screen.")
                            .font(settings.currentFont.title3Font)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 8)
                    }
                    .padding(.top, 62)
                    .accessibilityElement(children: .combine)

                    // ── Cards ─────────────────────────────────────────
                    VStack(spacing: 16) {

                        // Widget card
                        FeatureCard(
                            icon: "rectangle.stack",
                            iconColor: .purple,
                            title: "Add a Widget",
                            subtitle: "Keep your Daruma on your Home Screen for a constant reminder.",
                            actionLabel: "How to Add",
                            accessibilityHint: "Shows instructions for adding the Daruma widget to your Home Screen"
                        ) {
                            widgetHighlighted.toggle()
                            showWidgetInstructions()
                        }
                        .overlay(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .stroke(Color.purple.opacity(widgetHighlighted ? 0.8 : 0), lineWidth: 2)
                        )
                        .animation(.easeInOut(duration: 0.3), value: widgetHighlighted)

                        // Reminder card
                        VStack(spacing: 0) {
                            FeatureCard(
                                icon: "bell.badge",
                                iconColor: .orange,
                                title: "Daily Reminder",
                                subtitle: "A gentle nudge each day to check on your Daruma and progress.",
                                actionLabel: reminderEnabled ? "On" : "Enable",
                                actionIsEnabled: !reminderEnabled,
                                accessibilityHint: "Enables daily reminder notifications for your Daruma goal"
                            ) {
                                requestNotificationPermission()
                            }

                            if reminderEnabled {
                                Divider().padding(.horizontal, 14)

                                Button {
                                    showTimePickerSheet = true
                                } label: {
                                    HStack {
                                        Text("Reminder time")
                                            .font(settings.currentFont.bodyFont)
                                            .foregroundStyle(.primary)
                                        Spacer()
                                        Text(reminderTime, style: .time)
                                            .font(settings.currentFont.bodyFont)
                                            .foregroundStyle(.secondary)
                                        Image(systemName: "chevron.right")
                                            .foregroundStyle(.tertiary)
                                            .font(.footnote)
                                    }
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 12)
                                }
                                .accessibilityLabel("Reminder time, currently \(reminderTime.formatted(date: .omitted, time: .shortened))")
                                .accessibilityHint("Opens a time picker to change when you receive the daily reminder")
                                .transition(.opacity.combined(with: .move(edge: .top)))
                            }
                        }
                        .background(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(.regularMaterial)
                                .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: reminderEnabled)
                    }

                    Spacer(minLength: 32)
                }
                .frame(maxWidth: .infinity, minHeight: geometry.size.height)
                .padding(.horizontal, 24)
            }
        }
        .sheet(isPresented: $showTimePickerSheet) {
            ReminderTimePickerSheet(reminderTime: $reminderTime)
                .presentationDetents([.medium])
                .environment(settings)
        }
        .task { await checkNotificationStatus() }
    }

    // MARK: – Notifications

    private func checkNotificationStatus() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        await MainActor.run {
            notificationStatus = settings.authorizationStatus
            reminderEnabled = notificationStatus == .authorized
        }
    }

    private func requestNotificationPermission() {
        Task {
            do {
                let granted = try await UNUserNotificationCenter.current()
                    .requestAuthorization(options: [.alert, .sound, .badge])
                await MainActor.run {
                    withAnimation { reminderEnabled = granted }
                    if granted { scheduleReminder() }
                }
            } catch {
                print("Notification permission error: \(error)")
            }
        }
    }

    private func scheduleReminder() {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: ["daruma.daily"])

        let content = UNMutableNotificationContent()
        content.title = "Check your Daruma 👁"
        content.body = "How's your goal coming along? Your Daruma is watching."
        content.sound = .default

        var dateComponents = Calendar.current.dateComponents([.hour, .minute], from: reminderTime)
        dateComponents.second = 0
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: "daruma.daily", content: content, trigger: trigger)
        center.add(request)
    }

    private func showWidgetInstructions() {
        // In a real app you might show a sheet or call WidgetCenter.shared.reloadAllTimelines()
        let alert = UIAlertController(
            title: "Add the Widget",
            message: "Long-press your Home Screen → tap '+' → search 'Daruma' → choose a size and tap Add Widget.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Got it", style: .default))
        UIApplication.shared
            .connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first?.windows.first?.rootViewController?
            .present(alert, animated: true)
    }
}

// MARK: – Feature Card

private struct FeatureCard: View {
    @Environment(SettingsManager.self) private var settings

    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String
    let actionLabel: String
    var actionIsEnabled: Bool = true
    let accessibilityHint: String
    let action: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 26))
                .foregroundStyle(iconColor)
                .frame(width: 44, height: 44)
                .background(iconColor.opacity(0.12), in: RoundedRectangle(cornerRadius: 10, style: .continuous))

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(settings.currentFont.headlineFont)
                    .foregroundStyle(.primary)
                Text(subtitle)
                    .font(settings.currentFont.footnoteFont)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button(action: action) {
                Text(actionLabel)
                    .font(settings.currentFont.footnoteFont.bold())
                    .foregroundStyle(actionIsEnabled ? iconColor : .secondary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        Capsule().fill(actionIsEnabled ? iconColor.opacity(0.12) : Color.secondary.opacity(0.1))
                    )
            }
            .disabled(!actionIsEnabled)
            .accessibilityLabel(title)
            .accessibilityHint(accessibilityHint)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.regularMaterial)
                .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
        )
    }
}

// MARK: – Reminder Time Picker Sheet

private struct ReminderTimePickerSheet: View {
    @Environment(SettingsManager.self) private var settings
    @Binding var reminderTime: Date
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 20) {
            Text("Reminder Time")
                .font(settings.currentFont.largeTitleFont)
                .bold()
                .padding(.top, 24)

            DatePicker(
                "Select time",
                selection: $reminderTime,
                displayedComponents: .hourAndMinute
            )
            .datePickerStyle(.wheel)
            .labelsHidden()

            Button("Save") { dismiss() }
                .buttonStyle(.glassProminent)
                .controlSize(.extraLarge)
                .tint(.accentColor)
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
        }
    }
}

// MARK: – Preview

#Preview {
    @Previewable @State var reminder = false
    @Previewable @State var time = Date()
    OnboardingKeepVisiblePage(reminderEnabled: $reminder, reminderTime: $time)
        .environment(SettingsManager())
}
