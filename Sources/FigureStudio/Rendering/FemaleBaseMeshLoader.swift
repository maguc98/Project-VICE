import Foundation
import SceneKit
import GLTFKit2
import simd

/// Loads a fresh copy of the bundled GLB for each viewport or export.
/// The source asset remains bundled locally; no network access is needed at runtime.
enum FemaleBaseMeshLoader {
    private static var retainedAsset: GLTFAsset?

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
                retainedAsset = asset
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
    private var restLocalPositions: [String: SCNVector3] = [:]
    private var restScales: [String: SCNVector3] = [:]

    private struct DeformableMesh {
        let node: SCNNode
        let baseGeometry: SCNGeometry
        let vertexSourceIndex: Int
        let basePositions: [SIMD3<Float>]
        let source: SCNGeometrySource
    }
    private var deformableMeshes: [DeformableMesh] = []

    init(root: SCNNode) {
        self.root = root
        root.enumerateChildNodes { node, _ in
            guard let name = node.name else { return }
            self.nodes[name] = node
            self.restOrientations[name] = node.simdOrientation
            self.restLocalPositions[name] = node.position
            self.restScales[name] = node.scale
            let point = node.convertPosition(SCNVector3Zero, to: root)
            self.restPositions[name] = SIMD3<Float>(point.x, point.y, point.z)
        }
        collectDeformableMeshes()
    }

    /// Captures original skinned vertex positions once so every slider update is non-cumulative.
    private func collectDeformableMeshes() {
        root.enumerateChildNodes { node, _ in
            guard node.skinner != nil, let geometry = node.geometry,
                  let index = geometry.sources.firstIndex(where: {
                      $0.semantic == .vertex && $0.usesFloatComponents
                          && $0.componentsPerVector >= 3 && $0.bytesPerComponent == MemoryLayout<Float>.size
                  }) else { return }
            let source = geometry.sources[index]
            let stride = source.dataStride
            let offset = source.dataOffset
            let bytes = source.data
            guard stride >= source.componentsPerVector * source.bytesPerComponent,
                  bytes.count >= offset + max(source.vectorCount - 1, 0) * stride + 3 * MemoryLayout<Float>.size else { return }
            var positions: [SIMD3<Float>] = []
            positions.reserveCapacity(source.vectorCount)
            bytes.withUnsafeBytes { raw in
                for vertex in 0..<source.vectorCount {
                    let base = offset + vertex * stride
                    let x = raw.loadUnaligned(fromByteOffset: base, as: Float.self)
                    let y = raw.loadUnaligned(fromByteOffset: base + MemoryLayout<Float>.size, as: Float.self)
                    let z = raw.loadUnaligned(fromByteOffset: base + 2 * MemoryLayout<Float>.size, as: Float.self)
                    positions.append(SIMD3<Float>(x, y, z))
                }
            }
            deformableMeshes.append(DeformableMesh(
                node: node, baseGeometry: geometry, vertexSourceIndex: index,
                basePositions: positions, source: source
            ))
        }
        NSLog("Figure Studio: captured %d skinned mesh sections for localized contour shaping.", deformableMeshes.count)
    }

