import Foundation

public enum HKFDomain {
    case fitness
    case cardio
    case meditation

    var associatedTypes: [HKFMetricType] {
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

    func contains(_ type: HKFMetricType) -> Bool {
        self.associatedTypes.contains(type)
    }
}