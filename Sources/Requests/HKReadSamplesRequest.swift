import HealthKit

public struct HKReadSamplesRequest {
    let type: RType

    public init(
            type: RType
    ) {
        self.type = type
    }
}
