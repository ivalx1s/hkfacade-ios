import HealthKit

public enum HKQuantityType {
    case heartRate
    case steps
    case distance
    case basalEnergy
    case activeEnergy

    public var units: HKUnit {
        switch self {
        case .heartRate: return .beatsPerMinuteUnit
        case .steps: return .count()
        case .distance: return .meter()
        case .basalEnergy: return .smallCalorie()
        case .activeEnergy: return .smallCalorie()
        }
    }

    var asSample: HKSampleType? { asHKObject as? HKSampleType }

    var asQuantity: HealthKit.HKQuantityType? { asHKObject as? HealthKit.HKQuantityType }

    var asHKObject: HealthKit.HKObjectType? {
        switch self {
        case .heartRate:
            return HealthKit.HKQuantityType.quantityType(forIdentifier: .heartRate)
        case .steps:
            return HealthKit.HKQuantityType.quantityType(forIdentifier: .stepCount)
        case .distance:
            return HealthKit.HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning)
        case .basalEnergy:
            return HealthKit.HKQuantityType.quantityType(forIdentifier: .basalEnergyBurned)
        case .activeEnergy:
            return HealthKit.HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)
        }
    }
}