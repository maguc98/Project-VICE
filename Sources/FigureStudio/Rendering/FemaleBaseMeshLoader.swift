import Foundation
import SceneKit
import GLTFKit2
import simd

/// Loads the bundled, offline female anatomical base mesh.
enum FemaleBaseMeshLoader {
    private static var retainedAsset: GLTFAsset?
    private static var cachedScene: SCNScene?
    private static var isLoading = false
    private static var pendingCompletions: [(SCNScene?) -> Void] = []

    static func load(completion: @escaping (SCNScene?) -> Void) {
        if let cachedScene {
            completion(cachedScene)
            return
        }
        pendingCompletions.append(completion)
        guard !isLoading else { return }
        isLoading = true

        guard let url = Bundle.main.url(forResource: "FemaleBase", withExtension: "glb") else {
            finish(nil)
            return
        }

        GLTFAsset.load(with: url, options: [:]) { _, status, maybeAsset, maybeError, _ in
            guard status == .complete, let asset = maybeAsset else {
                if let maybeError {
                    NSLog("Female base mesh load failed: %@", maybeError.localizedDescription)
                }
                DispatchQueue.main.async { finish(nil) }
                return
            }

            let source = GLTFSCNSceneSource(asset: asset)
            let scene = source.defaultScene
            DispatchQueue.main.async {
                retainedAsset = asset
                finish(scene)
            }
        }
    }

    private static func finish(_ scene: SCNScene?) {
        cachedScene = scene
        isLoading = false
        let completions = pendingCompletions
        pendingCompletions.removeAll()
        completions.forEach { $0(scene) }
    }
}

/// Applies articulation to the actual skin-weighted MakeHuman skeleton in the GLB.
final class FemaleFigureRig {
    private let root: SCNNode
    private var nodes: [String: SCNNode] = [:]
    private var restOrientations: [String: simd_quatf] = [:]

    init(root: SCNNode) {
        self.root = root
        root.enumerateChildNodes { node, _ in
            guard let name = node.name else { return }
            self.nodes[name] = node
            self.restOrientations[name] = node.simdOrientation
        }
    }

    func apply(_ pose: FigurePose) {
        applySpine(pose)
        applyArm(pose.leftArm, side: "L")
        applyArm(pose.rightArm, side: "R")
        applyLeg(pose.leftLeg, side: "L", mode: pose.rigMode)
        applyLeg(pose.rightLeg, side: "R", mode: pose.rigMode)
        rotate("head", x: -pose.headTiltDegrees, y: pose.headRotationDegrees)
    }

    private func applySpine(_ pose: FigurePose) {
        let weights: [(String, Double)] = [
            ("spine01", 0.12), ("spine02", 0.18), ("spine03", 0.24),
            ("spine04", 0.24), ("spine05", 0.22)
        ]
        for (name, weight) in weights {
            rotate(name,
                   x: -pose.spineFlexionDegrees * weight,
                   y: pose.spineRotationDegrees * weight,
                   z: -pose.spineSideBendDegrees * weight)
        }
    }

    private func applyArm(_ arm: ArmPose, side: String) {
        // Share shoulder motion across the clavicle and two upper-arm segments.
        rotate("clavicle.\(side)",
               x: -arm.shoulderFlexionDegrees * 0.12,
               z: arm.shoulderAbductionDegrees * 0.15)
        rotate("shoulder01.\(side)",
               x: -arm.shoulderFlexionDegrees * 0.18,
               z: arm.shoulderAbductionDegrees * 0.20)
        rotate("upperarm01.\(side)",
               x: -arm.shoulderFlexionDegrees * 0.48,
               z: arm.shoulderAbductionDegrees * 0.48)
        rotate("upperarm02.\(side)",
               x: -arm.shoulderFlexionDegrees * 0.22,
               z: arm.shoulderAbductionDegrees * 0.17)

        // Elbow hinge and forearm rotation.
        rotate("lowerarm01.\(side)", x: -arm.elbowFlexionDegrees * 0.70)
        rotate("lowerarm02.\(side)",
               x: -arm.elbowFlexionDegrees * 0.30,
               y: arm.forearmRotationDegrees)
        rotate("wrist.\(side)",
               x: -arm.wristFlexionDegrees,
               z: arm.wristDeviationDegrees)

        // MakeHuman finger 1 = thumb; 2-5 = index through little finger.
        let segmentWeights = [0.54, 0.30, 0.16]
        for finger in 1...5 {
            let value = finger - 1 < arm.fingerCurlDegrees.count ? arm.fingerCurlDegrees[finger - 1] : 0
            for segment in 1...3 {
                let weight = segmentWeights[segment - 1]
                rotate("finger\(finger)-\(segment).\(side)", x: -value * weight)
            }
        }
    }

    private func applyLeg(_ leg: LegPose, side: String, mode: FigureRigMode) {
        let angles = mode == .ik ? solveLeg(leg) : (leg.hipFlexionDegrees, leg.kneeFlexionDegrees)
        rotate("pelvis.\(side)",
               x: -angles.0 * 0.12,
               z: leg.hipAbductionDegrees * 0.12)
        rotate("upperleg01.\(side)",
               x: -angles.0 * 0.60,
               y: leg.hipRotationDegrees * 0.55,
               z: leg.hipAbductionDegrees * 0.60)
        rotate("upperleg02.\(side)",
               x: -angles.0 * 0.28,
               y: leg.hipRotationDegrees * 0.45,
               z: leg.hipAbductionDegrees * 0.28)
        rotate("lowerleg01.\(side)", x: -angles.1 * 0.72)
        rotate("lowerleg02.\(side)", x: -angles.1 * 0.28)
        rotate("foot.\(side)", x: -leg.ankleFlexionDegrees)

        for toe in 1...5 {
            rotate("toe\(toe)-1.\(side)", x: -leg.toeCurlDegrees * 0.60)
            rotate("toe\(toe)-2.\(side)", x: -leg.toeCurlDegrees * 0.28)
            rotate("toe\(toe)-3.\(side)", x: -leg.toeCurlDegrees * 0.12)
        }
    }

    private func solveLeg(_ leg: LegPose) -> (Double, Double) {
        let upper: Double = 0.535
        let lower: Double = 0.495
        let forward = leg.footForwardTargetCM / 100
        let down = max(0.08, upper + lower - leg.footLiftTargetCM / 100)
        let raw = sqrt(forward * forward + down * down)
        let distance = min(max(raw, abs(upper - lower) + 0.001), upper + lower - 0.001)
        let kneeCos = min(max((upper * upper + lower * lower - distance * distance)
                              / (2 * upper * lower), -1), 1)
        let knee = Double.pi - acos(kneeCos)
        let hipCos = min(max((upper * upper + distance * distance - lower * lower)
                             / (2 * upper * distance), -1), 1)
        let hip = atan2(forward, down) + acos(hipCos)
        return (hip * 180 / .pi, knee * 180 / .pi)
    }

    private func rotate(_ name: String, x: Double = 0, y: Double = 0, z: Double = 0) {
        guard let node = nodes[name], let rest = restOrientations[name] else { return }
        let qx = simd_quatf(angle: Float(x * .pi / 180), axis: SIMD3<Float>(1, 0, 0))
        let qy = simd_quatf(angle: Float(y * .pi / 180), axis: SIMD3<Float>(0, 1, 0))
        let qz = simd_quatf(angle: Float(z * .pi / 180), axis: SIMD3<Float>(0, 0, 1))
        node.simdOrientation = simd_mul(simd_mul(simd_mul(rest, qx), qy), qz)
    }
}
