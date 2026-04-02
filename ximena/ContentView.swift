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

    var body: some View {
        NavigationStack {
            KeychainView()
        }
        .environment(settings)
        .environment(\.font, settings.currentFont.bodyFont)
    }
}
