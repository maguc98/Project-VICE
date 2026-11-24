import SceneKit
import UIKit
import simd
import Metal

enum FigureDisplayStyle: String, CaseIterable, Identifiable {
    case realistic, silhouette, wireframe, skeleton
    var id: String { rawValue }
    var title: String {
        switch self {
        case .realistic: "写实"
        case .silhouette: "剪影"
        case .wireframe: "线框"
        case .skeleton: "骨骼"
        }
    }
}

enum FigureLightingStyle: String, CaseIterable, Identifiable {
    case studio, soft, dramatic
    var id: String { rawValue }
    var title: String {
        switch self {
        case .studio: "影棚"
        case .soft: "柔光"
        case .dramatic: "戏剧光"
        }
    }
}

/// Procedural female artist-reference figure. This is a smooth anatomical study mesh,
/// not a scanned or medically validated human model.
enum FigureSceneBuilder {
    private struct TorsoRing {
        let y: Float
        let radiusX: Float
        let radiusZ: Float
        let centerZ: Float
    }

    static func makeScene(
        profile: BodyProfile,
        pose: FigurePose = FigurePose(),
        displayStyle: FigureDisplayStyle = .realistic,
        lightingStyle: FigureLightingStyle = .studio
    ) -> SCNScene {
        let scene = SCNScene()
        let root = scene.rootNode
        let h = Float(profile.stature / 165.0)
        let hipFactor = Float(profile.pelvis / 94.0)
        let shoulderFactor = Float(profile.shoulderWidth / 38.0)
        let chestFactor = Float(profile.chest / 86.0)
        let waistFactor = Float(profile.waist / 68.0)
        let bustFactor = Float(profile.bustProjection / 9.0)
        let glutealFactor = Float(profile.glutealProjection / 10.0)
        let pivotHeight = 1.05 * h

        let skin = makeSkinMaterial(style: displayStyle)
        let skinShadow = makeSkinShadowMaterial(style: displayStyle)
        let hair = SCNMaterial()
        hair.diffuse.contents = UIColor(red: 0.16, green: 0.12, blue: 0.11, alpha: 1)
        hair.roughness.contents = 0.82
        hair.lightingModel = .physicallyBased
        let eyeWhite = material(UIColor(red: 0.91, green: 0.89, blue: 0.84, alpha: 1), roughness: 0.28)
        let iris = material(UIColor(red: 0.22, green: 0.16, blue: 0.12, alpha: 1), roughness: 0.25)
        let feature = material(UIColor(red: 0.30, green: 0.19, blue: 0.17, alpha: 1), roughness: 0.72)

        // One continuous upper-body group provides a real spine pivot for posing.
        let upperBody = SCNNode()
        upperBody.name = "upperBodyPivot"
        upperBody.position.y = pivotHeight
        upperBody.eulerAngles = SCNVector3(
            -Float(pose.spineFlexionDegrees * .pi / 180),
            Float(pose.spineRotationDegrees * .pi / 180),
            -Float(pose.spineSideBendDegrees * .pi / 180)
        )
        root.addChildNode(upperBody)

        // Closely spaced cross-sections create smoother rib cage, waist and pelvic transitions.
        let baseRings: [TorsoRing] = [
            .init(y: 0.84, radiusX: 0.215 * hipFactor, radiusZ: 0.150 * hipFactor, centerZ: 0),
            .init(y: 0.91, radiusX: 0.255 * hipFactor, radiusZ: 0.170 * hipFactor, centerZ: 0),
            .init(y: 1.00, radiusX: 0.292 * hipFactor, radiusZ: 0.190 * hipFactor, centerZ: 0),
            .init(y: 1.11, radiusX: 0.320 * hipFactor, radiusZ: 0.195 * hipFactor, centerZ: 0),
            .init(y: 1.22, radiusX: 0.315 * hipFactor, radiusZ: 0.185 * hipFactor, centerZ: 0),
            .init(y: 1.33, radiusX: 0.286 * waistFactor, radiusZ: 0.167 * waistFactor, centerZ: 0),
            .init(y: 1.45, radiusX: 0.252 * waistFactor, radiusZ: 0.151 * waistFactor, centerZ: 0),
            .init(y: 1.57, radiusX: 0.238 * waistFactor, radiusZ: 0.150 * waistFactor, centerZ: 0),
            .init(y: 1.69, radiusX: 0.248 * chestFactor, radiusZ: 0.165 * chestFactor, centerZ: 0),
            .init(y: 1.81, radiusX: 0.275 * chestFactor, radiusZ: 0.177 * chestFactor, centerZ: 0),
            .init(y: 1.93, radiusX: 0.294 * chestFactor, radiusZ: 0.182 * chestFactor, centerZ: 0),
            .init(y: 2.04, radiusX: 0.292 * chestFactor, radiusZ: 0.174 * chestFactor, centerZ: 0),
            .init(y: 2.14, radiusX: 0.274 * shoulderFactor, radiusZ: 0.161 * chestFactor, centerZ: 0),
            .init(y: 2.22, radiusX: 0.252 * shoulderFactor, radiusZ: 0.145, centerZ: 0),
            .init(y: 2.30, radiusX: 0.207 * shoulderFactor, radiusZ: 0.125, centerZ: 0),
            .init(y: 2.40, radiusX: 0.120, radiusZ: 0.110, centerZ: 0),
            .init(y: 2.47, radiusX: 0.105, radiusZ: 0.100, centerZ: 0)
        ]
        let scaledRings = baseRings.map {
            TorsoRing(y: $0.y * h, radiusX: $0.radiusX * h,
                      radiusZ: $0.radiusZ * h, centerZ: $0.centerZ * h)
        }
        let torso = makeTorsoSurface(
            rings: scaledRings,
            heightScale: h,
            bustFactor: bustFactor,
            glutealFactor: glutealFactor,
            material: skin,
            radialSegments: 96,
            subdivisions: 8
        )
        torso.position.y = -pivotHeight
        upperBody.addChildNode(torso)

        // Neck and head share the torso pivot; facial landmarks provide a readable front view.
        addEllipsoid("neck", at: SCNVector3(0, 2.43 * h - pivotHeight, 0),
                     scale: SCNVector3(0.092 * h, 0.18 * h, 0.095 * h),
                     material: skin, to: upperBody)
        let headPivot = SCNNode()
        headPivot.name = "headPivot"
        headPivot.position = SCNVector3(0, 2.77 * h - pivotHeight, 0)
        headPivot.eulerAngles = SCNVector3(-Float(pose.headTiltDegrees * .pi / 180),
                                            Float(pose.headRotationDegrees * .pi / 180), 0)
        upperBody.addChildNode(headPivot)
        addEllipsoid("head", at: SCNVector3Zero,
                     scale: SCNVector3(0.190 * h, Float(profile.headHeight / 22.0) * 0.280 * h, 0.176 * h),
                     material: skin, to: headPivot)
        addEllipsoid("hairCap", at: SCNVector3(0, 0.108 * h, -0.006 * h),
                     scale: SCNVector3(0.194 * h, 0.174 * h, 0.180 * h), material: hair, to: headPivot)
        for side: Float in [-1, 1] {
            addEllipsoid("ear", at: SCNVector3(side * 0.184 * h, -0.006 * h, 0),
                         scale: SCNVector3(0.027 * h, 0.052 * h, 0.027 * h),
                         material: skin, to: headPivot)
            addEllipsoid("eyeWhite", at: SCNVector3(side * 0.067 * h, 0.025 * h, 0.151 * h),
                         scale: SCNVector3(0.030 * h, 0.014 * h, 0.012 * h),
                         material: eyeWhite, to: headPivot)
            addEllipsoid("iris", at: SCNVector3(side * 0.067 * h, 0.025 * h, 0.161 * h),
                         scale: SCNVector3(0.010 * h, 0.011 * h, 0.005 * h),
                         material: iris, to: headPivot)
            addEllipsoid("eyebrow", at: SCNVector3(side * 0.067 * h, 0.057 * h, 0.147 * h),
                         scale: SCNVector3(0.038 * h, 0.006 * h, 0.009 * h),
                         material: hair, to: headPivot)
        }
        addEllipsoid("noseBridge", at: SCNVector3(0, -0.006 * h, 0.157 * h),
                     scale: SCNVector3(0.017 * h, 0.047 * h, 0.020 * h),
                     material: skinShadow, to: headPivot)
        addEllipsoid("noseTip", at: SCNVector3(0, -0.035 * h, 0.174 * h),
                     scale: SCNVector3(0.024 * h, 0.016 * h, 0.023 * h),
                     material: skin, to: headPivot)
        addEllipsoid("mouth", at: SCNVector3(0, -0.083 * h, 0.160 * h),
                     scale: SCNVector3(0.043 * h, 0.008 * h, 0.008 * h),
                     material: feature, to: headPivot)

        // Bilateral arm rigs: clavicle/shoulder, elbow, pronation, wrist and five articulated digits.
        let upperArmLength = Float(profile.upperArm / 29.0) * 0.405 * h
        let forearmLength = Float(profile.forearm / 24.0) * 0.365 * h
        let armX = 0.282 * shoulderFactor * h
        for side: Float in [-1, 1] {
            let isLeft = side < 0
            let arm = isLeft ? pose.leftArm : pose.rightArm
            let shoulderPivot = SCNNode()
            shoulderPivot.name = isLeft ? "leftShoulderPivot" : "rightShoulderPivot"
            shoulderPivot.position = SCNVector3(side * armX, 2.265 * h - pivotHeight, 0)
            shoulderPivot.eulerAngles = SCNVector3(
                -Float(arm.shoulderFlexionDegrees * .pi / 180),
                Float(arm.forearmRotationDegrees * .pi / 180),
                side * Float(arm.shoulderAbductionDegrees * .pi / 180)
            )
            upperBody.addChildNode(shoulderPivot)

            addEllipsoid("deltoid", at: SCNVector3Zero,
                         scale: SCNVector3(0.112 * h, 0.132 * h, 0.116 * h), material: skin, to: shoulderPivot)
            let elbowLocal = SCNVector3(side * 0.035 * h, -upperArmLength, 0.010 * h)
            addAnatomicalLimb("upperArm", from: SCNVector3Zero, to: elbowLocal,
                              startRadius: 0.083 * h, endRadius: 0.064 * h,
                              depthRatio: 0.88, material: skin, root: shoulderPivot)

            let elbowPivot = SCNNode()
            elbowPivot.name = isLeft ? "leftElbowPivot" : "rightElbowPivot"
            elbowPivot.position = elbowLocal
            elbowPivot.eulerAngles.z = -side * Float(arm.elbowFlexionDegrees * .pi / 180)
            shoulderPivot.addChildNode(elbowPivot)
            addEllipsoid("elbowLandmark", at: SCNVector3Zero,
                         scale: SCNVector3(0.064 * h, 0.068 * h, 0.065 * h), material: skin, to: elbowPivot)

            let wristLocal = SCNVector3(side * 0.020 * h, -forearmLength, 0.012 * h)
            addAnatomicalLimb("forearm", from: SCNVector3Zero, to: wristLocal,
                              startRadius: 0.063 * h, endRadius: 0.040 * h,
                              depthRatio: 0.82, material: skin, root: elbowPivot)

            let wristPivot = SCNNode()
            wristPivot.name = isLeft ? "leftWristPivot" : "rightWristPivot"
            wristPivot.position = wristLocal
            wristPivot.eulerAngles = SCNVector3(
                -Float(arm.wristFlexionDegrees * .pi / 180),
                0,
                side * Float(arm.wristDeviationDegrees * .pi / 180)
            )
            elbowPivot.addChildNode(wristPivot)
            addEllipsoid("palm", at: SCNVector3(side * 0.006 * h, -0.075 * h, 0.016 * h),
                         scale: SCNVector3(0.056 * h, Float(profile.handLength / 17.5) * 0.086 * h, 0.033 * h),
                         material: skin, to: wristPivot)
            addArticulatedHand(side: side, scale: h, curls: arm.fingerCurlDegrees,
                               material: skin, root: wristPivot)
        }

        // Separate hip, knee and ankle pivots keep left/right legs independently editable.
        let thighLength = Float(profile.thigh / 43.0) * 0.535 * h
        let shinLength = Float(profile.lowerLeg / 39.0) * 0.495 * h
        for side: Float in [-1, 1] {
            let isLeft = side < 0
            let leg = isLeft ? pose.leftLeg : pose.rightLeg
            let solved = resolvedLegAngles(leg, mode: pose.rigMode,
                                           thighLength: thighLength, shinLength: shinLength)
            let hipPosition = SCNVector3(side * 0.174 * hipFactor * h, 1.085 * h, 0)
            let hipPivot = SCNNode()
            hipPivot.name = isLeft ? "leftHipPivot" : "rightHipPivot"
            hipPivot.position = hipPosition
            hipPivot.eulerAngles = SCNVector3(
                -solved.hipFlexion * .pi / 180,
                Float(leg.hipRotationDegrees * .pi / 180),
                side * Float(leg.hipAbductionDegrees * .pi / 180)
            )
            root.addChildNode(hipPivot)

            let kneeLocal = SCNVector3(-side * 0.015 * hipFactor * h, -thighLength, 0.012 * h)
            addAnatomicalLimb("thigh", from: SCNVector3Zero, to: kneeLocal,
                              startRadius: 0.137 * h, endRadius: 0.086 * h,
                              depthRatio: 0.91, material: skin, root: hipPivot)
            let kneePivot = SCNNode()
            kneePivot.name = isLeft ? "leftKneePivot" : "rightKneePivot"
            kneePivot.position = kneeLocal
            kneePivot.eulerAngles.x = solved.kneeFlexion * .pi / 180
            hipPivot.addChildNode(kneePivot)
            addEllipsoid("kneecap", at: SCNVector3Zero,
                         scale: SCNVector3(0.078 * h, 0.084 * h, 0.079 * h), material: skin, to: kneePivot)
            let ankleLocal = SCNVector3(0, -shinLength, 0.008 * h)
            addAnatomicalLimb("lowerLeg", from: SCNVector3Zero, to: ankleLocal,
                              startRadius: 0.079 * h, endRadius: 0.043 * h,
                              depthRatio: 0.86, material: skin, root: kneePivot)

            let anklePivot = SCNNode()
            anklePivot.name = isLeft ? "leftAnklePivot" : "rightAnklePivot"
            anklePivot.position = ankleLocal
            anklePivot.eulerAngles.x = -Float(leg.ankleFlexionDegrees * .pi / 180)
            kneePivot.addChildNode(anklePivot)
            addEllipsoid("ankleLandmark", at: SCNVector3Zero,
                         scale: SCNVector3(0.047 * h, 0.052 * h, 0.048 * h), material: skin, to: anklePivot)
            addEllipsoid("foot", at: SCNVector3(0, -0.038 * h, 0.102 * h),
                         scale: SCNVector3(Float(profile.footWidth / 9.0) * 0.090 * h,
                                           0.050 * h, Float(profile.footLength / 24.0) * 0.195 * h),
                         material: skin, to: anklePivot)
            addToes(side: side, ankle: SCNVector3Zero,
                    widthFactor: Float(profile.footWidth / 9.0),
                    lengthFactor: Float(profile.footLength / 24.0),
                    scale: h, curl: leg.toeCurlDegrees, material: skin, root: anklePivot)
        }

        if displayStyle == .skeleton {
            addSkeletonOverlay(root: root, scale: h, skinMaterial: skin)
        }

        // Keep all procedural anatomy in one container so the imported skinned model can replace it.
        let proceduralRoot = SCNNode()
        proceduralRoot.name = "proceduralFigureRoot"
        for child in Array(root.childNodes) {
            child.removeFromParentNode()
            proceduralRoot.addChildNode(child)
        }
        root.addChildNode(proceduralRoot)

        let camera = SCNCamera()
        camera.fieldOfView = 38
        camera.wantsHDR = true
        camera.bloomIntensity = 0.08
        let cameraNode = SCNNode()
        cameraNode.name = "figureCamera"
        cameraNode.camera = camera
        cameraNode.position = SCNVector3(0, 1.50 * h, 4.45 * h)
        cameraNode.look(at: SCNVector3(0, 1.43 * h, 0))
        root.addChildNode(cameraNode)
        scene.background.contents = UIColor(red: 0.94, green: 0.95, blue: 0.96, alpha: 1)

        let keyLight = SCNLight()
        keyLight.type = .directional
        keyLight.intensity = lightingStyle == .dramatic ? 1100 : (lightingStyle == .soft ? 560 : 850)
        keyLight.temperature = lightingStyle == .dramatic ? 4700 : 5600
        let keyNode = SCNNode()
        keyNode.light = keyLight
        keyNode.eulerAngles = SCNVector3(-0.75, 0.35, 0)
        root.addChildNode(keyNode)

        let fillLight = SCNLight()
        fillLight.type = .ambient
        fillLight.intensity = lightingStyle == .dramatic ? 100 : (lightingStyle == .soft ? 390 : 260)
        let fillNode = SCNNode()
        fillNode.light = fillLight
        root.addChildNode(fillNode)

        let floor = SCNFloor()
        floor.reflectivity = 0
        floor.firstMaterial?.diffuse.contents = UIColor(white: 0.93, alpha: 1)
        floor.firstMaterial?.roughness.contents = 0.95
        let floorNode = SCNNode(geometry: floor)
        floorNode.position.y = 0.035 * h
        root.addChildNode(floorNode)
        return scene
    }


