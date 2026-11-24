import SceneKit
import UIKit

/// First-pass proportion study. Replace these primitive volumes with the anatomical
/// parametric surface in the next modeling milestone.
enum FigureSceneBuilder {
    static func makeScene(profile: BodyProfile) -> SCNScene {
        let scene = SCNScene()
        let root = scene.rootNode
        let unit = Float(profile.stature / 175.0)
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
        volume("head", SCNVector3(0, 1.52 * h, 0), SCNVector3(0.25 * h, 0.31 * h, 0.23 * h))
        volume("torso", SCNVector3(0, 1.13 * h, 0), SCNVector3(Float(profile.shoulderWidth / 175), 0.48 * h, 0.22 * h))
        volume("pelvis", SCNVector3(0, 0.78 * h, 0), SCNVector3(0.29 * h, 0.25 * h, 0.21 * h))
        for side: Float in [-1, 1] {
            volume("upperArm", SCNVector3(side * 0.27 * h, 1.12 * h, 0), SCNVector3(0.13 * h, 0.32 * h, 0.14 * h))
            volume("forearm", SCNVector3(side * 0.31 * h, 0.78 * h, 0), SCNVector3(0.10 * h, 0.29 * h, 0.11 * h))
            volume("hand", SCNVector3(side * 0.32 * h, 0.53 * h, 0), SCNVector3(0.10 * h, 0.16 * h, 0.055 * h))
            volume("thigh", SCNVector3(side * 0.15 * h, 0.43 * h, 0), SCNVector3(0.16 * h, 0.34 * h, 0.17 * h))
            volume("lowerLeg", SCNVector3(side * 0.15 * h, 0.13 * h, 0), SCNVector3(0.11 * h, 0.31 * h, 0.12 * h))
            volume("foot", SCNVector3(side * 0.15 * h, -0.04 * h, 0.10 * h), SCNVector3(0.12 * h, 0.07 * h, 0.24 * h))
        }

        let camera = SCNCamera()
        camera.fieldOfView = 38
        let cameraNode = SCNNode()
        cameraNode.camera = camera
        cameraNode.position = SCNVector3(0, 0.85 * h, 4.2 * h)
        cameraNode.look(at: SCNVector3(0, 0.78 * h, 0))
        root.addChildNode(cameraNode)

        let floor = SCNFloor()
        floor.reflectivity = 0
        floor.firstMaterial?.diffuse.contents = UIColor(white: 0.91, alpha: 1)
        let floorNode = SCNNode(geometry: floor)
        floorNode.position.y = -0.12
        root.addChildNode(floorNode)
        return scene
    }
}
