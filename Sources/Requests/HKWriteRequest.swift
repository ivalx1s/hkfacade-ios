import Foundation

public struct HKWriteRequest {
    public let type: RType
    public let device: HKFDevice

    public init(
            type: RType,
            device: HKFDevice
    ) {
        self.type = type
        self.device = device
    }
}

