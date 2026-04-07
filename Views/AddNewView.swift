//
//  AddNewView.swift
//  ximena
//
//  Created by Salvatore De Rosa on 02/04/2026.
//

import RealityKit
import SwiftUI

// MARK: - Main View

struct AddNewView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var dreamName = ""
    @State private var dreamDescription = ""
    @State private var audioManager = AudioRecorderManager()

    // Enum-based focus: one pointer per input field, not a boolean.
    // Allows deterministic tracking, programmatic field-switching, and
    // correct "Next" button behaviour on the keyboard.
    enum InputField { case title, description }
    @FocusState private var focusedField: InputField?

    // Derived boolean used by layers that only care whether *any* field is active.
    private var isInputActive: Bool { focusedField != nil }

    private static let dateFmt: DateFormatter = {
        let f = DateFormatter(); f.dateFormat = "dd/MM/yy"; return f
    }()

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .bottom) {

                // LAYER 1: Background
                Color(.systemBackground)
                    .ignoresSafeArea()
                    .onTapGesture { focusedField = nil }

                // LAYER 2: Ghost title — fades out while typing to reduce visual noise
                let navOffset = geo.safeAreaInsets.top + 44
                let usableH   = geo.size.height - navOffset
                let fontSize  = usableH * 0.22
                let maxLines  = max(1, Int(usableH / (fontSize * 1.2)))

                if !dreamName.isEmpty {
                    Text(dreamName)
                        .font(.system(size: fontSize, weight: .black))
                        .foregroundStyle(.primary)
                        .opacity(isInputActive ? 0 : 0.08)
                        .lineLimit(maxLines)
                        .minimumScaleFactor(0.2)
                        .padding(.top, navOffset)
                        .padding(.horizontal, 24)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                        .allowsHitTesting(false)
                        .accessibilityHidden(true)      // decorative duplicate — must not be read by VoiceOver
                        .animation(.easeOut(duration: 0.25), value: isInputActive)
                }

                // LAYER 3: Daruma — touch-disabled while keyboard is active,
                // preventing accidental 3D pan during text entry
                VStack {
                    DarumaPreviewView(darumaType: .basic)
                        .frame(maxWidth: .infinity)
                        .frame(height: geo.size.height * 0.55)
                        .allowsHitTesting(!isInputActive)
                        .overlay(alignment: .bottom) {
                            LinearGradient(
                                colors: [
                                    .clear,
                                    Color(.systemBackground).opacity(0.6),
                                    Color(.systemBackground)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                            .frame(height: 120)
                            .allowsHitTesting(false)
                        }
                    Spacer()
                }

                // LAYER 4: Focus dimming overlay — spotlights the input card,
                // dims the 3D scene, and provides a tap-to-dismiss surface
                if isInputActive {
                    Color.black.opacity(0.4)
                        .ignoresSafeArea()
                        .onTapGesture { focusedField = nil }
                        .transition(.opacity)
                        .animation(.easeInOut(duration: 0.2), value: isInputActive)
                }

                // LAYER 5: Input zone — sits above the dimming layer
                VStack(spacing: 20) {
                    RecordingControlRow(audioManager: audioManager)
                        .frame(height: 52)

                    BottomEntryCard(
                        dreamName: $dreamName,
                        dreamDescription: $dreamDescription,
                        focusedField: $focusedField,
                        creationDate: Self.dateFmt.string(from: Date())
                    )
                }
                .padding(.horizontal, 20)
                .padding(.bottom, geo.safeAreaInsets.bottom + 16)
                .zIndex(1)
            }
        }
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") { focusedField = nil }
            }

            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    // TODO: saving the daruma
                } label: {
                    Image(systemName: "checkmark")
                }
            }
        }
    }
}

// MARK: - 3D Daruma Preview

struct DarumaPreviewView: UIViewRepresentable {
    let darumaType: DarumaType

    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero, cameraMode: .nonAR, automaticallyConfigureSession: false)
        arView.environment.background = .color(.clear)
        arView.renderOptions = [.disableDepthOfField, .disableMotionBlur]

        let anchor = AnchorEntity(world: .zero)
        Self.addLights(to: anchor)
        arView.scene.anchors.append(anchor)

        if let entity = try? Entity.load(named: darumaType.modelFileName) {
            context.coordinator.attach(entity: entity, to: anchor)
        }

        let pan = UIPanGestureRecognizer(
            target: context.coordinator,
            action: #selector(Coordinator.handlePan(_:))
        )
        arView.addGestureRecognizer(pan)

        return arView
    }

    func updateUIView(_ uiView: ARView, context: Context) {}

    // MARK: Lighting (mirrors KeychainViewModel)

    private static func addLights(to anchor: AnchorEntity) {
        var main = DirectionalLightComponent()
        main.intensity = 1_200
        let mainEntity = Entity()
        mainEntity.components.set(main)
        mainEntity.look(at: .zero, from: SIMD3<Float>(0.5, 1.5, 1.0), relativeTo: nil)

        var fill = DirectionalLightComponent()
        fill.intensity = 400
        let fillEntity = Entity()
        fillEntity.components.set(fill)
        fillEntity.look(at: .zero, from: SIMD3<Float>(-0.5, -1.0, 0.5), relativeTo: nil)

        anchor.addChild(mainEntity)
        anchor.addChild(fillEntity)
    }

    // MARK: Coordinator — centering + Y-axis rotation

    final class Coordinator: NSObject {
        private var pivot: Entity?
        private var accumulatedAngleY: Float = 0

        func attach(entity: Entity, to anchor: AnchorEntity) {
            entity.scale = SIMD3<Float>(repeating: 1.0)
            let bounds = entity.visualBounds(relativeTo: nil)
            entity.position = -bounds.center

            let pivot = Entity()
            pivot.position = SIMD3<Float>(0, 0, -0.5)
            pivot.addChild(entity)
            anchor.addChild(pivot)
            self.pivot = pivot
        }

        @objc func handlePan(_ gesture: UIPanGestureRecognizer) {
            guard let pivot else { return }
            let delta = gesture.translation(in: gesture.view)
            accumulatedAngleY += Float(delta.x) * 0.008
            pivot.orientation = simd_quatf(angle: accumulatedAngleY, axis: SIMD3<Float>(0, 1, 0))
            gesture.setTranslation(.zero, in: gesture.view)
        }
    }
}

