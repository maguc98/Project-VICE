import SceneKit
import UIKit

/// Female proportion-study scaffold. These separate primitive volumes are temporary;
/// the next modeling milestone replaces them with connected anatomical topology.
enum FigureSceneBuilder {
    static func makeScene(profile: BodyProfile) -> SCNScene {
        let scene = SCNScene()
        let root = scene.rootNode
        let unit = Float(profile.stature / 165.0)
        let skin = SCNMaterial()
        skin.diffuse.contents = UIColor(red: 0.78, green: 0.66, blue: 0.57, alpha: 1)
        skin.roughness.contents = 0.82
        skin.metalness.contents = 0.0

        func volume(_ name: String, _ position: SCNVector3, _ scale: SCNVector3) {
            let geometry = SCNSphere(radius: 0.5)
            geometry.segmentCount = 24
            geometry.firstMaterial = skin
            let node = SCNNode(geometry: geometry)
            node.name = name
            node.position = position
            node.scale = scale
            root.addChildNode(node)
        }

        let h = unit
        let shoulder = Float(profile.shoulderWidth / 38.0)
        let chest = Float(profile.chest / 86.0)
        let waist = Float(profile.waist / 68.0)
        let pelvis = Float(profile.pelvis / 94.0)

        volume("head", SCNVector3(0, 1.43 * h, 0),
               SCNVector3(0.24 * h, Float(profile.headHeight / 22.0) * 0.29 * h, 0.22 * h))
        volume("upperTorso", SCNVector3(0, 1.08 * h, 0),
               SCNVector3(0.25 * h * shoulder, 0.30 * h, 0.19 * h * chest))
        volume("waist", SCNVector3(0, 0.83 * h, 0),
               SCNVector3(0.19 * h * waist, 0.20 * h, 0.16 * h * waist))
        volume("pelvis", SCNVector3(0, 0.64 * h, 0),
               SCNVector3(0.30 * h * pelvis, 0.23 * h, 0.21 * h * pelvis))

        for side: Float in [-1, 1] {
            volume("upperArm", SCNVector3(side * 0.27 * h * shoulder, 1.02 * h, 0),
                   SCNVector3(0.105 * h, 0.27 * h, 0.11 * h))
            volume("forearm", SCNVector3(side * 0.30 * h, 0.75 * h, 0),
                   SCNVector3(0.085 * h, 0.25 * h, 0.09 * h))
            volume("hand", SCNVector3(side * 0.30 * h, 0.53 * h, 0),
                   SCNVector3(0.08 * h, 0.14 * h, 0.05 * h))
            volume("thigh", SCNVector3(side * 0.15 * h * pelvis, 0.34 * h, 0),
                   SCNVector3(0.145 * h, 0.31 * h, 0.15 * h))
            volume("lowerLeg", SCNVector3(side * 0.15 * h * pelvis, 0.07 * h, 0),
                   SCNVector3(0.095 * h, 0.28 * h, 0.10 * h))
            volume("foot", SCNVector3(side * 0.15 * h * pelvis, -0.15 * h, 0.09 * h),
                   SCNVector3(Float(profile.footWidth / 9.0) * 0.10 * h, 0.06 * h,
                              Float(profile.footLength / 24.0) * 0.20 * h))
        }

        let camera = SCNCamera()
        camera.fieldOfView = 38
        let cameraNode = SCNNode()
        cameraNode.camera = camera
        cameraNode.position = SCNVector3(0, 0.72 * h, 4.0 * h)
        cameraNode.look(at: SCNVector3(0, 0.68 * h, 0))
        root.addChildNode(cameraNode)

        let floor = SCNFloor()
        floor.reflectivity = 0
        floor.firstMaterial?.diffuse.contents = UIColor(white: 0.91, alpha: 1)
        let floorNode = SCNNode(geometry: floor)
        floorNode.position.y = -0.22
        root.addChildNode(floorNode)
        return scene
    }
}
