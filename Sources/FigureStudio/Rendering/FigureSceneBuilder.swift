import SceneKit
import UIKit
import simd

/// Builds the first continuous female torso surface plus tapered limb forms.
/// This is an anatomical blockout, not yet a production-quality scanned/topology model.
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

        let shadow = SCNMaterial()
        shadow.diffuse.contents = UIColor(red: 0.70, green: 0.57, blue: 0.50, alpha: 1)
        shadow.roughness.contents = 0.9

        let shoulderFactor = Float(profile.shoulderWidth / 38.0)
        let chestFactor = Float(profile.chest / 86.0)
        let waistFactor = Float(profile.waist / 68.0)
        let hipFactor = Float(profile.pelvis / 94.0)

        // One continuous ring-built torso surface, from lower pelvis to neck.
        let rings: [TorsoRing] = [
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
        root.addChildNode(makeLatheSurface(rings: rings.map {
            TorsoRing(y: $0.y * h, radiusX: $0.radiusX * h, radiusZ: $0.radiusZ * h, centerZ: $0.centerZ)
        }, material: skin, radialSegments: 48))

        // Head and neck are deliberately separate so the head can later receive facial landmarks.
        addEllipsoid("neck", at: SCNVector3(0, 2.43 * h, 0), scale: SCNVector3(0.105 * h, 0.19 * h, 0.105 * h), material: skin, to: root)
        addEllipsoid("head", at: SCNVector3(0, 2.78 * h, 0), scale: SCNVector3(0.205 * h, 0.285 * h, 0.185 * h), material: skin, to: root)

        // Arms: segment lengths are driven by the editable centimetre measurements.
        let upperArmLength = Float(profile.upperArm / 29.0) * 0.40 * h
        let forearmLength = Float(profile.forearm / 24.0) * 0.36 * h
        let armX = 0.285 * shoulderFactor * h
        for side: Float in [-1, 1] {
            let shoulder = SCNVector3(side * armX, 2.27 * h, 0)
            let elbow = SCNVector3(side * (armX + 0.035 * h), 2.27 * h - upperArmLength, 0.015 * h)
            let wrist = SCNVector3(side * (armX + 0.055 * h), elbow.y - forearmLength, 0.035 * h)
            addTaperedSegment("upperArm", from: shoulder, to: elbow, startRadius: 0.092 * h, endRadius: 0.070 * h, material: skin, root: root)
            addTaperedSegment("forearm", from: elbow, to: wrist, startRadius: 0.070 * h, endRadius: 0.045 * h, material: skin, root: root)
            addEllipsoid("hand", at: SCNVector3(wrist.x, wrist.y - 0.105 * h, wrist.z + 0.015 * h),
                         scale: SCNVector3(0.060 * h, Float(profile.handLength / 17.5) * 0.105 * h, 0.035 * h),
                         material: skin, to: root)
        }

        // Legs: separate tapered anatomical segments, positioned from the pelvis landmark.
        let thighLength = Float(profile.thigh / 43.0) * 0.53 * h
        let shinLength = Float(profile.lowerLeg / 39.0) * 0.49 * h
        for side: Float in [-1, 1] {
            let hip = SCNVector3(side * 0.175 * hipFactor * h, 1.08 * h, 0)
            let knee = SCNVector3(side * 0.16 * hipFactor * h, hip.y - thighLength, 0.015 * h)
            let ankle = SCNVector3(side * 0.16 * hipFactor * h, knee.y - shinLength, 0.025 * h)
            addTaperedSegment("thigh", from: hip, to: knee, startRadius: 0.145 * h, endRadius: 0.092 * h, material: skin, root: root)
            addTaperedSegment("lowerLeg", from: knee, to: ankle, startRadius: 0.082 * h, endRadius: 0.050 * h, material: skin, root: root)
            addEllipsoid("foot", at: SCNVector3(ankle.x, ankle.y - 0.045 * h, 0.105 * h),
                         scale: SCNVector3(Float(profile.footWidth / 9.0) * 0.095 * h, 0.055 * h,
                                           Float(profile.footLength / 24.0) * 0.205 * h),
                         material: skin, to: root)
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

    private static func makeLatheSurface(rings: [TorsoRing], material: SCNMaterial, radialSegments: Int) -> SCNNode {
        var vertices: [SCNVector3] = []
        var normals: [SCNVector3] = []
        var indices: [Int32] = []
        for ring in rings {
            for segment in 0..<radialSegments {
                let angle = Float(segment) / Float(radialSegments) * 2 * Float.pi
                let c = cos(angle)
                let s = sin(angle)
                vertices.append(SCNVector3(ring.radiusX * c, ring.y, ring.centerZ + ring.radiusZ * s))
                let normal = simd_normalize(SIMD3<Float>(c / max(ring.radiusX, 0.001), 0, s / max(ring.radiusZ, 0.001)))
                normals.append(SCNVector3(normal.x, normal.y, normal.z))
            }
        }
        for row in 0..<(rings.count - 1) {
            for segment in 0..<radialSegments {
                let next = (segment + 1) % radialSegments
                let a = Int32(row * radialSegments + segment)
                let b = Int32(row * radialSegments + next)
                let c = Int32((row + 1) * radialSegments + segment)
                let d = Int32((row + 1) * radialSegments + next)
                indices.append(contentsOf: [a, c, b, b, c, d])
            }
        }
        let vertexSource = SCNGeometrySource(vertices: vertices)
        let normalSource = SCNGeometrySource(normals: normals)
        let element = SCNGeometryElement(indices: indices, primitiveType: .triangles)
        let geometry = SCNGeometry(sources: [vertexSource, normalSource], elements: [element])
        geometry.firstMaterial = material
        geometry.firstMaterial?.isDoubleSided = true
        let node = SCNNode(geometry: geometry)
        node.name = "continuousFemaleTorso"
        return node
    }

    private static func addEllipsoid(_ name: String, at position: SCNVector3, scale: SCNVector3, material: SCNMaterial, to root: SCNNode) {
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
                                          startRadius: CGFloat, endRadius: CGFloat, material: SCNMaterial, root: SCNNode) {
        let a = SIMD3<Float>(start.x, start.y, start.z)
        let b = SIMD3<Float>(end.x, end.y, end.z)
        let delta = b - a
        let length = simd_length(delta)
        guard length > 0.001 else { return }
        let geometry = SCNCylinder(radius: startRadius, height: CGFloat(length))
        geometry.radialSegmentCount = 24
        geometry.firstMaterial = material
        let node = SCNNode(geometry: geometry)
        node.name = name
        node.position = SCNVector3((start.x + end.x) * 0.5, (start.y + end.y) * 0.5, (start.z + end.z) * 0.5)
        node.simdOrientation = simd_quatf(from: SIMD3<Float>(0, 1, 0), to: simd_normalize(delta))
        node.scale.x = Float(endRadius / max(startRadius, 0.001))
        node.scale.z = Float(endRadius / max(startRadius, 0.001))
        root.addChildNode(node)
    }
}
