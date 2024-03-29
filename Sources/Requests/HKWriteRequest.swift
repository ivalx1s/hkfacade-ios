import Foundation

public extension HKFacade {
	typealias ExerciseMetaKey = String
}

public typealias HKFMetadata = [HKFacade.ExerciseMetaKey : Any]

public struct HKWriteRequest {
    public let type: RType
    public let device: HKFDevice
    public let meta: HKFMetadata?

    public init(
            type: RType,
            device: HKFDevice,
            meta: HKFMetadata?
    ) {
        self.type = type
        self.device = device
        self.meta = meta
    }
}

