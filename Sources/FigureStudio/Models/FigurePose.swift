import Foundation

/// Editable, persistable pose for the female artist-reference figure.
struct FigurePose: Codable, Equatable {
    var armRaiseDegrees: Double = 0
    var elbowBendDegrees: Double = 0
    var leftHipFlexionDegrees: Double = 0
    var rightHipFlexionDegrees: Double = 0
    var leftHipAbductionDegrees: Double = 0
    var rightHipAbductionDegrees: Double = 0
    var leftKneeBendDegrees: Double = 0
    var rightKneeBendDegrees: Double = 0
    var leftAnkleFlexionDegrees: Double = 0
    var rightAnkleFlexionDegrees: Double = 0
}
