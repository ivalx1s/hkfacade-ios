import Foundation
import HealthKit

public enum HKFAggregationType {
    case avg
    case min
    case max
    case sum
    case mostRecent

    var asStatsOption: HKStatisticsOptions {
        switch self {
        case .avg: return .discreteAverage
        case .min: return .discreteMin
        case .max: return .discreteMax
        case .sum: return .cumulativeSum
        case .mostRecent: return .mostRecent
        }
    }
}

public struct HKFStatsCollection {
    public let stats: [HKFStatsSample]
    public let aggregation: HKFAggregationType
}