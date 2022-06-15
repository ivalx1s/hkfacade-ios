import Foundation

public enum HKDomain {
    case fitness
    case cardio

    var associatedTypes: [HKQuantityType] {
        switch self {
        case .fitness: return [.steps, .distance, .basalEnergy, .activeEnergy]
        case .cardio: return [.heartRate]
        }
    }

    func contains(_ type: HKQuantityType) -> Bool {
        self.associatedTypes.contains(type)
    }
}