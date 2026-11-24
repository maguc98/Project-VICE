import Foundation

enum FigureRigMode: String, CaseIterable, Identifiable, Codable {
    case fk
    case ik

    var id: String { rawValue }
    var title: String { self == .fk ? "FK 关节控制" : "IK 目标控制" }
}

struct ArmPose: Codable, Equatable {
    var shoulderFlexionDegrees = 0.0
    var shoulderAbductionDegrees = 0.0
    var elbowFlexionDegrees = 0.0
    var forearmRotationDegrees = 0.0
    var wristFlexionDegrees = 0.0
    var wristDeviationDegrees = 0.0
    /// IK target offsets relative to the neutral wrist, in centimetres.
    var handReachTargetCM = 0.0
    var handLiftTargetCM = 0.0
    var handDepthTargetCM = 0.0
    /// Thumb, index, middle, ring, little finger; each value drives the finger joints.
    var fingerCurlDegrees = Array(repeating: 0.0, count: 5)

    init() {}

    private enum CodingKeys: String, CodingKey {
        case shoulderFlexionDegrees, shoulderAbductionDegrees, elbowFlexionDegrees
        case forearmRotationDegrees, wristFlexionDegrees, wristDeviationDegrees
        case handReachTargetCM, handLiftTargetCM, handDepthTargetCM, fingerCurlDegrees
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        shoulderFlexionDegrees = try c.decodeIfPresent(Double.self, forKey: .shoulderFlexionDegrees) ?? 0
        shoulderAbductionDegrees = try c.decodeIfPresent(Double.self, forKey: .shoulderAbductionDegrees) ?? 0
        elbowFlexionDegrees = try c.decodeIfPresent(Double.self, forKey: .elbowFlexionDegrees) ?? 0
        forearmRotationDegrees = try c.decodeIfPresent(Double.self, forKey: .forearmRotationDegrees) ?? 0
        wristFlexionDegrees = try c.decodeIfPresent(Double.self, forKey: .wristFlexionDegrees) ?? 0
        wristDeviationDegrees = try c.decodeIfPresent(Double.self, forKey: .wristDeviationDegrees) ?? 0
        handReachTargetCM = try c.decodeIfPresent(Double.self, forKey: .handReachTargetCM) ?? 0
        handLiftTargetCM = try c.decodeIfPresent(Double.self, forKey: .handLiftTargetCM) ?? 0
        handDepthTargetCM = try c.decodeIfPresent(Double.self, forKey: .handDepthTargetCM) ?? 0
        let decoded = try c.decodeIfPresent([Double].self, forKey: .fingerCurlDegrees) ?? []
        fingerCurlDegrees = Array((decoded + Array(repeating: 0, count: 5)).prefix(5))
    }
}

struct LegPose: Codable, Equatable {
    var hipFlexionDegrees = 0.0
    var hipAbductionDegrees = 0.0
    var hipRotationDegrees = 0.0
    var kneeFlexionDegrees = 0.0
    var ankleFlexionDegrees = 0.0
    var toeCurlDegrees = 0.0
    /// IK endpoint offsets relative to the neutral ankle, in centimetres.
    var footForwardTargetCM = 0.0
    var footLiftTargetCM = 0.0

    init() {}

    private enum CodingKeys: String, CodingKey {
        case hipFlexionDegrees, hipAbductionDegrees, hipRotationDegrees
        case kneeFlexionDegrees, ankleFlexionDegrees, toeCurlDegrees
        case footForwardTargetCM, footLiftTargetCM
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        hipFlexionDegrees = try c.decodeIfPresent(Double.self, forKey: .hipFlexionDegrees) ?? 0
        hipAbductionDegrees = try c.decodeIfPresent(Double.self, forKey: .hipAbductionDegrees) ?? 0
        hipRotationDegrees = try c.decodeIfPresent(Double.self, forKey: .hipRotationDegrees) ?? 0
        kneeFlexionDegrees = try c.decodeIfPresent(Double.self, forKey: .kneeFlexionDegrees) ?? 0
        ankleFlexionDegrees = try c.decodeIfPresent(Double.self, forKey: .ankleFlexionDegrees) ?? 0
        toeCurlDegrees = try c.decodeIfPresent(Double.self, forKey: .toeCurlDegrees) ?? 0
        footForwardTargetCM = try c.decodeIfPresent(Double.self, forKey: .footForwardTargetCM) ?? 0
        footLiftTargetCM = try c.decodeIfPresent(Double.self, forKey: .footLiftTargetCM) ?? 0
    }
}

