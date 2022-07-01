import Foundation

public struct HKWriteRequest {
    public let type: RType
    public let device: HKDevice

    public init(
            type: RType,
            device: HKDevice
    ) {
        self.type = type
        self.device = device
    }
}

public extension HKWriteRequest {
    enum RType {
        case quantitySample(
            st: HKSampleType,
            value: Double,
            period: HKClosedDateRange
        )
        case categorySample(
            st: HKSampleType,
            value: Double,
            period: HKClosedDateRange
        )
        case heartbeat(
            session: HKRriSession
        )
    }
}


