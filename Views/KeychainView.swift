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
    @State private var showAddNew = false

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

            ToolbarItemGroup(placement: .bottomBar) {
                if settings.leftHandedMode {
                    Button {
                        showAddNew = true
                    } label: {
                        Label("Add new", systemImage: "plus")
                    }
                    Spacer()
                } else {
                    Spacer()
                    Button {
                        showAddNew = true
                    } label: {
                        Label("Add new", systemImage: "plus")
                    }
                }
            }
        }
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarBackground(.visible, for: .bottomBar)
        .navigationDestination(isPresented: $showSettings) {
            SettingsView()
        }
        .navigationDestination(isPresented: $showAddNew) {
            AddNewView()
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


// MARK: - Preview

#Preview {
    NavigationStack {
        KeychainView()
    }
    .environment(SettingsManager())
}