    static func makeSnapshot(
        profile: BodyProfile,
        pose: FigurePose,
        displayStyle: FigureDisplayStyle,
        lightingStyle: FigureLightingStyle,
        width: Int,
        height: Int
    ) -> UIImage? {
        guard let device = MTLCreateSystemDefaultDevice() else { return nil }
        let scene = makeScene(profile: profile, pose: pose,
                              displayStyle: displayStyle, lightingStyle: lightingStyle)
        let renderer = SCNRenderer(device: device, options: nil)
        renderer.scene = scene
        renderer.pointOfView = scene.rootNode.childNode(withName: "figureCamera", recursively: false)
        return renderer.snapshot(
            atTime: 0,
            with: CGSize(width: width, height: height),
            antialiasingMode: .multisampling4X
        )
    }



    static func makeSnapshot(scene: SCNScene, width: Int, height: Int) -> UIImage? {
        guard let device = MTLCreateSystemDefaultDevice() else { return nil }
        let renderer = SCNRenderer(device: device, options: nil)
        renderer.scene = scene
        renderer.pointOfView = scene.rootNode.childNode(withName: "figureCamera", recursively: false)
        return renderer.snapshot(
            atTime: 0,
            with: CGSize(width: width, height: height),
            antialiasingMode: .multisampling4X
        )
    }

