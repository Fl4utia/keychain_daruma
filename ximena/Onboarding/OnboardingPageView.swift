//
//  SwiftUIView.swift
//  QUI
//
//  Created by Salvatore De Rosa on 23/02/26.
//

import SwiftUI

struct OnboardingPageView: View {
    let icon: String
    let color: Color
    let title: String
    let description: String

    var body: some View {

        GeometryReader { geometry in
            ScrollView {

                VStack(spacing: 30) {

                    Spacer()

                    Image(systemName: icon)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 120, height: 120)
                        .foregroundStyle(color)
                        .accessibilityHidden(true)

                    VStack(spacing: 15) {
                        Text(title)
                            .font(.largeTitle.bold())
                            .multilineTextAlignment(.center)
                            .accessibilityAddTraits(.isHeader)

                        Text(description)
                            .font(.title3)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .accessibilityElement(children: .combine)

                    Spacer()
                }
                .frame(maxWidth: .infinity, minHeight: geometry.size.height)
            }
        }
    }
}

#Preview {
    OnboardingPageView(
        icon: "document",
        color: .green,
        title: "Welcome to /appname",
        description:
            "App description"
    )
}
