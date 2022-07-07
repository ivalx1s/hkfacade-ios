import HealthKit

public struct HKReadSamplesRequest {
    let type: RType
    let predicate: HKFPredicate?
    let limit: Int?
    let order: Order

    public init(
            type: RType,
            predicate: HKFPredicate? = nil,
            limit: Int? = nil,
            order: Order = .desc
    ) {
        self.type = type
        self.predicate = predicate
        self.limit = limit
        self.order = order
    }
}