    /// Replaces the procedural blockout with the bundled, skinned female base mesh.
    /// Applies a repeatable artist camera preset. Orthographic views keep proportions measurable.
    static func applyCamera(_ preset: FigureCameraView, profile: BodyProfile, to view: SCNView) {
        guard let cameraNode = view.scene?.rootNode.childNode(
            withName: "figureCamera", recursively: true
        ), let camera = cameraNode.camera else { return }

        let height = Float(profile.stature / 100.0)
        let distance = max(height * 2.9, 2.6)
        let target = SCNVector3(0, height * 0.50, 0)
        let offset: SCNVector3
        switch preset {
        case .front:
            offset = SCNVector3(0, height * 0.025, distance)
        case .threeQuarter:
            offset = SCNVector3(distance * 0.58, height * 0.035, distance * 0.82)
        case .left:
            offset = SCNVector3(-distance, height * 0.025, 0)
        case .right:
            offset = SCNVector3(distance, height * 0.025, 0)
        case .back:
            offset = SCNVector3(0, height * 0.025, -distance)
        }

        cameraNode.position = SCNVector3(
            target.x + offset.x, target.y + offset.y, target.z + offset.z
        )
        cameraNode.look(at: target)
        camera.usesOrthographicProjection = preset != .threeQuarter
        camera.orthographicScale = CGFloat(height * 1.13)
        camera.zNear = 0.01
        camera.zFar = 100
        view.pointOfView = cameraNode
    }

