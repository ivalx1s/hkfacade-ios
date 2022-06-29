import Foundation

public enum HKDomain {
    case fitness
    case cardio
    case meditation

    var associatedTypes: [HKQuantityType] {
        switch self {
        case .fitness: return [.steps, .distance, .basalEnergy, .activeEnergy]
        case .cardio: return [.heartRate]
        case .meditation: return [.mindfulMinutes]
        }
    }

    func contains(_ type: HKQuantityType) -> Bool {
        self.associatedTypes.contains(type)
    }
}