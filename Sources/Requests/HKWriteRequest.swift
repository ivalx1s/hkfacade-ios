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