    static func updateRealisticBaseMesh(_ modelRoot: SCNNode, profile: BodyProfile) {
        // Cache the bind-pose bounds once. Bone scaling during profile edits can
        // otherwise change boundingBox and feed the previous edit back into the next.
        let boundsKey = "figureStudio.bindPoseBounds"
        let cachedBounds = modelRoot.figureStudioMetadata?[boundsKey] as? [NSNumber]
        let minimum: SCNVector3
        let maximum: SCNVector3
        if let cachedBounds, cachedBounds.count == 6 {
            minimum = SCNVector3(cachedBounds[0].floatValue,
                                 cachedBounds[1].floatValue,
                                 cachedBounds[2].floatValue)
            maximum = SCNVector3(cachedBounds[3].floatValue,
                                 cachedBounds[4].floatValue,
                                 cachedBounds[5].floatValue)
        } else {
            let bounds = modelRoot.boundingBox
            minimum = bounds.min
            maximum = bounds.max
        }

        let coordinates = [minimum.x, minimum.y, minimum.z,
                           maximum.x, maximum.y, maximum.z]
        let sourceHeight = maximum.y - minimum.y
        guard coordinates.allSatisfy(\.isFinite), sourceHeight.isFinite, sourceHeight > 0.1 else {
            NSLog("Figure Studio: invalid model bounds; skipping automatic stature scaling.")
            return
        }

        if cachedBounds == nil || cachedBounds?.count != 6 {
            let userData = modelRoot.figureStudioMetadata ?? NSMutableDictionary()
            userData.setObject([
                NSNumber(value: minimum.x), NSNumber(value: minimum.y), NSNumber(value: minimum.z),
                NSNumber(value: maximum.x), NSNumber(value: maximum.y), NSNumber(value: maximum.z)
            ], forKey: boundsKey as NSString)
            modelRoot.figureStudioMetadata = userData
        }

        let statureScale = Float(profile.stature / 100.0) / sourceHeight
        let shoulderFactor = Float(profile.shoulderWidth / 38.0)
        let pelvisFactor = Float(profile.pelvis / 94.0)
        let chestFactor = Float(profile.chest / 86.0)
        let waistFactor = Float(profile.waist / 68.0)
        let widthScale = 1 + ((shoulderFactor + pelvisFactor) * 0.5 - 1) * 0.55
        let depthScale = 1 + ((chestFactor + waistFactor) * 0.5 - 1) * 0.35
        modelRoot.scale = SCNVector3(statureScale * widthScale, statureScale, statureScale * depthScale)
        modelRoot.position = SCNVector3(-minimum.x * statureScale * widthScale,
                                        -minimum.y * statureScale,
                                        -minimum.z * statureScale * depthScale)
    }

