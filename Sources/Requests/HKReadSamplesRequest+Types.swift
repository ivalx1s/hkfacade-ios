import HealthKit

public extension HKReadSamplesRequest {
    enum Order {
        case asc
        case desc
    }
}

public extension HKReadSamplesRequest {
    enum RType {
        case discreteSample(
                associatedType: HKFMetricType
        )
        case bloodPressureSample
        case mindfulMinutesSample
        case heartbeatSeries
    }
}
