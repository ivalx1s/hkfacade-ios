import HealthKit

public enum HKFMetricType {
    case heartRate
    case breathRate
    case oxygenSaturation
    case bloodPressureSystolic
    case bloodPressureDiastolic
    case bloodPressure
    case sdnn
    case rri

    case steps
    case distance
    case basalEnergy
    case activeEnergy

    case mindfulMinutes

    public var units: HKUnit {
        switch self {
        case .heartRate: return .timesPerMinuteUnit
        case .breathRate: return .timesPerMinuteUnit
        case .oxygenSaturation: return .percent()
        case .bloodPressureSystolic: return .millimeterOfMercury()
        case .bloodPressureDiastolic: return .millimeterOfMercury()
        case .bloodPressure: return .millimeterOfMercury()
        case .sdnn: return .second()
        case .rri: return .second()

        case .steps: return .count()
        case .distance: return .meter()
        case .basalEnergy: return .smallCalorie()
        case .activeEnergy: return .smallCalorie()

        case .mindfulMinutes: return .minute()
        }
    }

    var asSampleType: HealthKit.HKSampleType? { asHKQuantityType as? HealthKit.HKSampleType }

    var asQuantityType: HealthKit.HKQuantityType? { asHKQuantityType as? HealthKit.HKQuantityType }

    var asHKSeriesType: HealthKit.HKSeriesType? { asHKQuantityType as? HKSeriesType }

    var asHKCategoryType: HealthKit.HKCategoryType? {
        switch self {
        case .heartRate:
            return nil
        case .breathRate:
            return nil
        case .oxygenSaturation:
            return nil
        case .bloodPressureSystolic,
             .bloodPressureDiastolic,
             .bloodPressure:
            return nil
        case .sdnn:
            return nil
        case .rri:
            return nil

        case .steps:
            return nil
        case .distance:
            return nil
        case .basalEnergy:
            return nil
        case .activeEnergy:
            return nil
        case .mindfulMinutes:
            return HKObjectType.categoryType(forIdentifier: .mindfulSession)
        }
    }

    var asHKQuantityType: HealthKit.HKObjectType? {
        switch self {
        case .heartRate:
            return HealthKit.HKQuantityType.quantityType(forIdentifier: .heartRate)
        case .breathRate:
            return HealthKit.HKQuantityType.quantityType(forIdentifier: .respiratoryRate)
        case .oxygenSaturation:
            return HealthKit.HKQuantityType.quantityType(forIdentifier: .oxygenSaturation)
        case .bloodPressureSystolic:
            return HealthKit.HKQuantityType.quantityType(forIdentifier: .bloodPressureSystolic)
        case .bloodPressureDiastolic:
            return HealthKit.HKQuantityType.quantityType(forIdentifier: .bloodPressureDiastolic)
        case .bloodPressure:
            return nil

        case .sdnn:
            return HealthKit.HKQuantityType.quantityType(forIdentifier: .heartRateVariabilitySDNN)
        case .rri:
            return HealthKit.HKSeriesType.heartbeat()
        case .steps:
            return HealthKit.HKQuantityType.quantityType(forIdentifier: .stepCount)
        case .distance:
            return HealthKit.HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning)
        case .basalEnergy:
            return HealthKit.HKQuantityType.quantityType(forIdentifier: .basalEnergyBurned)
        case .activeEnergy:
            return HealthKit.HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)

        case .mindfulMinutes:
            return HealthKit.HKQuantityType.categoryType(forIdentifier: .mindfulSession)
        }
    }
}