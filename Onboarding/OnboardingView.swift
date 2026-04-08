//
//  OnboardingView.swift
//

import SwiftUI

// MARK: – Shared onboarding state

struct OnboardingResult {
    var wishText: String = ""
    var wishDescription: String = ""
    var darumaImage: UIImage? = nil
    var hasFirstEyePainted: Bool = false
    var reminderEnabled: Bool = false
    var reminderTime: Date = {
        var comps = Calendar.current.dateComponents([.year, .month, .day], from: Date())
        comps.hour = 9; comps.minute = 0; comps.second = 0
        return Calendar.current.date(from: comps) ?? Date()
    }()
}

// MARK: – Main OnboardingView

struct OnboardingView: View {
    @Environment(SettingsManager.self) private var settings
    @Environment(\.colorScheme) var colorScheme
    @Binding var isPresented: Bool

    @State private var currentPage = 0
    @State private var didTapNext = false
    @State private var result = OnboardingResult()
    @State private var navigateToKeychain = false

    private let pageCount = 5
    private var lastIndex: Int { pageCount - 1 }

    private var nextButtonLabel: String {
        switch currentPage {
        case 0: return "Get Started"
        case 1: return result.wishText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                    ? "Set My Goal" : "I'm Ready"
        case 2: return result.hasFirstEyePainted ? "Eye Painted ✓" : "I'll Paint It Later"
        case 3: return "Got It"
        case lastIndex: return "Create My Daruma"
        default: return "Next"
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {

                // ── Pages displayed programmatically ─────────────
                ZStack {
                    switch currentPage {
                    case 0: OnboardingDarumaWelcomePage()
                    case 1: OnboardingMakeAWishPage(
                                wishText: $result.wishText,
                                wishDescription: $result.wishDescription,
                                darumaImage: $result.darumaImage)
                    case 2: OnboardingPaintFirstEyePage(hasFirstEyePainted: $result.hasFirstEyePainted)
                    case 3: OnboardingKeepVisiblePage(
                                reminderEnabled: $result.reminderEnabled,
                                reminderTime: $result.reminderTime)
                    case 4: OnboardingSecondEyePage()
                    default: EmptyView()
                    }
                }
                .animation(.easeInOut, value: currentPage)
                .transition(.slide)

                // ── Single CTA button ──────────────────────────────
                Button {
                    didTapNext.toggle()
                    if currentPage < lastIndex {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            currentPage += 1
                        }
                    } else {
                        navigateToKeychain = true
                    }
                } label: {
                    Text(nextButtonLabel)
                        .font(settings.currentFont.headlineFont)
                        .frame(maxWidth: .infinity)
                        .animation(.easeInOut(duration: 0.2), value: nextButtonLabel)
                }
                .buttonStyle(.glassProminent)
                .controlSize(.extraLarge)
                .tint(colorScheme == .dark ? .white : .black)
                .padding(.horizontal, 24)
                .padding(.bottom, 16)
                .sensoryFeedback(.impact(flexibility: .soft), trigger: didTapNext)
                .accessibilityHint(
                    currentPage < lastIndex
                        ? "Goes to the next step."
                        : "Finishes onboarding and creates your first Daruma."
                )

                // ── Hidden NavigationLink to KeychainView ─────────────
                NavigationLink(
                    destination: KeychainView()
                        .environment(settings),
                    isActive: $navigateToKeychain,
                    label: { EmptyView() }
                )
                .hidden()
            }
            .background(Color(.systemBackground).ignoresSafeArea())
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    if currentPage < lastIndex {
                        Button("Skip") { isPresented = false }
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }
}

#Preview {
    OnboardingView(isPresented: .constant(true))
        .environment(SettingsManager())
}
