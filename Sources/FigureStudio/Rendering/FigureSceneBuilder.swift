import SceneKit
import UIKit
import simd

/// A female artist-reference blockout with a continuous torso surface.
/// The surface is generated from editable proportions; it is not a final anatomical scan.
enum FigureSceneBuilder {
    private struct TorsoRing {
        let y: Float
        let radiusX: Float
        let radiusZ: Float
        let centerZ: Float
    }

    static func makeScene(profile: BodyProfile) -> SCNScene {
        let scene = SCNScene()
        let root = scene.rootNode
        let h = Float(profile.stature / 165.0)

        let skin = SCNMaterial()
        skin.diffuse.contents = UIColor(red: 0.79, green: 0.67, blue: 0.59, alpha: 1)
        skin.roughness.contents = 0.88
        skin.metalness.contents = 0
        skin.lightingModel = .physicallyBased

        let shoulderFactor = Float(profile.shoulderWidth / 38.0)
        let chestFactor = Float(profile.chest / 86.0)
        let waistFactor = Float(profile.waist / 68.0)
        let hipFactor = Float(profile.pelvis / 94.0)
        let bustFactor = Float(profile.bustProjection / 9.0)
        let glutealFactor = Float(profile.glutealProjection / 10.0)

        // Ring stations run continuously from the lower pelvis through the neck.
        let baseRings: [TorsoRing] = [
            .init(y: 0.88, radiusX: 0.205 * hipFactor, radiusZ: 0.145 * hipFactor, centerZ: 0),
            .init(y: 1.02, radiusX: 0.285 * hipFactor, radiusZ: 0.185 * hipFactor, centerZ: 0),
            .init(y: 1.20, radiusX: 0.335 * hipFactor, radiusZ: 0.195 * hipFactor, centerZ: 0),
            .init(y: 1.38, radiusX: 0.285 * waistFactor, radiusZ: 0.165 * waistFactor, centerZ: 0),
            .init(y: 1.58, radiusX: 0.235 * waistFactor, radiusZ: 0.145 * waistFactor, centerZ: 0),
            .init(y: 1.78, radiusX: 0.255 * chestFactor, radiusZ: 0.165 * chestFactor, centerZ: 0),
            .init(y: 1.98, radiusX: 0.292 * chestFactor, radiusZ: 0.185 * chestFactor, centerZ: 0),
            .init(y: 2.16, radiusX: 0.270 * shoulderFactor, radiusZ: 0.160 * chestFactor, centerZ: 0),
            .init(y: 2.32, radiusX: 0.245 * shoulderFactor, radiusZ: 0.135, centerZ: 0),
            .init(y: 2.43, radiusX: 0.115, radiusZ: 0.115, centerZ: 0)
        ]
        let scaledRings = baseRings.map {
            TorsoRing(y: $0.y * h, radiusX: $0.radiusX * h, radiusZ: $0.radiusZ * h, centerZ: $0.centerZ * h)
        }
        root.addChildNode(makeTorsoSurface(
            rings: scaledRings,
            heightScale: h,
            bustFactor: bustFactor,
            glutealFactor: glutealFactor,
            material: skin,
            radialSegments: 64,
            subdivisions: 5
        ))

        // Neck and head remain separate meshes to support future facial landmark controls.
        addEllipsoid("neck", at: SCNVector3(0, 2.43 * h, 0),
                     scale: SCNVector3(0.105 * h, 0.19 * h, 0.105 * h), material: skin, to: root)
        addEllipsoid("head", at: SCNVector3(0, 2.78 * h, 0),
                     scale: SCNVector3(0.205 * h, Float(profile.headHeight / 22.0) * 0.285 * h, 0.185 * h),
                     material: skin, to: root)

        // Arms, elbows, wrists, palms and individually named fingers.
        let upperArmLength = Float(profile.upperArm / 29.0) * 0.40 * h
        let forearmLength = Float(profile.forearm / 24.0) * 0.36 * h
        let armX = 0.285 * shoulderFactor * h
        for side: Float in [-1, 1] {
            let shoulder = SCNVector3(side * armX, 2.27 * h, 0)
            let elbow = SCNVector3(side * (armX + 0.035 * h), 2.27 * h - upperArmLength, 0.015 * h)
            let wrist = SCNVector3(side * (armX + 0.055 * h), elbow.y - forearmLength, 0.035 * h)
            addEllipsoid("shoulderCap", at: shoulder,
                         scale: SCNVector3(0.115 * h, 0.14 * h, 0.115 * h), material: skin, to: root)
            addTaperedSegment("upperArm", from: shoulder, to: elbow,
                              startRadius: 0.092 * h, endRadius: 0.070 * h, material: skin, root: root)
            addEllipsoid("elbowLandmark", at: elbow,
                         scale: SCNVector3(0.072 * h, 0.075 * h, 0.070 * h), material: skin, to: root)
            addTaperedSegment("forearm", from: elbow, to: wrist,
                              startRadius: 0.070 * h, endRadius: 0.045 * h, material: skin, root: root)
            let palm = SCNVector3(wrist.x, wrist.y - 0.105 * h, wrist.z + 0.015 * h)
            addEllipsoid("palm", at: palm,
                         scale: SCNVector3(0.060 * h, Float(profile.handLength / 17.5) * 0.105 * h, 0.035 * h),
                         material: skin, to: root)
            addFingers(side: side, wrist: wrist, scale: h, material: skin, root: root)
        }

        // Legs include visible knee and ankle landmarks, with tapered thigh/shin segments.
        let thighLength = Float(profile.thigh / 43.0) * 0.53 * h
        let shinLength = Float(profile.lowerLeg / 39.0) * 0.49 * h
        for side: Float in [-1, 1] {
            let hip = SCNVector3(side * 0.175 * hipFactor * h, 1.08 * h, 0)
            let knee = SCNVector3(side * 0.16 * hipFactor * h, hip.y - thighLength, 0.015 * h)
            let ankle = SCNVector3(side * 0.16 * hipFactor * h, knee.y - shinLength, 0.025 * h)
            addTaperedSegment("thigh", from: hip, to: knee,
                              startRadius: 0.145 * h, endRadius: 0.092 * h, material: skin, root: root)
            addEllipsoid("kneecap", at: knee,
                         scale: SCNVector3(0.085 * h, 0.095 * h, 0.085 * h), material: skin, to: root)
            addTaperedSegment("lowerLeg", from: knee, to: ankle,
                              startRadius: 0.082 * h, endRadius: 0.050 * h, material: skin, root: root)
            addEllipsoid("ankleLandmark", at: ankle,
                         scale: SCNVector3(0.055 * h, 0.060 * h, 0.055 * h), material: skin, to: root)

            addEllipsoid("foot", at: SCNVector3(ankle.x, ankle.y - 0.045 * h, 0.105 * h),
                         scale: SCNVector3(Float(profile.footWidth / 9.0) * 0.095 * h, 0.055 * h,
                                           Float(profile.footLength / 24.0) * 0.205 * h),
                         material: skin, to: root)
            addToes(side: side, ankle: ankle, widthFactor: Float(profile.footWidth / 9.0),
                    lengthFactor: Float(profile.footLength / 24.0), scale: h, material: skin, root: root)
        }

        let camera = SCNCamera()
        camera.fieldOfView = 38
        let cameraNode = SCNNode()
        cameraNode.camera = camera
        cameraNode.position = SCNVector3(0, 1.48 * h, 4.35 * h)
        cameraNode.look(at: SCNVector3(0, 1.40 * h, 0))
        root.addChildNode(cameraNode)

        let keyLight = SCNLight()
        keyLight.type = .directional
        keyLight.intensity = 850
        let keyNode = SCNNode()
        keyNode.light = keyLight
        keyNode.eulerAngles = SCNVector3(-0.75, 0.35, 0)
        root.addChildNode(keyNode)

        let fillLight = SCNLight()
        fillLight.type = .ambient
        fillLight.intensity = 260
        let fillNode = SCNNode()
        fillNode.light = fillLight
        root.addChildNode(fillNode)

        let floor = SCNFloor()
        floor.reflectivity = 0
        floor.firstMaterial?.diffuse.contents = UIColor(white: 0.93, alpha: 1)
        let floorNode = SCNNode(geometry: floor)
        floorNode.position.y = 0.04 * h
        root.addChildNode(floorNode)
        return scene
    }

