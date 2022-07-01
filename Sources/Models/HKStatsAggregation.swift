import Foundation

public struct HKStatsAggregation: Hashable, Equatable {
    public let val: Double?
    public let period: HKClosedDateRange
}

public struct HKStatsSample: Hashable, Equatable {
    public let val: Double?
    public let type: HKSampleType
    public let period: HKClosedDateRange
    public let source: HKDevice?
}

