import Foundation

public struct HKReadSamplesRequest {
    let associatedType: HKQuantityType
    let predicate: HKPredicate?
    let limit: Int?

    public init(
            type: HKQuantityType,
            predicate: HKPredicate?,
            limit: Int? = nil
    ) {
        self.associatedType = type
        self.predicate = predicate
        self.limit = limit
    }
}
