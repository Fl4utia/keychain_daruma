//
//  SwiftUIView.swift
//  QUI
//
//  Created by Salvatore De Rosa on 23/02/26.
//

import SwiftUI
import UIKit

struct OnboardingView: View {
    @Binding var isPresented: Bool
    @State private var currentPage = 0
    @State private var didTapNext = false

    private struct OnboardingPage: Identifiable {
        let id = UUID()
        let icon: String
        let color: Color
        let title: String
        let description: String
    }

    private let pages: [OnboardingPage] = [
        OnboardingPage(
            icon: "document",
            color: .green,
            title: "First page",
            description: "First page"
        ),
        OnboardingPage(
            icon: "document",
            color: .orange,
            title: "Second page",
            description: "Second page"
        ),
        OnboardingPage(
            icon: "document",
            color: .red,
            title: "Third page",
            description: "Third page"
        ),
        OnboardingPage(
            icon: "document",
            color: .accentColor,
            title: "Fourth page",
            description: "Fourth page"
        )
    ]

    private var lastIndex: Int {
        max(pages.count - 1, 0)
    }

    var body: some View {

        NavigationStack {
            VStack {
                TabView(selection: $currentPage) {
                    ForEach(Array(pages.enumerated()), id: \.offset) { index, page in
                        OnboardingPageView(
                            icon: page.icon,
                            color: page.color,
                            title: page.title,
                            description: page.description
                        )
                        .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .always))
                .indexViewStyle(.page(backgroundDisplayMode: .always))
                .sensoryFeedback(.selection, trigger: currentPage)
                .onChange(of: currentPage) { _, newValue in
                    let pageNumber = newValue + 1
                    let totalPages = max(pages.count, 1)
                    UIAccessibility.post(
                        notification: .announcement,
                        argument: "Page \(pageNumber) of \(totalPages)"
                    )
                }

                Button {
                    didTapNext.toggle()
                    if currentPage < lastIndex {
                        withAnimation {
                            currentPage += 1
                        }
                    } else {
                        isPresented = false
                    }
                } label: {
                    Text(currentPage < lastIndex ? "Next" : "Get Started")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.extraLarge)
                .tint(.accentColor)
                .accessibilityHint(
                    currentPage < lastIndex
                        ? "Goes to the next page."
                        : "Closes the welcome screen and starts the app."
                )
                .padding()
                .sensoryFeedback(
                    .impact(flexibility: .soft),
                    trigger: didTapNext
                )

            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    if currentPage < lastIndex {
                        Button("Skip") {
                            isPresented = false
                        }
                        .foregroundStyle(.secondary)
                        .accessibilityHint(
                            "Skips the tutorial and starts the app."
                        )
                    }
                }
            }
        }
    }
}

#Preview {
    OnboardingView(isPresented: .constant(true))
}