    static func attachRealisticBaseMesh(
        _ modelRoot: SCNNode,
        to scene: SCNScene,
        profile: BodyProfile,
        displayStyle: FigureDisplayStyle
    ) {
        var geometryCount = modelRoot.geometry == nil ? 0 : 1
        modelRoot.enumerateChildNodes { node, _ in
            if node.geometry != nil { geometryCount += 1 }
        }
        guard geometryCount > 0 else {
            NSLog("Figure Studio: refusing to attach an empty realistic model; keeping procedural fallback visible.")
            return
        }

        scene.rootNode.childNode(withName: "realisticFemaleMeshRoot", recursively: false)?.removeFromParentNode()
        scene.rootNode.childNode(withName: "proceduralFigureRoot", recursively: false)?.removeFromParentNode()

        modelRoot.name = "realisticFemaleMeshRoot"
        updateRealisticBaseMesh(modelRoot, profile: profile)

        modelRoot.enumerateChildNodes { node, _ in
            guard let source = node.geometry else { return }
            let geometry = source.copy() as! SCNGeometry

            // Keep an untouched copy of imported materials. Display modes are rebuilt
            // from this cache so silhouette/wireframe tinting cannot leak into realism.
            let originalMaterialsKey = "figureStudio.originalMaterials"
            let originalMaterials: [SCNMaterial]
            if let cached = node.figureStudioMetadata?[originalMaterialsKey] as? [SCNMaterial] {
                originalMaterials = cached
            } else {
                originalMaterials = source.materials.map { $0.copy() as! SCNMaterial }
                let userData = node.figureStudioMetadata ?? NSMutableDictionary()
                userData.setObject(originalMaterials, forKey: originalMaterialsKey as NSString)
                node.figureStudioMetadata = userData
            }

            geometry.materials = originalMaterials.map { sourceMaterial in
                let material = sourceMaterial.copy() as! SCNMaterial
                switch displayStyle {
                case .realistic:
                    // Preserve source texture maps and use a gentle warm tint instead of
                    // flattening skin, eyes and fine facial materials into one colour.
                    material.lightingModel = .physicallyBased
                    material.multiply.contents = UIColor(red: 1.0, green: 0.94, blue: 0.88, alpha: 1)
                    material.roughness.contents = 0.62
                    material.metalness.contents = 0
                    material.specular.contents = UIColor(white: 0.24, alpha: 1)
                    material.fillMode = .fill
                    material.transparency = 1
                case .silhouette:
                    material.lightingModel = .constant
                    material.diffuse.contents = UIColor(white: 0.025, alpha: 1)
                    material.roughness.contents = 1
                    material.fillMode = .fill
                    material.transparency = 1
                case .wireframe:
                    material.lightingModel = .constant
                    material.diffuse.contents = UIColor(red: 0.20, green: 0.38, blue: 0.50, alpha: 1)
                    material.fillMode = .lines
                    material.transparency = 1
                case .skeleton:
                    material.lightingModel = .physicallyBased
                    material.diffuse.contents = UIColor(red: 0.64, green: 0.70, blue: 0.73, alpha: 1)
                    material.transparency = 0.23
                    material.fillMode = .fill
                }
                return material
            }
            node.geometry = geometry
        }
        scene.rootNode.addChildNode(modelRoot)

        // Reframe the camera for a real 1.65 m figure rather than the taller procedural blockout.
        if let camera = scene.rootNode.childNode(withName: "figureCamera", recursively: false) {
            camera.position = SCNVector3(0, Float(profile.stature / 100.0) * 0.53,
                                         Float(profile.stature / 100.0) * 2.75)
            camera.look(at: SCNVector3(0, Float(profile.stature / 100.0) * 0.49, 0))
        }
    }