// MARK: - Recording Control Row

struct RecordingControlRow: View {
    let audioManager: AudioRecorderManager

    /// Single source of truth for the button icon — derived from observable state.
    private var iconName: String {
        if audioManager.isRecording  { return "stop.circle.fill" }
        if audioManager.isPlaying    { return "pause.circle.fill" }
        if audioManager.hasRecording { return "play.circle.fill" }
        return "record.circle"
    }

    var body: some View {
        HStack(spacing: 12) {
            // Waveform slides in when there is audio to show; hidden otherwise.
            if audioManager.isRecording || audioManager.hasRecording {
                WaveformView(levels: audioManager.audioLevels)
                    .transition(.opacity.combined(with: .move(edge: .leading)))
            }

            Spacer()

            // One button — icon morphs natively between all four states.
            Button {
                if audioManager.isRecording {
                    audioManager.stopRecording()
                } else if audioManager.isPlaying {
                    audioManager.stopPlayback()
                } else if audioManager.hasRecording {
                    audioManager.playRecording()
                } else {
                    Task { await audioManager.startRecording() }
                }
            } label: {
                Image(systemName: iconName)
                    .font(.system(size: 32))
                    .contentTransition(.symbolEffect(.replace))
            }
            .buttonStyle(.plain)
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: audioManager.isRecording)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: audioManager.hasRecording)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: audioManager.isPlaying)
    }
}

// MARK: - Waveform View

struct WaveformView: View {
    let levels: [Float]

    private let barCount = 44
    private let barWidth: CGFloat = 2.5
    private let barSpacing: CGFloat = 2

    var body: some View {
        GeometryReader { geo in
            HStack(alignment: .center, spacing: barSpacing) {
                ForEach(0..<barCount, id: \.self) { i in
                    let level = levelAt(i)
                    RoundedRectangle(cornerRadius: 1.5)
                        .fill(barColor(at: i))
                        .frame(width: barWidth, height: max(3, CGFloat(level) * geo.size.height * 0.9))
                        .animation(.easeOut(duration: 0.1), value: level)
                }
            }
            .frame(maxHeight: .infinity, alignment: .center)
        }
    }

    private func levelAt(_ index: Int) -> Float {
        guard !levels.isEmpty else { return 0.04 }
        let mapped = Int(Double(index) / Double(barCount) * Double(levels.count))
        return levels[min(mapped, levels.count - 1)]
    }

    private func barColor(at index: Int) -> Color {
        guard !levels.isEmpty else { return Color.secondary.opacity(0.3) }
        let filled = Int(Double(levels.count) / 80.0 * Double(barCount))
        return index < filled ? Color.orange : Color.secondary.opacity(0.25)
    }
}

// MARK: - Bottom Entry Card

struct BottomEntryCard: View {
    @Binding var dreamName: String
    @Binding var dreamDescription: String
    var focusedField: FocusState<AddNewView.InputField?>.Binding
    let creationDate: String

    private var isActive: Bool { focusedField.wrappedValue != nil }

    var body: some View {
        VStack(spacing: 0) {

            // Title — single line, bound specifically to .title
            HStack {
                TextField("Title", text: $dreamName)
                    .font(.headline)
                    .focused(focusedField, equals: .title)
                if !dreamName.isEmpty {
                    Button { dreamName = "" } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)

            Divider().padding(.horizontal, 16)

            // Description — grows organically with content (1–6 lines).
            // Content drives size, not focus state, so no abrupt jump on tap.
            TextField("Add a description...", text: $dreamDescription, axis: .vertical)
                .lineLimit(1...6)
                .focused(focusedField, equals: .description)
                .padding(.horizontal, 16)
                .padding(.vertical, 14)

            // Date row hides while any field is active to reclaim vertical space
            if !isActive {
                Divider().padding(.horizontal, 16)

                HStack {
                    Image(systemName: "calendar")
                        .foregroundStyle(.secondary)
                        .font(.system(size: 13))
                    Text(creationDate)
                        .foregroundStyle(.secondary)
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .transition(.opacity.combined(with: .scale(scale: 0.95)))
            }
        }
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: isActive)
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: dreamDescription)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        AddNewView()
    }
}
