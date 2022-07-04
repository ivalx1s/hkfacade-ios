import Foundation

public struct HKFStatsSample: Hashable, Equatable {
    public let value: Value
    public let type: HKFMetricType
    public let period: HKFPeriod
    public let source: HKFDevice?
}