    /// Applies pose deltas to the existing rig. Geometry is rebuilt only when proportions or display change.
    static func apply(pose: FigurePose, to scene: SCNScene, profile: BodyProfile) {
        let h = Float(profile.stature / 165.0)
        func node(_ name: String) -> SCNNode? { scene.rootNode.childNode(withName: name, recursively: true) }

        if let upperBody = node("upperBodyPivot") {
            upperBody.eulerAngles = SCNVector3(
                -Float(pose.spineFlexionDegrees * .pi / 180),
                Float(pose.spineRotationDegrees * .pi / 180),
                -Float(pose.spineSideBendDegrees * .pi / 180)
            )
        }
        if let head = node("headPivot") {
            head.eulerAngles = SCNVector3(-Float(pose.headTiltDegrees * .pi / 180),
                                           Float(pose.headRotationDegrees * .pi / 180), 0)
        }

        for side: Float in [-1, 1] {
            let prefix = side < 0 ? "left" : "right"
            let arm = side < 0 ? pose.leftArm : pose.rightArm
            if let shoulder = node("\(prefix)ShoulderPivot") {
                shoulder.eulerAngles = SCNVector3(
                    -Float(arm.shoulderFlexionDegrees * .pi / 180),
                    Float(arm.forearmRotationDegrees * .pi / 180),
                    side * Float(arm.shoulderAbductionDegrees * .pi / 180)
                )
            }
            if let elbow = node("\(prefix)ElbowPivot") {
                elbow.eulerAngles.z = -side * Float(arm.elbowFlexionDegrees * .pi / 180)
            }
            if let wrist = node("\(prefix)WristPivot") {
                wrist.eulerAngles = SCNVector3(
                    -Float(arm.wristFlexionDegrees * .pi / 180), 0,
                    side * Float(arm.wristDeviationDegrees * .pi / 180)
                )
            }
            let fingerNames = ["Thumb", "Index", "Middle", "Ring", "Little"]
            for (index, name) in fingerNames.enumerated() {
                let curl = Float((index < arm.fingerCurlDegrees.count ? arm.fingerCurlDegrees[index] : 0) * .pi / 180)
                for joint in ["MCP", "PIP", "DIP"] {
                    if let pivot = node("\(prefix)\(name)\(joint)") {
                        let factor: Float = joint == "MCP" ? 0.72 : (joint == "PIP" ? 0.82 : 0.55)
                        pivot.eulerAngles.x = -curl * factor
                    }
                }
            }

            let leg = side < 0 ? pose.leftLeg : pose.rightLeg
            let thighLength = Float(profile.thigh / 43.0) * 0.535 * h
            let shinLength = Float(profile.lowerLeg / 39.0) * 0.495 * h
            let solved = resolvedLegAngles(leg, mode: pose.rigMode,
                                           thighLength: thighLength, shinLength: shinLength)
            if let hip = node("\(prefix)HipPivot") {
                hip.eulerAngles = SCNVector3(
                    -solved.hipFlexion * .pi / 180,
                    Float(leg.hipRotationDegrees * .pi / 180),
                    side * Float(leg.hipAbductionDegrees * .pi / 180)
                )
            }
            if let knee = node("\(prefix)KneePivot") {
                knee.eulerAngles.x = solved.kneeFlexion * .pi / 180
            }
            if let ankle = node("\(prefix)AnklePivot") {
                ankle.eulerAngles.x = -Float(leg.ankleFlexionDegrees * .pi / 180)
            }
            if let toes = node("\(prefix)ToesPivot") {
                toes.eulerAngles.x = -Float(leg.toeCurlDegrees * .pi / 180)
            }
        }
    }

    private static func resolvedLegAngles(
        _ leg: LegPose,
        mode: FigureRigMode,
        thighLength: Float,
        shinLength: Float
    ) -> (hipFlexion: Float, kneeFlexion: Float) {
        guard mode == .ik else {
            return (Float(leg.hipFlexionDegrees), Float(leg.kneeFlexionDegrees))
        }
        let forward = Float(leg.footForwardTargetCM / 100)
        let down = max(0.08, thighLength + shinLength - Float(leg.footLiftTargetCM / 100))
        let rawDistance = sqrt(forward * forward + down * down)
        let minimum = abs(thighLength - shinLength) + 0.001
        let maximum = thighLength + shinLength - 0.001
        let distance = min(max(rawDistance, minimum), maximum)
        let cosineKnee = min(max((thighLength * thighLength + shinLength * shinLength - distance * distance)
                                 / (2 * thighLength * shinLength), -1), 1)
        let internalKnee = acos(cosineKnee)
        let knee = Float.pi - internalKnee
        let cosineHip = min(max((thighLength * thighLength + distance * distance - shinLength * shinLength)
                                / (2 * thighLength * distance), -1), 1)
        let hipOffset = acos(cosineHip)
        let targetAngle = atan2(forward, down)
        return ((targetAngle + hipOffset) * 180 / .pi, knee * 180 / .pi)
    }

    private static func makeSkinMaterial(style: FigureDisplayStyle) -> SCNMaterial {
        let skin = SCNMaterial()
        skin.diffuse.contents = style == .silhouette
            ? UIColor(white: 0.035, alpha: 1)
            : UIColor(red: 0.78, green: 0.64, blue: 0.55, alpha: 1)
        skin.roughness.contents = style == .silhouette ? 1.0 : 0.58
        skin.metalness.contents = 0
        skin.specular.contents = style == .silhouette ? UIColor.black : UIColor(white: 0.22, alpha: 1)
        skin.lightingModel = style == .silhouette ? .constant : .physicallyBased
        skin.isDoubleSided = true
        if style == .wireframe { skin.fillMode = .lines }
        if style == .skeleton { skin.transparency = 0.28 }
        return skin
    }

    private static func makeSkinShadowMaterial(style: FigureDisplayStyle) -> SCNMaterial {
        material(style == .silhouette ? UIColor.black : UIColor(red: 0.68, green: 0.49, blue: 0.43, alpha: 1),
                 roughness: 0.68)
    }

