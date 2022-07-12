import Foundation

public struct HKFStatsSample: AnyDated {
    public let value: HKFValue
    public let type: HKFMetricType
    public let period: HKFPeriod
    public let device: HKFDevice?
    public let source: HKFSource?
    public let meta: HKFMetadata?

    var date: Date { period.start }
}

public struct HKFStatsAggregationSample {
    public let value: HKFValue
    public let type: HKFMetricType
    public let period: HKFPeriod
    public let devices: [HKFDevice]
    public let source: [HKFStatsSample]
}