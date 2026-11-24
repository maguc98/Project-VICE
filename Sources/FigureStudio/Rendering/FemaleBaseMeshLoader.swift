import Foundation
import SceneKit
import GLTFKit2
import simd

/// Loads a fresh copy of the bundled GLB for each viewport or export.
/// The source asset remains bundled locally; no network access is needed at runtime.
enum FemaleBaseMeshLoader {
    private static var retainedAssets: [GLTFAsset] = []

    static func load(completion: @escaping (SCNScene?) -> Void) {
        guard let url = Bundle.main.url(forResource: "FemaleBase", withExtension: "glb") else {
            DispatchQueue.main.async { completion(nil) }
            return
        }

        GLTFAsset.load(with: url, options: [:]) { _, status, maybeAsset, maybeError, _ in
            guard status == .complete, let asset = maybeAsset else {
                if let maybeError {
                    NSLog("Female base mesh load failed: %@", maybeError.localizedDescription)
                }
                DispatchQueue.main.async { completion(nil) }
                return
            }

            let source = GLTFSCNSceneSource(asset: asset)
            let scene = source.defaultScene
            DispatchQueue.main.async {
                retainedAssets.append(asset)
                completion(scene)
            }
        }
    }
}

/// Applies articulation to the skin-weighted MakeHuman skeleton in the imported GLB.
final class FemaleFigureRig {
    private let root: SCNNode
    private var nodes: [String: SCNNode] = [:]
    private var restOrientations: [String: simd_quatf] = [:]
    private var restPositions: [String: SIMD3<Float>] = [:]

    init(root: SCNNode) {
        self.root = root
        root.enumerateChildNodes { node, _ in
            guard let name = node.name else { return }
            self.nodes[name] = node
            self.restOrientations[name] = node.simdOrientation
            let point = node.convertPosition(SCNVector3Zero, to: root)
            self.restPositions[name] = SIMD3<Float>(point.x, point.y, point.z)
        }
    }