    private static func makeTorsoSurface(
        rings: [TorsoRing],
        heightScale: Float,
        bustFactor: Float,
        glutealFactor: Float,
        material: SCNMaterial,
        radialSegments: Int,
        subdivisions: Int
    ) -> SCNNode {
        let smoothRings = interpolateRings(rings, subdivisions: subdivisions)
        var vertices: [SCNVector3] = []
        var indices: [Int32] = []

        for ring in smoothRings {
            for segment in 0..<radialSegments {
                let angle = Float(segment) / Float(radialSegments) * 2 * Float.pi
                let c = cos(angle)
                let s = sin(angle)
                let x = ring.radiusX * c
                var z = ring.centerZ + ring.radiusZ * s
                let localY = ring.y / max(heightScale, 0.001)

                // A soft front-facing displacement gives the chest a controllable volume
                // while keeping the front silhouette part of the same torso surface.
                if s > 0 {
                    for side: Float in [-1, 1] {
                        let dx = (x - side * 0.112 * heightScale) / (0.090 * heightScale)
                        let dy = (localY - 1.93) / 0.145
                        let falloff = exp(-0.5 * (dx * dx + dy * dy)) * pow(max(s, 0), 5)
                        z += 0.095 * heightScale * bustFactor * falloff
                    }
                }

                // Soft posterior gluteal landmarks, also displaced into the continuous surface.
                if s < 0 {
                    for side: Float in [-1, 1] {
                        let dx = (x - side * 0.145 * heightScale) / (0.125 * heightScale)
                        let dy = (localY - 1.045) / 0.155
                        let falloff = exp(-0.5 * (dx * dx + dy * dy)) * pow(max(-s, 0), 5)
                        z -= 0.075 * heightScale * glutealFactor * falloff
                    }
                }
                vertices.append(SCNVector3(x, ring.y, z))
            }
        }

        for row in 0..<(smoothRings.count - 1) {
            for segment in 0..<radialSegments {
                let next = (segment + 1) % radialSegments
                let a = Int32(row * radialSegments + segment)
                let b = Int32(row * radialSegments + next)
                let c = Int32((row + 1) * radialSegments + segment)
                let d = Int32((row + 1) * radialSegments + next)
                indices.append(contentsOf: [a, c, b, b, c, d])
            }
        }

        // Recalculate normals from the deformed triangles so the new contours shade smoothly.
        var normalSums = Array(repeating: SIMD3<Float>(repeating: 0), count: vertices.count)
        for offset in stride(from: 0, to: indices.count, by: 3) {
            let ia = Int(indices[offset])
            let ib = Int(indices[offset + 1])
            let ic = Int(indices[offset + 2])
            let a = SIMD3<Float>(vertices[ia].x, vertices[ia].y, vertices[ia].z)
            let b = SIMD3<Float>(vertices[ib].x, vertices[ib].y, vertices[ib].z)
            let c = SIMD3<Float>(vertices[ic].x, vertices[ic].y, vertices[ic].z)
            let normal = simd_cross(b - a, c - a)
            normalSums[ia] += normal
            normalSums[ib] += normal
            normalSums[ic] += normal
        }
        let normals = normalSums.map { value -> SCNVector3 in
            let normal = simd_length(value) > 0.00001 ? simd_normalize(value) : SIMD3<Float>(0, 1, 0)
            return SCNVector3(normal.x, normal.y, normal.z)
        }

        let geometry = SCNGeometry(
            sources: [SCNGeometrySource(vertices: vertices), SCNGeometrySource(normals: normals)],
            elements: [SCNGeometryElement(indices: indices, primitiveType: .triangles)]
        )
        geometry.firstMaterial = material
        geometry.firstMaterial?.isDoubleSided = true
        let node = SCNNode(geometry: geometry)
        node.name = "continuousFemaleTorso"
        return node
    }

