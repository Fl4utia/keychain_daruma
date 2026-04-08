import SwiftUI
import RealityKit

struct OnboardingDarumaWelcomePage: View {
    @Environment(SettingsManager.self) private var settings

    @State private var shadowScale: CGFloat = 1.0
    @State private var yOffset: CGFloat = 0
    @State private var triggerSpin: Bool = false
    @State private var isAnimating: Bool = false

    var body: some View {
        VStack(spacing: 0) {

            // ── Title ────────────────────────────────────
            Text("Never forget your dreams with Daru widgets")
                .font(settings.currentFont.largeTitleFont)
                .bold()
                .foregroundColor(Color(.label))
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 32)
                .padding(.top, 32)

            Spacer() // pushes content down evenly

            // ── Centered Daruma ──────────────────────────
            ZStack {
                Ellipse()
                    .fill(.black.opacity(0.12))
                    .frame(width: 200, height: 24)
                    .scaleEffect(x: shadowScale, y: 1)
                    .blur(radius: 10)
                    .offset(y: 140) // reduced from 185 → aligns better

                DarumaRealityView(triggerSpin: $triggerSpin)
                    .frame(width: 380, height: 380)
                    .offset(y: yOffset)
                    .onTapGesture {
                        guard !isAnimating else { return }
                        jumpAndFlip()
                    }
            }

            Spacer() // balances top spacer → true vertical centering
        }
        .onAppear { startJumpLoop() }
    }

    // MARK: – Animation

    private func startJumpLoop() { jumpAndFlip() }

    private func jumpAndFlip() {
        isAnimating = true

        withAnimation(.easeOut(duration: 0.35)) {
            yOffset = -100
            shadowScale = 0.45
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            triggerSpin.toggle()
        }
        withAnimation(.spring(response: 0.45, dampingFraction: 0.58).delay(0.4)) {
            yOffset = 0
            shadowScale = 1.0
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
            isAnimating = false
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.2) {
            if !isAnimating { jumpAndFlip() }
        }
    }
}

// MARK: – RealityKit View

private struct DarumaRealityView: View {
    @Binding var triggerSpin: Bool
    @State private var darumaEntity: ModelEntity? = nil

    var body: some View {
        RealityView { content in
            guard let url = Bundle.main.url(forResource: "base_basic_shaded", withExtension: "usdz") else {
                print("⚠️ Could not find base_basic_shaded.usdz"); return
            }
            do {
                let entity = try await ModelEntity(contentsOf: url)
                let bounds = entity.visualBounds(relativeTo: nil)
                let maxDim = max(bounds.extents.x, bounds.extents.y, bounds.extents.z)
                let scale: Float = maxDim > 0 ? 1.5 / maxDim : 1
                entity.scale = SIMD3<Float>(repeating: scale)
                entity.position = SIMD3<Float>(
                    -bounds.center.x * scale,
                    -bounds.center.y * scale,
                    -bounds.center.z * scale
                )
                content.add(entity)
                darumaEntity = entity
            } catch { print("⚠️ Failed to load USDZ: \(error)") }
        }
        .onChange(of: triggerSpin) { _, _ in spinEntity() }
        .background(.clear)
    }

    private func spinEntity() {
        guard let entity = darumaEntity else { return }
        var transform = entity.transform
        let spinQuat = simd_quatf(angle: .pi * 2, axis: SIMD3<Float>(0, 1, 0))
        transform.rotation = transform.rotation * spinQuat
        entity.move(to: transform, relativeTo: entity.parent, duration: 0.5, timingFunction: .linear)
    }
}

#Preview {
    OnboardingDarumaWelcomePage()
        .environment(SettingsManager())
}