struct FigurePose: Codable, Equatable {
    var leftArm = ArmPose()
    var rightArm = ArmPose()
    var leftLeg = LegPose()
    var rightLeg = LegPose()
    var spineFlexionDegrees = 0.0
    var spineSideBendDegrees = 0.0
    var spineRotationDegrees = 0.0
    var headTiltDegrees = 0.0
    var headRotationDegrees = 0.0
    var rigMode: FigureRigMode = .fk

    init() {}

    private enum CodingKeys: String, CodingKey {
        case leftArm, rightArm, leftLeg, rightLeg
        case spineFlexionDegrees, spineSideBendDegrees, spineRotationDegrees
        case headTiltDegrees, headRotationDegrees, rigMode
        // Legacy keys from the first pose format.
        case armRaiseDegrees, elbowBendDegrees
        case leftHipFlexionDegrees, rightHipFlexionDegrees
        case leftHipAbductionDegrees, rightHipAbductionDegrees
        case leftKneeBendDegrees, rightKneeBendDegrees
        case leftAnkleFlexionDegrees, rightAnkleFlexionDegrees
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        leftArm = try c.decodeIfPresent(ArmPose.self, forKey: .leftArm) ?? ArmPose()
        rightArm = try c.decodeIfPresent(ArmPose.self, forKey: .rightArm) ?? ArmPose()
        leftLeg = try c.decodeIfPresent(LegPose.self, forKey: .leftLeg) ?? LegPose()
        rightLeg = try c.decodeIfPresent(LegPose.self, forKey: .rightLeg) ?? LegPose()
        spineFlexionDegrees = try c.decodeIfPresent(Double.self, forKey: .spineFlexionDegrees) ?? 0
        spineSideBendDegrees = try c.decodeIfPresent(Double.self, forKey: .spineSideBendDegrees) ?? 0
        spineRotationDegrees = try c.decodeIfPresent(Double.self, forKey: .spineRotationDegrees) ?? 0
        headTiltDegrees = try c.decodeIfPresent(Double.self, forKey: .headTiltDegrees) ?? 0
        headRotationDegrees = try c.decodeIfPresent(Double.self, forKey: .headRotationDegrees) ?? 0
        rigMode = try c.decodeIfPresent(FigureRigMode.self, forKey: .rigMode) ?? .fk

        // Keep poses saved by earlier versions readable after this rig upgrade.
        if let oldRaise = try c.decodeIfPresent(Double.self, forKey: .armRaiseDegrees) {
            leftArm.shoulderAbductionDegrees = oldRaise
            rightArm.shoulderAbductionDegrees = oldRaise
        }
        if let oldElbow = try c.decodeIfPresent(Double.self, forKey: .elbowBendDegrees) {
            leftArm.elbowFlexionDegrees = oldElbow
            rightArm.elbowFlexionDegrees = oldElbow
        }
        leftLeg.hipFlexionDegrees = try c.decodeIfPresent(Double.self, forKey: .leftHipFlexionDegrees) ?? leftLeg.hipFlexionDegrees
        rightLeg.hipFlexionDegrees = try c.decodeIfPresent(Double.self, forKey: .rightHipFlexionDegrees) ?? rightLeg.hipFlexionDegrees
        leftLeg.hipAbductionDegrees = try c.decodeIfPresent(Double.self, forKey: .leftHipAbductionDegrees) ?? leftLeg.hipAbductionDegrees
        rightLeg.hipAbductionDegrees = try c.decodeIfPresent(Double.self, forKey: .rightHipAbductionDegrees) ?? rightLeg.hipAbductionDegrees
        leftLeg.kneeFlexionDegrees = try c.decodeIfPresent(Double.self, forKey: .leftKneeBendDegrees) ?? leftLeg.kneeFlexionDegrees
        rightLeg.kneeFlexionDegrees = try c.decodeIfPresent(Double.self, forKey: .rightKneeBendDegrees) ?? rightLeg.kneeFlexionDegrees
        leftLeg.ankleFlexionDegrees = try c.decodeIfPresent(Double.self, forKey: .leftAnkleFlexionDegrees) ?? leftLeg.ankleFlexionDegrees
        rightLeg.ankleFlexionDegrees = try c.decodeIfPresent(Double.self, forKey: .rightAnkleFlexionDegrees) ?? rightLeg.ankleFlexionDegrees
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(leftArm, forKey: .leftArm)
        try c.encode(rightArm, forKey: .rightArm)
        try c.encode(leftLeg, forKey: .leftLeg)
        try c.encode(rightLeg, forKey: .rightLeg)
        try c.encode(spineFlexionDegrees, forKey: .spineFlexionDegrees)
        try c.encode(spineSideBendDegrees, forKey: .spineSideBendDegrees)
        try c.encode(spineRotationDegrees, forKey: .spineRotationDegrees)
        try c.encode(headTiltDegrees, forKey: .headTiltDegrees)
        try c.encode(headRotationDegrees, forKey: .headRotationDegrees)
        try c.encode(rigMode, forKey: .rigMode)
    }

