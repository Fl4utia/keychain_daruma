import SwiftUI
import RealityKit
import Combine

// MARK: - ViewModel

class KeychainViewModel: NSObject, ObservableObject {
    private var arView: ARView?
    private var anchorEntity: AnchorEntity?

    private var argolla: Entity?
    private var ganchito: Entity?
    private var daruma: Entity?

    private var angleY: Float = 0
    private var velocityY: Float = 0

    private let gravity: Float   = 0.012
    private let damping: Float   = 0.96
    private let dragForce: Float = 0.06

    private var pendulumLink: CADisplayLink?
    private var idleTime: Float = 0
    private var idleLink: CADisplayLink?

    func setup(arView: ARView) {
        self.arView = arView
        arView.environment.background = .color(.black)

        // Luz principal
        var lightComponent = DirectionalLightComponent()
        lightComponent.intensity = 1200
        let lightEntity = Entity()
        lightEntity.components.set(lightComponent)
        lightEntity.look(at: SIMD3<Float>(0, 0, 0),
                         from: SIMD3<Float>(0.5, 1.5, 1.0),
                         relativeTo: nil)

        // Luz de relleno
        var fillLight = DirectionalLightComponent()
        fillLight.intensity = 400
        let fillEntity = Entity()
        fillEntity.components.set(fillLight)
        fillEntity.look(at: SIMD3<Float>(0, 0, 0),
                        from: SIMD3<Float>(-0.5, -1, 0.5),
                        relativeTo: nil)

        let anchor = AnchorEntity(world: .zero)
        anchor.addChild(lightEntity)
        anchor.addChild(fillEntity)
        self.anchorEntity = anchor
        arView.scene.anchors.append(anchor)

        loadModels()
    }

    // MARK: - Carga de modelos
    // 🎛️ AJUSTA AQUÍ las escalas y posiciones
    private func loadModels() {
        guard
            let argollaEntity  = try? Entity.load(named: "objeto3"),
            let ganchitoEntity = try? Entity.load(named: "objeto2"),
            let darumaEntity   = try? Entity.load(named: "base_basic_shaded")
        else {
            print("❌ Error cargando modelos — verifica los nombres")
            return
        }

        // ── ARGOLLA ──────────────────────────────────
        argollaEntity.scale    = SIMD3<Float>(repeating: 0.15)
        argollaEntity.position = SIMD3<Float>(0, 0.20, -0.5)
        anchorEntity?.addChild(argollaEntity)
        self.argolla = argollaEntity

        // ── GANCHITO ──────────────────────────────────
        ganchitoEntity.scale    = SIMD3<Float>(repeating: 0.55)
        ganchitoEntity.position = SIMD3<Float>(0.25, 0, -1)

        // El modelo está tumbado en XZ → lo levantamos con X, luego Z para orientar vertical
        let rotGX = simd_quatf(angle: -.pi / 2, axis: SIMD3<Float>(1, 0, 0))  // levanta del suelo
        let rotGZ = simd_quatf(angle:  .pi / 2, axis: SIMD3<Float>(0, 0, 1))  // gira para que el largo quede en Y
        ganchitoEntity.orientation = rotGX * rotGZ
        argollaEntity.addChild(ganchitoEntity)
        self.ganchito = ganchitoEntity

        // ── DARUMA — compensa la rotación del ganchito ─
        darumaEntity.scale    = SIMD3<Float>(repeating: 1.8)
        darumaEntity.position = SIMD3<Float>(4, 0.2, 0)

        // Compensamos rotGX (-.pi/2 en X) y rotGZ (.pi/2 en Z) del padre, más las rotaciones originales
        let rotX = simd_quatf(angle:  .pi/2, axis: SIMD3<Float>(1, 0, 0))  // invierte rotGX del padre
        let rotZ = simd_quatf(angle: -.pi, axis: SIMD3<Float>(0, 0, 1))  // invierte rotGZ del padre
        let rotY = simd_quatf(angle:  .pi/2,     axis: SIMD3<Float>(0, 1, 0))  // orientación original
        darumaEntity.orientation = rotZ * rotX * rotY
        ganchitoEntity.addChild(darumaEntity)
        self.daruma = darumaEntity

        startPendulumLoop()
        startIdleFloat()
    }
    // MARK: - Gesture (solo horizontal)

    func handleDrag(translation: CGSize) {
        velocityY += Float(translation.width) * dragForce * 0.01
    }

    func handleDragEnded() {}

    // MARK: - Péndulo (solo eje Y = izquierda/derecha)

    private func startPendulumLoop() {
        let link = CADisplayLink(target: self, selector: #selector(pendulumStep))
        link.add(to: .main, forMode: .common)
        self.pendulumLink = link
    }

    @objc private func pendulumStep() {
        velocityY += -gravity * angleY
        velocityY *= damping
        angleY    += velocityY

        guard let ganchitoEntity = ganchito else { return }

        let rotX      = simd_quatf(angle: -.pi / 2, axis: SIMD3<Float>(1, 0, 0))
        let rotZ      = simd_quatf(angle:  .pi / 2, axis: SIMD3<Float>(0, 0, 1))
        let baseRot   = rotX * rotZ
        let pendulumY = simd_quatf(angle: angleY, axis: SIMD3<Float>(0, 1, 0))
        ganchitoEntity.orientation = pendulumY * baseRot
    }

    // MARK: - Idle float

    private func startIdleFloat() {
        let link = CADisplayLink(target: self, selector: #selector(idleStep))
        link.add(to: .main, forMode: .common)
        self.idleLink = link
    }

    @objc private func idleStep() {
        guard let argollaEntity = argolla else { return }
        idleTime += 0.008
        argollaEntity.position.y = 0.20 + sin(idleTime) * 0.012
    }
}


// MARK: - Preview

#Preview {
    KeychainView()
}
