import SwiftUI
import RealityKit
import Combine
import CoreMotion   // ← NEW

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

    // ── Clamp: ±π/2 (90°) each side = 180° total arc ──
    private let maxAngle: Float  = .pi / 2

    private var pendulumLink: CADisplayLink?
    private var idleTime: Float = 0
    private var idleLink: CADisplayLink?

    // ── Gyroscope ──────────────────────────────────────
    private let motionManager = CMMotionManager()
    private var gyroForce: Float = 0   // accumulated tilt influence

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
        startGyroscope()   // ← NEW
    }

    // MARK: - Gyroscope

    private func startGyroscope() {
        guard motionManager.isDeviceMotionAvailable else { return }

        // Update at 60 Hz; we read the value each display-link frame instead
        // of using the handler queue so we stay on the main thread.
        motionManager.deviceMotionUpdateInterval = 1.0 / 60.0
        motionManager.startDeviceMotionUpdates(to: .main) { [weak self] motion, _ in
            guard let self, let motion else { return }
            // gravity.x ranges –1 … +1 (device tilted left/right).
            // We use it as a continuous nudge force on the pendulum.
            // Negated so daruma swings in the correct direction when tilting
            self.gyroForce = -Float(motion.gravity.x) * 0.004
        }
    }

    // MARK: - Carga de modelos

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
        argollaEntity.scale    = SIMD3<Float>(repeating: 0.2)
        argollaEntity.position = SIMD3<Float>(0, 11, -0.4)
        anchorEntity?.addChild(argollaEntity)
        self.argolla = argollaEntity

        // ── GANCHITO ─────────────────────────────────
        ganchitoEntity.scale    = SIMD3<Float>(repeating: 0.6)
        // Position offset so the TOP of ganchito aligns with the argolla's origin,
        // making it look attached to the bottom of the ring rather than centered on it.
        ganchitoEntity.position = SIMD3<Float>(0.25, 3, -1.5)

        let rotGX = simd_quatf(angle: -.pi / 2, axis: SIMD3<Float>(1, 0, 0))
        let rotGZ = simd_quatf(angle:  .pi / 2, axis: SIMD3<Float>(0, 0, 1))
        ganchitoEntity.orientation = rotGX * rotGZ
        argollaEntity.addChild(ganchitoEntity)
        self.ganchito = ganchitoEntity

        // ── DARUMA — bigger scale (was 1.8) ──────────
        darumaEntity.scale    = SIMD3<Float>(repeating: 5.0)   // ← BIGGER
        darumaEntity.position = SIMD3<Float>(10, 0.2, 0)

        let rotX = simd_quatf(angle:  .pi / 2, axis: SIMD3<Float>(1, 0, 0))
        let rotZ = simd_quatf(angle: -.pi,     axis: SIMD3<Float>(0, 0, 1))
        let rotY = simd_quatf(angle:  .pi / 2, axis: SIMD3<Float>(0, 1, 0))
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

    // MARK: - Péndulo — clamped to ±maxAngle

    private func startPendulumLoop() {
        let link = CADisplayLink(target: self, selector: #selector(pendulumStep))
        link.add(to: .main, forMode: .common)
        self.pendulumLink = link
    }

    @objc private func pendulumStep() {
        // Add gyroscope nudge each frame
        velocityY += gyroForce

        velocityY += -gravity * angleY
        velocityY *= damping
        angleY    += velocityY

        // ── Clamp to ±90° and kill velocity if we hit the wall ──
        if angleY > maxAngle {
            angleY    =  maxAngle
            velocityY = -abs(velocityY) * 0.3   // small bounce-back
        } else if angleY < -maxAngle {
            angleY    = -maxAngle
            velocityY =  abs(velocityY) * 0.3
        }

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
