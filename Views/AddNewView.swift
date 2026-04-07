//
//  DarumaDetailView.swift
//  ximena
//
//  Created by Salvatore De Rosa on 02/04/2026.
//
//  NOTE: rename this file to DarumaDetailView.swift in Xcode's Project Navigator
//  (right-click → Rename) to resolve persistent SourceKit indexing warnings.

import UIKit       // UIViewRepresentable, UIPanGestureRecognizer
import RealityKit  // ARView, AnchorEntity, Entity, DirectionalLightComponent
import SwiftUI

// MARK: - Root view

struct DarumaDetailView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var entry: DarumaEntry
    @State private var isEditing = false
    @State private var showDeleteConfirmation = false
    @State private var audioManager = AudioRecorderManager()
    @FocusState private var titleFocused: Bool   // stays here — FocusState.Binding cannot be passed to sub-views

    init(entry: DarumaEntry) {
        _entry = State(initialValue: entry)
    }

    private static let dateFmt: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "dd/MM/yyyy"
        return f
    }()

    var body: some View {
        ZStack {
            // ── 1. Background ──────────────────────────────────────────────────
            Color(.systemBackground)
                .ignoresSafeArea()

            // ── 2. Ghost title — behind the daruma in ZStack order ─────────────
            // Large fixed font + minimumScaleFactor: the layout engine scales it
            // to fill available space with zero geometry reading required.
            GhostTitleView(title: entry.title, isEditing: isEditing)

            // ── 3. Daruma scene + floating record button ───────────────────────
            // allowsHitTesting is managed inside DarumaSceneView based on isEditing.
            DarumaSceneView(audioManager: audioManager, isEditing: isEditing)

            // ── 4. Dark overlay — dims the scene when editing ─────────────────
            // Sits above the daruma and ghost text, below the title field.
            // Provides the visual focus cue that the screen is in edit mode.
            if isEditing {
                Color.black.opacity(0.55)
                    .ignoresSafeArea()
                    .transition(.opacity)
            }

            // ── 5. Tap-to-dismiss surface ──────────────────────────────────────
            // Transparent, above the dark overlay, below the title field.
            // Taps outside the TextField exit edit mode.
            if isEditing {
                Color.clear
                    .contentShape(Rectangle())
                    .onTapGesture { exitEditing() }
            }

            // ── 6. Inline title editor ─────────────────────────────────────────
            // Topmost layer. FocusState lives here in the root view — it cannot
            // be bridged to a child struct without losing the focus contract.
            if isEditing {
                TextField("Goal", text: $entry.title)
                    .font(.title2.bold())
                    .multilineTextAlignment(.center)
                    .focused($titleFocused)
                    .submitLabel(.done)
                    .onSubmit { exitEditing() }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(
                        Color(.systemFill),
                        in: RoundedRectangle(cornerRadius: 10, style: .continuous)
                    )
                    .padding(.horizontal, 32)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                    .padding(.top, 16)
                    .transition(.opacity.combined(with: .move(edge: .top)))
                    .zIndex(1)
            }
        }
        // Bottom bar — pinned above the home indicator via safeAreaInset.
        // .ignoresSafeArea(.keyboard) prevents the bar from jumping when the
        // title keyboard appears, since editing happens at the top of the screen.
        .safeAreaInset(edge: .bottom) {
            DetailBottomBar(
                date: Self.dateFmt.string(from: entry.date),
                onDelete: { showDeleteConfirmation = true }
            )
            .offset(y: isEditing ? 120 : 0)
            .opacity(isEditing ? 0 : 1)
            .animation(.spring(response: 0.35, dampingFraction: 0.85), value: isEditing)
            .ignoresSafeArea(.keyboard)
        }
        // Back button is hidden while editing — navigating away mid-edit
        // would discard unsaved changes without warning, which violates HIG.
        // The "Done" button is the only exit path during edit mode.
        .navigationBarBackButtonHidden(isEditing)
        .toolbar {
            // Native "Edit" / "Done" text pattern — identical to Notes, Contacts,
            // and every first-party iOS app. "Done" is semibold per HIG convention.
            ToolbarItem(placement: .topBarTrailing) {
                Button(isEditing ? "Done" : "Edit") {
                    isEditing ? exitEditing() : enterEditing()
                }
                .fontWeight(isEditing ? .semibold : .regular)
                .accessibilityLabel(isEditing ? "Done editing" : "Edit goal")
            }
        }
        // confirmationDialog attached to the root view, not to the button.
        // Attaching it to a leaf view (Button) causes unreliable presentation
        // when the button is inside a safeAreaInset or conditional branch.
        .confirmationDialog(
            "Delete this daruma?",
            isPresented: $showDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                // TODO: remove from persistence layer before dismissing
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This action cannot be undone.")
        }
        .toolbarBackground(.hidden, for: .navigationBar)
    }

    // MARK: - Edit mode

    private func enterEditing() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            isEditing = true
        }
        // FocusState mutations are not animatable — set after the animation block.
        titleFocused = true
    }

    private func exitEditing() {
        // Dismiss keyboard first so the system keyboard animation runs in
        // parallel with (not after) the SwiftUI spring below.
        titleFocused = false
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            isEditing = false
        }
    }
}