    /// Applies local torso contour changes to the original skin-weighted mesh vertices.
    /// The deformation is rebuilt from the immutable bind geometry, so repeated slider
    /// updates never accumulate rounding error or progressively distort the model.
    private func applyLocalizedBodyShape(_ profile: BodyProfile) {
        guard !deformableMeshes.isEmpty else { return }
        let chest = Float(min(max(profile.chest / 86.0, 0.72), 1.32))
        let waist = Float(min(max(profile.waist / 68.0, 0.72), 1.32))
        let pelvis = Float(min(max(profile.pelvis / 94.0, 0.72), 1.32))
        let bustDelta = Float(min(max((profile.bustProjection - 9.0) / 100.0, -0.07), 0.09))
        let gluteDelta = Float(min(max((profile.glutealProjection - 10.0) / 100.0, -0.07), 0.09))

        for mesh in deformableMeshes {
            var values: [Float] = []
            values.reserveCapacity(mesh.basePositions.count * 3)
            for local in mesh.basePositions {
                let world = mesh.node.convertPosition(
                    SCNVector3(local.x, local.y, local.z), to: root
                )
                let x = world.x
                let y = world.y
                let z = world.z
                let torsoGate = 1 - smoothstep(0.30, 0.49, abs(x))
                let chestMask = exp(-pow((y - 1.91) / 0.245, 2)) * torsoGate
                let waistMask = exp(-pow((y - 1.49) / 0.185, 2)) * torsoGate
                let pelvisMask = exp(-pow((y - 1.105) / 0.205, 2)) * torsoGate

                var shapedX = x
                var shapedZ = z
                shapedX *= 1 + (chest - 1) * chestMask
                shapedZ *= 1 + (chest - 1) * chestMask * 0.72
                shapedX *= 1 + (waist - 1) * waistMask
                shapedZ *= 1 + (waist - 1) * waistMask * 0.72
                shapedX *= 1 + (pelvis - 1) * pelvisMask
                shapedZ *= 1 + (pelvis - 1) * pelvisMask * 0.72

                let bustFront = smoothstep(0.025, 0.20, z)
                    * exp(-pow((y - 1.84) / 0.19, 2))
                    * exp(-pow(x / 0.205, 4))
                let gluteBack = smoothstep(0.015, 0.20, -z)
                    * exp(-pow((y - 1.075) / 0.22, 2))
                    * exp(-pow(x / 0.245, 4))
                shapedZ += bustDelta * bustFront
                shapedZ -= gluteDelta * gluteBack

                let localShaped = mesh.node.convertPosition(
                    SCNVector3(shapedX, y, shapedZ), from: root
                )
                values.append(localShaped.x)
                values.append(localShaped.y)
                values.append(localShaped.z)
            }

            let data = values.withUnsafeBufferPointer { Data(buffer: $0) }
            let replacement = SCNGeometrySource(
                data: data, semantic: .vertex, vectorCount: mesh.basePositions.count,
                usesFloatComponents: true, componentsPerVector: 3,
                bytesPerComponent: MemoryLayout<Float>.size, dataOffset: 0,
                dataStride: 3 * MemoryLayout<Float>.size
            )
            var sources = mesh.baseGeometry.sources
            sources[mesh.vertexSourceIndex] = replacement
            let geometry = SCNGeometry(sources: sources, elements: mesh.baseGeometry.elements)
            geometry.materials = mesh.baseGeometry.materials
            mesh.node.geometry = geometry
        }
    }

    private func smoothstep(_ edge0: Float, _ edge1: Float, _ value: Float) -> Float {
        let t = min(max((value - edge0) / (edge1 - edge0), 0), 1)
        return t * t * (3 - 2 * t)
    }

