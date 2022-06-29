import Foundation

public struct HKWriteSampleRequest {
    public let type: HKQuantityType
    public let value: Double
    public let period: HKClosedDateRange
    public let device: HKFacade.HKDevice

    public init(
            type: HKQuantityType,
            value: Double,
            period: HKClosedDateRange,
            device: HKFacade.HKDevice
    ) {
        self.type = type
        self.value = value
        self.period = period
        self.device = device
    }
}