    func apply(_ pose: FigurePose) {
        applySpine(pose)
        applyArm(pose.leftArm, side: "L", mode: pose.rigMode)
        applyArm(pose.rightArm, side: "R", mode: pose.rigMode)
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

    private func applyArm(_ arm: ArmPose, side: String, mode: FigureRigMode) {
        let angles = mode == .ik ? solveArm(arm, side: side) : (
            flexion: arm.shoulderFlexionDegrees,
            abduction: arm.shoulderAbductionDegrees,
            elbow: arm.elbowFlexionDegrees
        )
        rotate("clavicle.\(side)",
               x: -angles.flexion * 0.12,
               z: angles.abduction * 0.15)
        rotate("shoulder01.\(side)",
               x: -angles.flexion * 0.18,
               z: angles.abduction * 0.20)
        rotate("upperarm01.\(side)",
               x: -angles.flexion * 0.48,
               z: angles.abduction * 0.48)
        rotate("upperarm02.\(side)",
               x: -angles.flexion * 0.22,
               z: angles.abduction * 0.17)

        rotate("lowerarm01.\(side)", x: -angles.elbow * 0.70)
        rotate("lowerarm02.\(side)",
               x: -angles.elbow * 0.30,
               y: arm.forearmRotationDegrees)
        rotate("wrist.\(side)",
               x: -arm.wristFlexionDegrees,
               z: arm.wristDeviationDegrees)

        let segmentWeights = [0.54, 0.30, 0.16]
        for finger in 1...5 {
            let value = finger - 1 < arm.fingerCurlDegrees.count ? arm.fingerCurlDegrees[finger - 1] : 0
            for segment in 1...3 {
                rotate("finger\(finger)-\(segment).\(side)",
                       x: -value * segmentWeights[segment - 1])
            }
        }
    }

    private func solveArm(_ arm: ArmPose, side: String) -> (flexion: Double, abduction: Double, elbow: Double) {
        let shoulderKey = "upperarm01.\(side)"
        let elbowKey = "lowerarm01.\(side)"
        let wristKey = "wrist.\(side)"
        guard let shoulder = restPositions[shoulderKey],
              let elbow = restPositions[elbowKey],
              let wrist = restPositions[wristKey] else {
            return (arm.shoulderFlexionDegrees, arm.shoulderAbductionDegrees, arm.elbowFlexionDegrees)
        }

        let upper = Double(simd_length(elbow - shoulder))
        let lower = Double(simd_length(wrist - elbow))
        let base = wrist - shoulder
        let sideSign: Double = side == "L" ? -1 : 1
        let scale = max(Double(root.scale.y), 0.001)
        let target = base + SIMD3<Float>(
            Float(sideSign * arm.handReachTargetCM / 100 / scale),
            Float(arm.handLiftTargetCM / 100 / scale),
            Float(arm.handDepthTargetCM / 100 / scale)
        )
        let rawDistance = Double(simd_length(target))
        let distance = min(max(rawDistance, abs(upper - lower) + 0.001), upper + lower - 0.001)

        let kneeCosine = min(max((upper * upper + lower * lower - distance * distance)
                                 / (2 * upper * lower), -1), 1)
        let elbowBend = Double.pi - acos(kneeCosine)

        let baseAbduction = atan2(Double(base.x) * sideSign, -Double(base.y))
        let targetAbduction = atan2(Double(target.x) * sideSign, -Double(target.y))
        let baseFlexion = atan2(Double(base.z), -Double(base.y))
        let targetFlexion = atan2(Double(target.z), -Double(target.y))

        return (
            (targetFlexion - baseFlexion) * 180 / .pi,
            (targetAbduction - baseAbduction) * 180 / .pi,
            elbowBend * 180 / .pi
        )
    }

    private func applyLeg(_ leg: LegPose, side: String, mode: FigureRigMode) {
        let angles = mode == .ik ? solveLeg(leg, side: side) : (leg.hipFlexionDegrees, leg.kneeFlexionDegrees)
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

    private func solveLeg(_ leg: LegPose, side: String) -> (Double, Double) {
        let scale = max(Double(root.scale.y), 0.001)
        let upper = measuredLength(from: "pelvis.\(side)", to: "lowerleg01.\(side)") ?? 0.535
        let lower = measuredLength(from: "lowerleg01.\(side)", to: "foot.\(side)") ?? 0.495
        let forward = leg.footForwardTargetCM / 100 / scale
        let down = max(0.08, upper + lower - leg.footLiftTargetCM / 100 / scale)
        let rawDistance = sqrt(forward * forward + down * down)
        let distance = min(max(rawDistance, abs(upper - lower) + 0.001), upper + lower - 0.001)
        let kneeCos = min(max((upper * upper + lower * lower - distance * distance)
                              / (2 * upper * lower), -1), 1)
        let knee = Double.pi - acos(kneeCos)
        let hipCos = min(max((upper * upper + distance * distance - lower * lower)
                             / (2 * upper * distance), -1), 1)
        let hip = atan2(forward, down) + acos(hipCos)
        return (hip * 180 / .pi, knee * 180 / .pi)
    }

    private func measuredLength(from start: String, to end: String) -> Double? {
        guard let a = restPositions[start], let b = restPositions[end] else { return nil }
        let length = Double(simd_length(b - a))
        return length > 0.001 ? length : nil
    }

    private func rotate(_ name: String, x: Double = 0, y: Double = 0, z: Double = 0) {
        guard let node = nodes[name], let rest = restOrientations[name] else { return }
        let qx = simd_quatf(angle: Float(x * .pi / 180), axis: SIMD3<Float>(1, 0, 0))
        let qy = simd_quatf(angle: Float(y * .pi / 180), axis: SIMD3<Float>(0, 1, 0))
        let qz = simd_quatf(angle: Float(z * .pi / 180), axis: SIMD3<Float>(0, 0, 1))
        node.simdOrientation = simd_mul(simd_mul(simd_mul(rest, qx), qy), qz)
    }
}
