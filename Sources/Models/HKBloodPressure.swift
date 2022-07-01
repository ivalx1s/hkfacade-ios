import Foundation

public struct HKBloodPressure: Equatable, Hashable {
    public let systolic: Double
    public let diastolic: Double

    public init(
            systolic: Double,
            diastolic: Double) {
        self.systolic = systolic
        self.diastolic = diastolic
    }
}