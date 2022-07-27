import Foundation

public extension HKFDomain {
    static var fitness: HKFDomain = .init(
            associatedTypes: [.steps, .distance, .basalEnergy, .activeEnergy]
    )

    static var cardio: HKFDomain = .init(
            associatedTypes: [.heartRate, .breathRate, .oxygenSaturation, .sdnn, .rri, .bloodPressureSystolic, .bloodPressureDiastolic]
    )

    static var meditation: HKFDomain = .init(
            associatedTypes: [.mindfulMinutes]
    )
}

public struct HKFDomain {
    public let associatedTypes: [HKFMetricType]

    public init(associatedTypes: [HKFMetricType]) {
        self.associatedTypes = associatedTypes
    }

    public func contains(_ type: HKFMetricType) -> Bool {
        self.associatedTypes.contains(type)
    }
}

extension HKFDomain: CustomStringConvertible {
    public var description: String {
        self.associatedTypes.map {$0.rawValue}.joined(separator: ",")
    }
}

