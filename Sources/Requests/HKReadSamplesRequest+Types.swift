import HealthKit

public extension HKReadSamplesRequest {
    enum RType {
        case discreteSample(
                associatedType: HKFMetricType,
                predicate: HKPredicate?,
                limit: Int?
        )
        case bloodPressureSample(
                predicate: HKPredicate?,
                limit: Int?
        )
        case mindfulMinutesSample(
                predicate: HKPredicate?,
                limit: Int?
        )
        case heartbeatSeries(
                predicate: HKPredicate?,
                limit: Int?
        )
    }
}