    func mirrored() -> FigurePose {
        var copy = self
        copy.leftArm = rightArm
        copy.rightArm = leftArm
        copy.leftLeg = rightLeg
        copy.rightLeg = leftLeg
        copy.leftArm.shoulderAbductionDegrees *= -1
        copy.rightArm.shoulderAbductionDegrees *= -1
        copy.leftArm.wristDeviationDegrees *= -1
        copy.rightArm.wristDeviationDegrees *= -1
        copy.leftLeg.hipAbductionDegrees *= -1
        copy.rightLeg.hipAbductionDegrees *= -1
        copy.spineSideBendDegrees *= -1
        copy.spineRotationDegrees *= -1
        return copy
    }

    static var natural: FigurePose { FigurePose() }

    static var aPose: FigurePose {
        var pose = FigurePose()
        pose.leftArm.shoulderAbductionDegrees = -32
        pose.rightArm.shoulderAbductionDegrees = 32
        return pose
    }

    static var walking: FigurePose {
        var pose = FigurePose()
        pose.leftLeg.hipFlexionDegrees = 24
        pose.leftLeg.kneeFlexionDegrees = 32
        pose.rightLeg.hipFlexionDegrees = -12
        pose.rightLeg.kneeFlexionDegrees = 8
        pose.leftArm.shoulderFlexionDegrees = -18
        pose.rightArm.shoulderFlexionDegrees = 18
        pose.leftArm.elbowFlexionDegrees = 24
        pose.rightArm.elbowFlexionDegrees = 24
        return pose
    }

    static var sitting: FigurePose {
        var pose = FigurePose()
        pose.leftLeg.hipFlexionDegrees = 82
        pose.rightLeg.hipFlexionDegrees = 82
        pose.leftLeg.kneeFlexionDegrees = 92
        pose.rightLeg.kneeFlexionDegrees = 92
        pose.spineFlexionDegrees = 7
        return pose
    }

    static var squat: FigurePose {
        var pose = FigurePose()
        pose.leftLeg.hipFlexionDegrees = 68
        pose.rightLeg.hipFlexionDegrees = 68
        pose.leftLeg.kneeFlexionDegrees = 102
        pose.rightLeg.kneeFlexionDegrees = 102
        pose.leftArm.shoulderFlexionDegrees = -35
        pose.rightArm.shoulderFlexionDegrees = -35
        pose.spineFlexionDegrees = 15
        return pose
    }
}

struct SavedFigurePose: Identifiable, Codable, Equatable {
    var id: UUID
    var name: String
    var pose: FigurePose
    var savedAt: Date

    init(id: UUID = UUID(), name: String, pose: FigurePose, savedAt: Date = Date()) {
        self.id = id
        self.name = name
        self.pose = pose
        self.savedAt = savedAt
    }
}