    private static func interpolateRings(_ rings: [TorsoRing], subdivisions: Int) -> [TorsoRing] {
        guard rings.count >= 2 else { return rings }
        func catmull(_ p0: Float, _ p1: Float, _ p2: Float, _ p3: Float, _ t: Float) -> Float {
            let t2 = t * t
            let t3 = t2 * t
            return 0.5 * ((2 * p1) + (-p0 + p2) * t
                + (2 * p0 - 5 * p1 + 4 * p2 - p3) * t2
                + (-p0 + 3 * p1 - 3 * p2 + p3) * t3)
        }
        func sample(_ keyPath: KeyPath<TorsoRing, Float>, _ index: Int, _ t: Float) -> Float {
            let p0 = rings[max(index - 1, 0)][keyPath: keyPath]
            let p1 = rings[index][keyPath: keyPath]
            let p2 = rings[index + 1][keyPath: keyPath]
            let p3 = rings[min(index + 2, rings.count - 1)][keyPath: keyPath]
            return catmull(p0, p1, p2, p3, t)
        }
        var result: [TorsoRing] = []
        for index in 0..<(rings.count - 1) {
            for step in 0..<subdivisions {
                let t = Float(step) / Float(subdivisions)
                result.append(TorsoRing(
                    y: sample(\.y, index, t),
                    radiusX: max(sample(\.radiusX, index, t), 0.001),
                    radiusZ: max(sample(\.radiusZ, index, t), 0.001),
                    centerZ: sample(\.centerZ, index, t)
                ))
            }
        }
        if let last = rings.last { result.append(last) }
        return result
    }

