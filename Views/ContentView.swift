//
//  ContentView.swift
//  ximena
//
//  Created by Estrella Verdiguel on 31/03/26.
//

import SwiftUI

struct ContentView: View {
    // @State owns the @Observable object; .environment() makes it available to all descendants.
    @State private var settings = SettingsManager()

    @AppStorage("hasCompletedFirstSettings") private var hasCompletedFirstSettings = false
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false

    var body: some View {
        Group {
            if !hasCompletedFirstSettings {
                FirstSettingsView {
                    hasCompletedFirstSettings = true
                }
            } else if !hasSeenOnboarding {
                OnboardingView(isPresented: Binding(
                    get: { !hasSeenOnboarding },
                    set: { if !$0 { hasSeenOnboarding = true } }
                ))
            } else {
                NavigationStack {
                    KeychainView()
                }
            }
        }
        .environment(settings)
        .environment(\.font, settings.currentFont.bodyFont)
    }
}
