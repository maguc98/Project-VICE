import Foundation

enum MeasurementSection: String, CaseIterable, Identifiable {
    case body, arms, legs, feet, pose
    var id: String { rawValue }
    var title: String {
        switch self {
        case .body: "躯干"
        case .arms: "手臂与手"
        case .legs: "腿部"
        case .feet: "足部"
        case .pose: "姿势"
        }
    }
}

struct MeasurementItem: Identifiable {
    let id: String
    let title: String
    let value: Double
    let range: ClosedRange<Double>
}

/// One female reference figure. Measurements are expressed in centimetres.
struct BodyProfile: Codable, Equatable {
    var stature = 165.0
    var headHeight = 22.0
    var shoulderWidth = 38.0
    var chest = 86.0
    var bustProjection = 9.0
    var waist = 68.0
    var pelvis = 94.0
    var glutealProjection = 10.0
    var upperArm = 29.0
    var forearm = 24.0
    var handLength = 17.5
    var thigh = 43.0
    var lowerLeg = 39.0
    var footLength = 24.0
    var footWidth = 9.0

    static let defaultProfile = BodyProfile()

    func measurements(for section: MeasurementSection) -> [MeasurementItem] {
        switch section {
        case .body:
            return [
                .init(id: "stature", title: "身高", value: stature, range: 140...210),
                .init(id: "headHeight", title: "头部高度", value: headHeight, range: 18...30),
                .init(id: "shoulderWidth", title: "肩宽", value: shoulderWidth, range: 30...60),
                .init(id: "chest", title: "胸围", value: chest, range: 65...130),
                .init(id: "bustProjection", title: "胸部突出度", value: bustProjection, range: 3...18),
                .init(id: "waist", title: "腰围", value: waist, range: 50...120),
                .init(id: "pelvis", title: "骨盆围", value: pelvis, range: 65...130),
                .init(id: "glutealProjection", title: "臀部突出度", value: glutealProjection, range: 4...18)
            ]
        case .arms:
            return [
                .init(id: "upperArm", title: "上臂长度", value: upperArm, range: 20...45),
                .init(id: "forearm", title: "前臂长度", value: forearm, range: 18...40),
                .init(id: "handLength", title: "手掌长度", value: handLength, range: 12...25)
            ]
        case .legs:
            return [
                .init(id: "thigh", title: "大腿长度", value: thigh, range: 30...65),
                .init(id: "lowerLeg", title: "小腿长度", value: lowerLeg, range: 28...60)
            ]
        case .feet:
            return [
                .init(id: "footLength", title: "脚长", value: footLength, range: 20...33),
                .init(id: "footWidth", title: "脚宽", value: footWidth, range: 7...14)
            ]
        case .pose:
            return []
        }
    }

    mutating func setMeasurement(_ key: String, value: Double) {
        switch key {
        case "stature": stature = value
        case "headHeight": headHeight = value
        case "shoulderWidth": shoulderWidth = value
        case "chest": chest = value
        case "bustProjection": bustProjection = value
        case "waist": waist = value
        case "pelvis": pelvis = value
        case "glutealProjection": glutealProjection = value
        case "upperArm": upperArm = value
        case "forearm": forearm = value
        case "handLength": handLength = value
        case "thigh": thigh = value
        case "lowerLeg": lowerLeg = value
        case "footLength": footLength = value
        case "footWidth": footWidth = value
        default: break
        }
    }
}