    /// Applies restrained segment and contour proportion adjustments on the skinned rig.
    /// This is a bone-scale approximation; it does not replace a sculpted morph-target set.
    func applyProfile(_ profile: BodyProfile) {
        applyLocalizedBodyShape(profile)
        let shoulder = clamped(profile.shoulderWidth / 38.0, 0.78, 1.24)
        let chest = clamped(profile.chest / 86.0, 0.78, 1.25)
        let waist = clamped(profile.waist / 68.0, 0.78, 1.24)
        let pelvis = clamped(profile.pelvis / 94.0, 0.78, 1.25)
        let bust = clamped(profile.bustProjection / 9.0, 0.55, 1.70)
        let glute = clamped(profile.glutealProjection / 10.0, 0.55, 1.65)
        let upperArm = clamped(profile.upperArm / 29.0, 0.75, 1.30)
        let forearm = clamped(profile.forearm / 24.0, 0.75, 1.30)
        let thigh = clamped(profile.thigh / 43.0, 0.75, 1.30)
        let lowerLeg = clamped(profile.lowerLeg / 39.0, 0.75, 1.30)
        let hand = clamped(profile.handLength / 17.5, 0.75, 1.30)
        let footWidth = clamped(profile.footWidth / 9.0, 0.75, 1.30)
        let footLength = clamped(profile.footLength / 24.0, 0.75, 1.30)
        let head = clamped(profile.headHeight / 22.0, 0.78, 1.25)

        for side in ["L", "R"] {
            scaleNode("clavicle.\(side)", x: shoulder, z: shoulder)
            scaleNode("shoulder01.\(side)", x: shoulder, z: shoulder)
            scaleNode("breast.\(side)", z: bust)
            scaleNode("pelvis.\(side)", x: pelvis, z: glute)
            scaleNode("upperarm02.\(side)", y: upperArm)
            scaleNode("lowerarm02.\(side)", y: forearm)
            scaleNode("upperleg02.\(side)", y: thigh)
            scaleNode("lowerleg02.\(side)", y: lowerLeg)
            scaleNode("wrist.\(side)", x: hand, y: hand, z: hand)
            scaleNode("foot.\(side)", x: footWidth, z: footLength)
            for finger in 1...5 {
                scaleNode("finger\(finger)-1.\(side)", y: hand)
                scaleNode("finger\(finger)-2.\(side)", y: hand)
                scaleNode("finger\(finger)-3.\(side)", y: hand)
            }

            if let clavicle = nodes["clavicle.\(side)"],
               let original = restLocalPositions["clavicle.\(side)"] {
                clavicle.position = SCNVector3(original.x * Float(shoulder), original.y, original.z)
            }
            if let pelvisNode = nodes["pelvis.\(side)"],
               let original = restLocalPositions["pelvis.\(side)"] {
                pelvisNode.position = SCNVector3(original.x * Float(pelvis), original.y, original.z)
            }
        }

        scaleNode("head", y: head)
    }

    private func clamped(_ value: Double, _ lower: Double, _ upper: Double) -> Double {
        min(max(value, lower), upper)
    }

    private func scaleNode(_ name: String, x: Double = 1, y: Double = 1, z: Double = 1) {
        guard let node = nodes[name], let base = restScales[name] else { return }
        node.scale = SCNVector3(base.x * Float(x), base.y * Float(y), base.z * Float(z))
    }

    /// Adds a live joint-and-bone guide to the imported skeleton for figure study.
    func setSkeletonVisible(_ visible: Bool) {
        for node in nodes.values {
            node.childNodes.filter { $0.name == "__figureBoneGuide" }.forEach { $0.removeFromParentNode() }
        }
        guard visible else { return }
        let guideMaterial = SCNMaterial()
        guideMaterial.diffuse.contents = UIColor(red: 0.16, green: 0.47, blue: 0.69, alpha: 1)
        guideMaterial.emission.contents = UIColor(red: 0.06, green: 0.18, blue: 0.28, alpha: 1)
        guideMaterial.lightingModel = .constant

        for (_, parent) in nodes {
            let joints = parent.childNodes.filter { child in
                guard let childName = child.name else { return false }
                return nodes[childName] === child
            }
            for joint in joints {
                let delta = SIMD3<Float>(joint.position.x, joint.position.y, joint.position.z)
                let length = simd_length(delta)
                guard length > 0.012 else { continue }
                let cylinder = SCNCylinder(radius: 0.0045, height: CGFloat(length))
                cylinder.radialSegmentCount = 8
                cylinder.firstMaterial = guideMaterial
                let guide = SCNNode(geometry: cylinder)
                guide.name = "__figureBoneGuide"
                guide.position = SCNVector3(delta.x * 0.5, delta.y * 0.5, delta.z * 0.5)
                guide.simdOrientation = simd_quatf(
                    from: SIMD3<Float>(0, 1, 0),
                    to: simd_normalize(delta)
                )
                parent.addChildNode(guide)

                let jointSphere = SCNSphere(radius: 0.008)
                jointSphere.segmentCount = 8
                jointSphere.firstMaterial = guideMaterial
                let marker = SCNNode(geometry: jointSphere)
                marker.name = "__figureBoneGuide"
                marker.position = joint.position
                parent.addChildNode(marker)
            }
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
