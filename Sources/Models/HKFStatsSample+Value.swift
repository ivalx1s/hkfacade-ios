import Foundation

public enum HKFValue: Equatable, Hashable {
    case nullableDouble(Double?)
    case rriSession(HKFRriSession)
    case bloodPressure(HKFBloodPressure)
    case mindfulMinutes(HKFMindfulMinutes)
}

public extension HKFValue {
    var asDouble: Double? {
        switch self {
        case let .nullableDouble(val): return val
        default: return nil
        }
    }
    var asBloodPressure: HKFBloodPressure? {
        switch self {
        case let .bloodPressure(val): return val
        default: return nil
        }
    }

    var asRriSession: HKFRriSession? {
        switch self {
        case let .rriSession(val): return val
        default: return nil
        }
    }

    var asMindfulMinutes: HKFMindfulMinutes? {
        switch self {
        case let .mindfulMinutes(val): return val
        default: return nil
        }
    }
}
