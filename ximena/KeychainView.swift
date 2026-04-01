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

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            ARViewContainer(viewModel: viewModel)
                .ignoresSafeArea()

            // Drag gesture layer — captures the full screen
            Color.clear
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            viewModel.handleDrag(translation: value.translation)
                        }
                        .onEnded { _ in
                            viewModel.handleDragEnded()
                        }
                )

            // Settings button — rendered above the gesture layer so it receives taps first
            settingsButton
        }
        .toolbar(.hidden, for: .navigationBar)
    }

    private var settingsButton: some View {
        VStack {
            HStack {
                Spacer()
                NavigationLink(destination: SettingsView()) {
                    Image(systemName: "gearshape.fill")
                        .font(.title2)
                        .foregroundStyle(.white.opacity(0.7))
                        .padding(20)
                }
            }
            Spacer()
        }
    }
}

// MARK: - ARView Container

struct ARViewContainer: UIViewRepresentable {
    let viewModel: KeychainViewModel

    func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero)
        arView.environment.background = .color(.black)
        viewModel.setup(arView: arView)
        return arView
    }

    func updateUIView(_ uiView: ARView, context: Context) {}
}
