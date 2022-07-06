import Foundation
import HealthKit

public enum HKFAggregationType {
    case avg
    case min
    case max
    case sum

    var asStatsOption: HKStatisticsOptions {
        switch self {
        case .avg: return .discreteAverage
        case .min: return .discreteMin
        case .max: return .discreteMax
        case .sum: return .cumulativeSum
        }
    }
}

struct HKFStatsCollection {
    let stats: [HKFStats]
    let aggregation: HKFAggregationType
}

struct HKFStats {
    let value: HKFValue
    let period: HKFPeriod
}