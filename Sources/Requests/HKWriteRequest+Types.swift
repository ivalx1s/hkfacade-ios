import Foundation

public extension HKWriteRequest {
    enum RType {
        case quantitySample(
                st: HKSampleType,
                value: Double,
                period: HKPeriod
        )

        case bloodPressureSample(
                value: HKBloodPressure,
                period: HKPeriod
        )

        case mindfulMinutesSample(
                value: HKMindfulMinutes
        )

        case categorySample(
                st: HKSampleType,
                value: Double,
                period: HKPeriod
        )

        case heartbeat(
                session: HKRriSession
        )
    }
}
