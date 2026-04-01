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
