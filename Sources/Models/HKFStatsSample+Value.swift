import Foundation

public enum HKFValue: Equatable, Hashable {
    case nullableDouble(Double?)
    case rriSession(HKFRriSession)
    case bloodPressure(HKFBloodPressure)
    case mindfulMinutes(HKFMindfulMinutes)
}

extension HKFValue: Comparable {
    public static func <(lhs: HKFValue, rhs: HKFValue) -> Bool {
        switch lhs {
        case let .nullableDouble(leftVal):
            return (leftVal ?? 0) < (rhs.asDouble ?? 0)
        case let .mindfulMinutes(leftVal):
            return leftVal.end.timeIntervalSince(leftVal.start) < (rhs.asMindfulMinutes?.end ?? Date()).timeIntervalSince(rhs.asMindfulMinutes?.start ?? Date())
        case let .bloodPressure(leftVal):
            return leftVal.systolic < rhs.asBloodPressure?.systolic ?? 0
        case let .rriSession(leftVal):
            return (leftVal.timestamps.max() ?? 0) < (rhs.asRriSession?.timestamps.max() ?? 0)
        }
    }
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
