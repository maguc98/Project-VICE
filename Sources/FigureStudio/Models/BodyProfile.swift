import Foundation

enum MeasurementSection: String, CaseIterable, Identifiable {
    case body, arms, legs, feet
    var id: String { rawValue }
    var title: String {
        switch self {
        case .body: "躯干"
        case .arms: "手臂与手"
        case .legs: "腿部"
        case .feet: "足部"
        }
    }
}

struct MeasurementItem: Identifiable {
    let id: String
    let title: String
    let value: Double
    let range: ClosedRange<Double>
}

struct BodyProfile: Codable {
    var stature = 175.0
    var headHeight = 23.0
    var shoulderWidth = 44.0
    var chest = 96.0
    var waist = 78.0
    var pelvis = 94.0
    var upperArm = 32.0
    var forearm = 26.0
    var handLength = 19.0
    var thigh = 48.0
    var lowerLeg = 43.0
    var footLength = 26.0
    var footWidth = 10.0

    static let defaultProfile = BodyProfile()

    func measurements(for section: MeasurementSection) -> [MeasurementItem] {
        switch section {
        case .body:
            return [
                .init(id: "stature", title: "身高", value: stature, range: 140...210),
                .init(id: "headHeight", title: "头部高度", value: headHeight, range: 18...30),
                .init(id: "shoulderWidth", title: "肩宽", value: shoulderWidth, range: 30...60),
                .init(id: "chest", title: "胸围", value: chest, range: 65...130),
                .init(id: "waist", title: "腰围", value: waist, range: 50...120),
                .init(id: "pelvis", title: "骨盆围", value: pelvis, range: 65...130)
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
        }
    }

    mutating func setMeasurement(_ key: String, value: Double) {
        switch key {
        case "stature": stature = value
        case "headHeight": headHeight = value
        case "shoulderWidth": shoulderWidth = value
        case "chest": chest = value
        case "waist": waist = value
        case "pelvis": pelvis = value
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
