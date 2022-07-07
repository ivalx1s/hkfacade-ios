import Foundation

public struct HKFStatsSample: Hashable, Equatable, AnyDated {
    public let value: HKFValue
    public let type: HKFMetricType
    public let period: HKFPeriod
    public let source: HKFDevice?

    var date: Date { period.start }
}

public struct HKFStatsAggregationSample: Hashable, Equatable {
    public let value: HKFValue
    public let type: HKFMetricType
    public let period: HKFPeriod
    public let sources: [HKFDevice]
    public let aggregatedItemsCount: Int
}