    private static func material(_ color: UIColor, roughness: CGFloat) -> SCNMaterial {
        let result = SCNMaterial()
        result.diffuse.contents = color
        result.roughness.contents = roughness
        result.lightingModel = .physicallyBased
        return result
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

                if s > 0 {
                    for side: Float in [-1, 1] {
                        let dx = (x - side * 0.112 * heightScale) / (0.094 * heightScale)
                        let dy = (localY - 1.92) / 0.165
                        let falloff = exp(-0.5 * (dx * dx + dy * dy)) * pow(max(s, 0), 5)
                        z += 0.090 * heightScale * bustFactor * falloff
                    }
                }
                if s < 0 {
                    for side: Float in [-1, 1] {
                        let dx = (x - side * 0.145 * heightScale) / (0.132 * heightScale)
                        let dy = (localY - 1.06) / 0.165
                        let falloff = exp(-0.5 * (dx * dx + dy * dy)) * pow(max(-s, 0), 5)
                        z -= 0.072 * heightScale * glutealFactor * falloff
                    }
                }
                // A subtle abdominal plane avoids a perfectly cylindrical front torso.
                if s > 0.75 {
                    let abdomenY = exp(-pow((localY - 1.48) / 0.22, 2))
                    z += 0.008 * heightScale * abdomenY * (s - 0.75) * 4
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

    private static func addAnatomicalLimb(
        _ name: String,
        from start: SCNVector3,
        to end: SCNVector3,
        startRadius: Float,
        endRadius: Float,
        depthRatio: Float,
        material: SCNMaterial,
        root: SCNNode
    ) {
        let a = SIMD3<Float>(start.x, start.y, start.z)
        let b = SIMD3<Float>(end.x, end.y, end.z)
        let delta = b - a
        let length = simd_length(delta)
        guard length > 0.001 else { return }
        let orientation = simd_quatf(from: SIMD3<Float>(0, 1, 0), to: simd_normalize(delta))
        let radialSegments = 24
        let axialSegments = 14
        var vertices: [SCNVector3] = []
        var indices: [Int32] = []
        let bulge = max(startRadius, endRadius) * 0.19

        for row in 0...axialSegments {
            let t = Float(row) / Float(axialSegments)
            let taper = startRadius * (1 - t) + endRadius * t
            let cap = 0.84 + 0.16 * sin(Float.pi * t)
            let radius = (taper + bulge * sin(Float.pi * t)) * cap
            for segment in 0..<radialSegments {
                let angle = Float(segment) / Float(radialSegments) * 2 * Float.pi
                let local = SIMD3<Float>(cos(angle) * radius, (t - 0.5) * length,
                                         sin(angle) * radius * depthRatio)
                let rotated = simd_act(orientation, local)
                vertices.append(SCNVector3(rotated.x, rotated.y, rotated.z))
            }
        }
        for row in 0..<axialSegments {
            for segment in 0..<radialSegments {
                let next = (segment + 1) % radialSegments
                let i0 = Int32(row * radialSegments + segment)
                let i1 = Int32(row * radialSegments + next)
                let i2 = Int32((row + 1) * radialSegments + segment)
                let i3 = Int32((row + 1) * radialSegments + next)
                indices.append(contentsOf: [i0, i2, i1, i1, i2, i3])
            }
        }
        var sums = Array(repeating: SIMD3<Float>(repeating: 0), count: vertices.count)
        for offset in stride(from: 0, to: indices.count, by: 3) {
            let ia = Int(indices[offset]), ib = Int(indices[offset + 1]), ic = Int(indices[offset + 2])
            let va = SIMD3<Float>(vertices[ia].x, vertices[ia].y, vertices[ia].z)
            let vb = SIMD3<Float>(vertices[ib].x, vertices[ib].y, vertices[ib].z)
            let vc = SIMD3<Float>(vertices[ic].x, vertices[ic].y, vertices[ic].z)
            let normal = simd_cross(vb - va, vc - va)
            sums[ia] += normal; sums[ib] += normal; sums[ic] += normal
        }
        let normals = sums.map { v -> SCNVector3 in
            let n = simd_length(v) > 0.00001 ? simd_normalize(v) : SIMD3<Float>(0, 1, 0)
            return SCNVector3(n.x, n.y, n.z)
        }
        let geometry = SCNGeometry(
            sources: [SCNGeometrySource(vertices: vertices), SCNGeometrySource(normals: normals)],
            elements: [SCNGeometryElement(indices: indices, primitiveType: .triangles)]
        )
        geometry.firstMaterial = material
        let node = SCNNode(geometry: geometry)
        node.name = name
        node.position = SCNVector3((start.x + end.x) * 0.5,
                                   (start.y + end.y) * 0.5,
                                   (start.z + end.z) * 0.5)
        root.addChildNode(node)
        addEllipsoid("\(name)ProximalBlend", at: start,
                     scale: SCNVector3(startRadius * 0.96, startRadius * 0.96, startRadius * depthRatio),
                     material: material, to: root)
        addEllipsoid("\(name)DistalBlend", at: end,
                     scale: SCNVector3(endRadius * 0.92, endRadius * 0.92, endRadius * depthRatio),
                     material: material, to: root)
    }

    private static func addArticulatedHand(
        side: Float,
        scale h: Float,
        curls: [Double],
        material: SCNMaterial,
        root: SCNNode
    ) {
        let prefix = side < 0 ? "left" : "right"
        let definitions: [(String, Float, Float)] = [
            ("Thumb", 0.047, 0.075),
            ("Index", 0.030, 0.104),
            ("Middle", 0.010, 0.116),
            ("Ring", -0.012, 0.108),
            ("Little", -0.033, 0.088)
        ]
        let widths: [Float] = [0.010, 0.009, 0.0095, 0.009, 0.008]
        for (index, definition) in definitions.enumerated() {
            let (digit, offset, length) = definition
            let base = SCNNode()
            base.name = "\(prefix)\(digit)MCP"
            base.position = SCNVector3(side * offset * h, -0.125 * h, 0.028 * h)
            base.eulerAngles.x = -Float((index < curls.count ? curls[index] : 0) * 0.72 * .pi / 180)
            root.addChildNode(base)

            let proximalEnd: SCNVector3
            if digit == "Thumb" {
                proximalEnd = SCNVector3(side * 0.026 * h, -0.026 * h, 0.008 * h)
            } else {
                proximalEnd = SCNVector3(side * (offset * 0.08) * h, -length * 0.42 * h, 0)
            }
            addAnatomicalLimb("\(prefix)\(digit)Proximal", from: SCNVector3Zero, to: proximalEnd,
                              startRadius: widths[index] * h, endRadius: widths[index] * 0.78 * h,
                              depthRatio: 0.86, material: material, root: base)

            let pip = SCNNode()
            pip.name = "\(prefix)\(digit)PIP"
            pip.position = proximalEnd
            pip.eulerAngles.x = -Float((index < curls.count ? curls[index] : 0) * 0.82 * .pi / 180)
            base.addChildNode(pip)
            let middleEnd = SCNVector3(proximalEnd.x * 0.35, -length * 0.34 * h, 0)
            addAnatomicalLimb("\(prefix)\(digit)Middle", from: SCNVector3Zero, to: middleEnd,
                              startRadius: widths[index] * 0.78 * h, endRadius: widths[index] * 0.64 * h,
                              depthRatio: 0.82, material: material, root: pip)

            let dip = SCNNode()
            dip.name = "\(prefix)\(digit)DIP"
            dip.position = middleEnd
            dip.eulerAngles.x = -Float((index < curls.count ? curls[index] : 0) * 0.55 * .pi / 180)
            pip.addChildNode(dip)
            let distalEnd = SCNVector3(proximalEnd.x * 0.18, -length * 0.24 * h, 0)
            addAnatomicalLimb("\(prefix)\(digit)Distal", from: SCNVector3Zero, to: distalEnd,
                              startRadius: widths[index] * 0.64 * h, endRadius: widths[index] * 0.42 * h,
                              depthRatio: 0.78, material: material, root: dip)
        }
    }

    private static func addToes(
        side: Float,
        ankle: SCNVector3,
        widthFactor: Float,
        lengthFactor: Float,
        scale h: Float,
        curl: Double,
        material: SCNMaterial,
        root: SCNNode
    ) {
        let prefix = side < 0 ? "left" : "right"
        let pivot = SCNNode()
        pivot.name = "\(prefix)ToesPivot"
        pivot.eulerAngles.x = -Float(curl * .pi / 180)
        root.addChildNode(pivot)
        let offsets: [Float] = [-0.060, -0.030, 0, 0.030, 0.058]
        for (index, offset) in offsets.enumerated() {
            let size: Float = index == 4 ? 0.013 : 0.017
            addEllipsoid("toe\(index + 1)",
                         at: SCNVector3(ankle.x + side * offset * widthFactor * h,
                                        ankle.y - 0.038 * h, 0.235 * lengthFactor * h),
                         scale: SCNVector3(size * widthFactor * h, 0.020 * h, 0.048 * lengthFactor * h),
                         material: material, to: pivot)
        }
    }

    private static func addSkeletonOverlay(root: SCNNode, scale h: Float, skinMaterial: SCNMaterial) {
        let bone = material(UIColor(red: 0.22, green: 0.48, blue: 0.66, alpha: 1), roughness: 0.86)
        bone.transparency = 0.95
        let points: [(String, SCNVector3, SCNVector3, Float)] = [
            ("spine", SCNVector3(0, 0.92*h, 0), SCNVector3(0, 2.34*h, 0), 0.018*h),
            ("leftClavicle", SCNVector3(0, 2.20*h, 0), SCNVector3(-0.28*h, 2.25*h, 0), 0.014*h),
            ("rightClavicle", SCNVector3(0, 2.20*h, 0), SCNVector3(0.28*h, 2.25*h, 0), 0.014*h),
            ("leftFemur", SCNVector3(-0.17*h, 1.08*h, 0), SCNVector3(-0.19*h, 0.55*h, 0), 0.025*h),
            ("rightFemur", SCNVector3(0.17*h, 1.08*h, 0), SCNVector3(0.19*h, 0.55*h, 0), 0.025*h)
        ]
        for (name, start, end, radius) in points {
            addAnatomicalLimb(name, from: start, to: end, startRadius: radius,
                              endRadius: radius * 0.82, depthRatio: 0.9,
                              material: bone, root: root)
        }
    }

    private static func addEllipsoid(
        _ name: String,
        at position: SCNVector3,
        scale: SCNVector3,
        material: SCNMaterial,
        to root: SCNNode
    ) {
        let geometry = SCNSphere(radius: 1)
        geometry.segmentCount = 40
        geometry.firstMaterial = material
        let node = SCNNode(geometry: geometry)
        node.name = name
        node.position = position
        node.scale = scale
        root.addChildNode(node)
    }
}
