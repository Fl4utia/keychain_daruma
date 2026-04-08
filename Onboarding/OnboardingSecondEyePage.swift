//
//  OnboardingSecondEyePage.swift
//

import SwiftUI

struct OnboardingSecondEyePage: View {
    @Environment(SettingsManager.self) private var settings

    @State private var confettiPieces: [ConfettiPiece] = []
    @State private var darumaScale: CGFloat = 0.6
    @State private var darumaOpacity: Double = 0
    @State private var glowOpacity: Double = 0

    var body: some View {
        ZStack {
            // Confetti layer
            ForEach(confettiPieces) { piece in
                RoundedRectangle(cornerRadius: 2)
                    .fill(piece.color)
                    .frame(width: piece.width, height: piece.height)
                    .rotationEffect(.degrees(piece.rotation))
                    .offset(x: piece.x, y: piece.y)
                    .opacity(piece.opacity)
            }

            VStack(spacing: 0) {

                // ── Title (Top) ─────────────────────────
                VStack(spacing: 10) {
                    Text("Paint the Second Eye")
                        .font(settings.currentFont.largeTitleFont)
                        .bold()
                        .multilineTextAlignment(.center)

                    Text("When you reach your goal, return to your Daruma and paint the second eye.")
                        .font(settings.currentFont.title3Font)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.horizontal, 8)
                }
                .padding(.top, 60)
                .padding(.horizontal, 32)

                Spacer() // pushes Daruma down to center

                // ── Centered Daruma ─────────────────────
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [Color.yellow.opacity(0.5), .clear],
                                center: .center,
                                startRadius: 60,
                                endRadius: 140
                            )
                        )
                        .frame(width: 300, height: 300)
                        .opacity(glowOpacity)

                    Image("daruma_two_eyes")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 280, height: 280)
                        .scaleEffect(darumaScale)
                        .opacity(darumaOpacity)
                }

                Spacer() // keeps Daruma perfectly centered
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .onAppear { triggerEntrance() }
    }

    private func triggerEntrance() {
        withAnimation(.spring(response: 0.55, dampingFraction: 0.65).delay(0.2)) {
            darumaScale = 1.0; darumaOpacity = 1.0
        }
        withAnimation(.easeIn(duration: 0.6).delay(0.5)) { glowOpacity = 1.0 }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { spawnConfetti() }
    }

    private func spawnConfetti() {
        let colors: [Color] = [.red, .orange, .yellow, .green, .blue, .purple, .pink]
        confettiPieces = (0..<40).map { _ in
            ConfettiPiece(
                id: UUID(),
                x: CGFloat.random(in: -180...180),
                y: CGFloat.random(in: -300...100),
                width: CGFloat.random(in: 6...14),
                height: CGFloat.random(in: 10...20),
                rotation: Double.random(in: 0...360),
                color: colors.randomElement()!,
                opacity: Double.random(in: 0.6...1.0)
            )
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation(.easeOut(duration: 1.0)) {
                confettiPieces = confettiPieces.map { var p = $0; p.opacity = 0; return p }
            }
        }
    }
}

private struct ConfettiPiece: Identifiable {
    let id: UUID
    var x: CGFloat; var y: CGFloat
    var width: CGFloat; var height: CGFloat
    var rotation: Double; var color: Color; var opacity: Double
}

#Preview {
    OnboardingSecondEyePage().environment(SettingsManager())
}
