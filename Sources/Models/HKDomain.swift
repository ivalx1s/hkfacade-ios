import Foundation

public enum HKDomain {
    case fitness
    case cardio
    case meditation

    var associatedTypes: [HKSampleType] {
        switch self {
        case .fitness: return [
            .steps,
            .distance,
            .basalEnergy,
            .activeEnergy
        ]

        case .cardio: return [
            .heartRate,
            .breathRate,
            .oxygenSaturation,
            .bloodPressureSystolic,
            .bloodPressureDiastolic,
            .sdnn,
            .rri
        ]

        case .meditation: return [
            .mindfulMinutes
        ]
        }
    }

    func contains(_ type: HKSampleType) -> Bool {
        self.associatedTypes.contains(type)
    }
}