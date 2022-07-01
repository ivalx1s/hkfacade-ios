import Foundation

public struct HKStatsAggregation: Hashable, Equatable {
    public let val: Double?
    public let period: HKPeriod
}

public struct HKStatsSample: Hashable, Equatable {
    public let value: Value
    public let type: HKSampleType
    public let period: HKPeriod
    public let source: HKDevice?
}

public extension HKStatsSample {
    enum Value: Equatable, Hashable {
        case nullableDouble(Double?)
        case rriSession(HKRriSession)
        case bloodPressure(HKBloodPressure)
        case mindfulMinutes(HKMindfulMinutes)
    }
}

public extension HKStatsSample.Value {
    var asDouble: Double? {
        switch self {
        case let .nullableDouble(val): return val
        default: return nil
        }
    }
    var asBloodPressure: HKBloodPressure? {
        switch self {
        case let .bloodPressure(val): return val
        default: return nil
        }
    }

    var asRriSession: HKRriSession? {
        switch self {
        case let .rriSession(val): return val
        default: return nil
        }
    }

    var asMindfulMinutes: HKMindfulMinutes? {
        switch self {
        case let .mindfulMinutes(val): return val
        default: return nil
        }
    }
}