    private static func addFingers(side: Float, wrist: SCNVector3, scale h: Float,
                                   material: SCNMaterial, root: SCNNode) {
        let fingerOffsets: [(String, Float, Float)] = [
            ("indexFinger", -0.043, 0.112),
            ("middleFinger", -0.014, 0.132),
            ("ringFinger", 0.016, 0.121),
            ("littleFinger", 0.044, 0.098)
        ]
        let handBaseY = wrist.y - 0.19 * h
        for (name, offset, length) in fingerOffsets {
            let start = SCNVector3(wrist.x + side * offset * h, handBaseY, wrist.z + 0.020 * h)
            let end = SCNVector3(wrist.x + side * (offset + (offset * 0.10)) * h,
                                 handBaseY - length * h, wrist.z + 0.030 * h)
            addTaperedSegment(name, from: start, to: end,
                              startRadius: 0.014 * CGFloat(h), endRadius: 0.010 * CGFloat(h),
                              material: material, root: root)
        }
        let thumbStart = SCNVector3(wrist.x + side * 0.052 * h, wrist.y - 0.075 * h, wrist.z + 0.015 * h)
        let thumbEnd = SCNVector3(wrist.x + side * 0.105 * h, wrist.y - 0.155 * h, wrist.z + 0.040 * h)
        addTaperedSegment("thumb", from: thumbStart, to: thumbEnd,
                          startRadius: 0.018 * CGFloat(h), endRadius: 0.012 * CGFloat(h),
                          material: material, root: root)
    }

    private static func addToes(side: Float, ankle: SCNVector3, widthFactor: Float, lengthFactor: Float,
                                scale h: Float, material: SCNMaterial, root: SCNNode) {
        let offsets: [Float] = [-0.060, -0.030, 0, 0.030, 0.058]
        for (index, offset) in offsets.enumerated() {
            let size = index == 4 ? 0.014 : 0.018
            addEllipsoid("toe\(index + 1)",
                         at: SCNVector3(ankle.x + side * offset * widthFactor * h,
                                        ankle.y - 0.045 * h, 0.255 * lengthFactor * h),
                         scale: SCNVector3(size * widthFactor * h, 0.023 * h, 0.052 * lengthFactor * h),
                         material: material, to: root)
        }
    }

    private static func addEllipsoid(_ name: String, at position: SCNVector3, scale: SCNVector3,
                                     material: SCNMaterial, to root: SCNNode) {
        let geometry = SCNSphere(radius: 1)
        geometry.segmentCount = 32
        geometry.ringCount = 24
        geometry.firstMaterial = material
        let node = SCNNode(geometry: geometry)
        node.name = name
        node.position = position
        node.scale = scale
        root.addChildNode(node)
    }

    private static func addTaperedSegment(_ name: String, from start: SCNVector3, to end: SCNVector3,
                                          startRadius: CGFloat, endRadius: CGFloat,
                                          material: SCNMaterial, root: SCNNode) {
        let a = SIMD3<Float>(start.x, start.y, start.z)
        let b = SIMD3<Float>(end.x, end.y, end.z)
        let delta = b - a
        let length = simd_length(delta)
        guard length > 0.001 else { return }
        let geometry = SCNCone(topRadius: endRadius, bottomRadius: startRadius, height: CGFloat(length))
        geometry.radialSegmentCount = 24
        geometry.firstMaterial = material
        let node = SCNNode(geometry: geometry)
        node.name = name
        node.position = SCNVector3((start.x + end.x) * 0.5,
                                   (start.y + end.y) * 0.5,
                                   (start.z + end.z) * 0.5)
        node.simdOrientation = simd_quatf(from: SIMD3<Float>(0, 1, 0), to: simd_normalize(delta))
        root.addChildNode(node)
        addEllipsoid("\(name)JointStart", at: start,
                     scale: SCNVector3(Float(startRadius), Float(startRadius), Float(startRadius)),
                     material: material, to: root)
        addEllipsoid("\(name)JointEnd", at: end,
                     scale: SCNVector3(Float(endRadius), Float(endRadius), Float(endRadius)),
                     material: material, to: root)
    }
}
