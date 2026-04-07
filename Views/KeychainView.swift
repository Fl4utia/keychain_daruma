//
//  KeychainView.swift
//  ximena
//
//  Created by Estrella Verdiguel on 31/03/26.
//

import SwiftUI
import RealityKit
import Combine

struct KeychainView: View {
    @StateObject private var viewModel = KeychainViewModel()
    @Environment(SettingsManager.self) private var settings
    @State private var showSettings = false
    @State private var showDarumaDetail = false

    // Placeholder daruma — tapping the 3D doll opens its detail view.
    // Replace with persisted entry once storage is wired up.
    private let placeholderEntry = DarumaEntry(
        title: "laurea",
        date: Calendar.current.date(from: DateComponents(year: 2027, month: 8, day: 28))!
    )

    var body: some View {
        ZStack {

            ARViewContainer(viewModel: viewModel)
                .ignoresSafeArea()

            // Drag gesture layer — captures the full screen.
            // A gesture that ends with less than 10 pt of travel is treated as a tap
            // and opens the daruma detail view instead of applying pendulum force.
            Color.clear
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            viewModel.handleDrag(translation: value.translation)
                        }
                        .onEnded { value in
                            viewModel.handleDragEnded()
                            let magnitude = hypot(value.translation.width, value.translation.height)
                            if magnitude < 10 {
                                showDarumaDetail = true
                            }
                        }
                )
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: settings.leftHandedMode ? .topBarLeading : .topBarTrailing) {
                Button {
                    showSettings = true
                } label: {
                    Label("Settings", systemImage: "gearshape.fill")
                }
            }
        }
        .toolbarBackground(.visible, for: .navigationBar)
        .navigationDestination(isPresented: $showSettings) {
            SettingsView()
        }
        .navigationDestination(isPresented: $showDarumaDetail) {
            DarumaDetailView(entry: placeholderEntry)
        }
    }
}

// MARK: - ARView Container

struct ARViewContainer: UIViewRepresentable {
    let viewModel: KeychainViewModel

    func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero)
        arView.environment.background = .color(.clear)
        viewModel.setup(arView: arView)
        return arView
    }

    func updateUIView(_ uiView: ARView, context: Context) {}
}


// MARK: - Preview

#Preview {
    NavigationStack {
        KeychainView()
    }
    .environment(SettingsManager())
}
