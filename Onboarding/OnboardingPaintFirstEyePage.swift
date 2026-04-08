//
//  OnboardingPaintFirstEyePage.swift
//

import SwiftUI

struct OnboardingPaintFirstEyePage: View {
    @Environment(SettingsManager.self) private var settings
    @Binding var hasFirstEyePainted: Bool

    @State private var isPainting = false
    @State private var brushScale: CGFloat = 1.0
    @State private var inkParticles: [InkParticle] = []

    var body: some View {
        VStack(spacing: 0) {

            // ── Title ────────────────────────────────────
            VStack(spacing: 20) {
                Text("Paint the First Eye")
                    .font(settings.currentFont.largeTitleFont)
                    .bold()
                    .multilineTextAlignment(.center)
                    .accessibilityAddTraits(.isHeader)

                Text("By coloring in one eye, you commit to your goal. The Daruma watches over you.")
                    .font(settings.currentFont.title3Font)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, 8)
            }
            .padding(.horizontal, 32)
            .padding(.top, 32)

            // ── Middle section: Interactive Daruma ───────
            VStack(spacing: 0) {
                Spacer()
                
                ZStack {
                    ForEach(inkParticles) { particle in
                        Circle()
                            .fill(particle.color)
                            .frame(width: particle.size, height: particle.size)
                            .offset(x: particle.x, y: particle.y)
                            .opacity(particle.opacity)
                    }

                    Image(hasFirstEyePainted ? "daruma_one_eye" : "no_eye")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 300, height: 300)
                        .scaleEffect(brushScale)
                        .animation(.spring(response: 0.3, dampingFraction: 0.5), value: brushScale)

                    if isPainting {
                        Circle()
                            .stroke(Color.red.opacity(0.5), lineWidth: 3)
                            .frame(width: 60, height: 60)
                            .scaleEffect(isPainting ? 3 : 1)
                            .opacity(isPainting ? 0 : 0.8)
                            .animation(.easeOut(duration: 0.5), value: isPainting)
                    }
                }
                .frame(width: 240, height: 240)
                .onTapGesture {
                    guard !hasFirstEyePainted else { return }
                    paintEye()
                }

                // ── Hint / confirmation ──────────────────────
                Group {
                    if hasFirstEyePainted {
                        Label("Your Daruma is watching.", systemImage: "eye.fill")
                            .font(settings.currentFont.bodyFont)
                            .foregroundStyle(.secondary)
                            .transition(.scale.combined(with: .opacity))
                    } else {
                        Label("Tap the Daruma to paint its eye", systemImage: "hand.tap")
                            .font(settings.currentFont.bodyFont)
                            .foregroundStyle(.secondary)
                            .transition(.opacity)
                    }
                }
                .padding(.top, 84)
                .animation(.spring(response: 0.4, dampingFraction: 0.7), value: hasFirstEyePainted)

                Spacer()
            }
        }
    }

    private func paintEye() {
        let gen = UIImpactFeedbackGenerator(style: .medium)
        gen.impactOccurred()

        brushScale = 0.85
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
            brushScale = 1.05
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) { brushScale = 1.0 }
        }
        spawnInkParticles()
        isPainting = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { isPainting = false }
        withAnimation(.easeInOut(duration: 0.35).delay(0.2)) { hasFirstEyePainted = true }
    }

    private func spawnInkParticles() {
        let colors: [Color] = [.red, .red.opacity(0.7), .orange, .pink]
        inkParticles = (0..<14).map { i in
            let angle = Double(i) / 14.0 * .pi * 2
            let radius = Double.random(in: 40...110)
            return InkParticle(
                id: UUID(),
                x: cos(angle) * radius,
                y: sin(angle) * radius,
                size: CGFloat.random(in: 4...14),
                color: colors.randomElement()!,
                opacity: 1.0
            )
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(.easeOut(duration: 0.6)) {
                inkParticles = inkParticles.map { var p = $0; p.opacity = 0; return p }
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { inkParticles = [] }
    }
}

private struct InkParticle: Identifiable {
    let id: UUID
    var x: Double; var y: Double
    var size: CGFloat; var color: Color; var opacity: Double
}

#Preview {
    @Previewable @State var painted = false
    OnboardingPaintFirstEyePage(hasFirstEyePainted: $painted)
        .environment(SettingsManager())
}
