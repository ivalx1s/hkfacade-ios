import Foundation

public extension HKWriteRequest {
    enum RType {
        case quantitySample(
                st: HKFMetricType,
                value: Double,
                period: HKFPeriod
        )

        case bloodPressureSample(
                value: HKFBloodPressure,
                period: HKFPeriod
        )

        case mindfulMinutesSample(
                value: HKFMindfulMinutes
        )

        case categorySample(
                st: HKFMetricType,
                value: Double,
                period: HKFPeriod
        )

        case heartbeat(
                session: HKFRriSession
        )
    }
}