// MARK: - Ghost title

private struct GhostTitleView: View {
    let title: String
    let isEditing: Bool

    var body: some View {
        Text(title)
            .font(.system(size: 200, weight: .black))   // intentionally oversized —
            .minimumScaleFactor(0.05)                   // layout engine scales to fit
            .lineLimit(6)
            .foregroundStyle(.primary.opacity(isEditing ? 0.04 : 0.08))
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .padding(.horizontal, 24)
            .padding(.top, 16)
            .allowsHitTesting(false)
            .accessibilityHidden(true)
            .animation(.easeOut(duration: 0.2), value: isEditing)
    }
}

// MARK: - Daruma scene

private struct DarumaSceneView: View {
    let audioManager: AudioRecorderManager
    let isEditing: Bool

    var body: some View {
        DarumaPreviewView(darumaType: .basic)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            // Disables both the pan gesture and the record button for the
            // entire duration of edit mode, not just when the keyboard is up.
            .allowsHitTesting(!isEditing)
            .overlay(alignment: .bottomTrailing) {
                // Record button anchored to the daruma view's bottom-right corner.
                // Position is screen-size-independent — no offset arithmetic needed.
                // Fades out when editing so only the title field holds attention.
                RecordFloatingButton(audioManager: audioManager)
                    .padding(.trailing, 24)
                    .padding(.bottom, 24)
                    .opacity(isEditing ? 0 : 1)
                    .animation(.easeOut(duration: 0.2), value: isEditing)
            }
    }
}

// MARK: - Detail bottom bar

private struct DetailBottomBar: View {
    let date: String
    let onDelete: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text(date)
                    .foregroundStyle(.primary.opacity(0.8))
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 18)
            .background(
                Color(.secondarySystemBackground),
                in: RoundedRectangle(cornerRadius: 14, style: .continuous)
            )

            Button(role: .destructive, action: onDelete) {
                Text("Delete")
                    .foregroundStyle(.red)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 8)
    }
}

// MARK: - Record floating button

struct RecordFloatingButton: View {
    let audioManager: AudioRecorderManager

    private var iconName: String {
        if audioManager.isRecording  { return "stop.circle.fill" }
        if audioManager.isPlaying    { return "pause.circle.fill" }
        if audioManager.hasRecording { return "play.circle.fill" }
        return "record.circle"
    }

    var body: some View {
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
                .font(.system(size: 34))
                .foregroundStyle(.primary.opacity(0.85))
                .contentTransition(.symbolEffect(.replace))
        }
        .frame(width: 44, height: 44)   // HIG minimum touch target
        .buttonStyle(.plain)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: audioManager.isRecording)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: audioManager.hasRecording)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: audioManager.isPlaying)
    }
}

// MARK: - 3D Daruma preview (UIViewRepresentable)

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

    // MARK: Lighting

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

// MARK: - Preview

#Preview {
    NavigationStack {
        DarumaDetailView(entry: DarumaEntry(
            title: "laurea",
            date: Calendar.current.date(from: DateComponents(year: 2027, month: 8, day: 28))!
        ))
    }
}
