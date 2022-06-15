import Foundation

public struct HKWriteSampleRequest {
    public let type: HKQuantityType
    public let value: Double
    public let period: HKClosedDateRange

    public init(
            type: HKQuantityType,
            value: Double,
            period: HKClosedDateRange
    ) {
        self.type = type
        self.value = value
        self.period = period
    }
}
