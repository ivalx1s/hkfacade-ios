import HealthKit

public extension HKReadSamplesRequest {
    enum RType {
        case discreteSample(
                associatedType: HKFMetricType,
                predicate: HKFPredicate?,
                limit: Int?
        )
        case bloodPressureSample(
                predicate: HKFPredicate?,
                limit: Int?
        )
        case mindfulMinutesSample(
                predicate: HKFPredicate?,
                limit: Int?
        )
        case heartbeatSeries(
                predicate: HKFPredicate?,
                limit: Int?
        )
    }
}
