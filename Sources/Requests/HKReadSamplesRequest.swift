import Foundation

public struct HKReadSamplesRequest {
    let associatedType: HKSampleType
    let predicate: HKPredicate?
    let limit: Int?

    public init(
            type: HKSampleType,
            predicate: HKPredicate?,
            limit: Int? = nil
    ) {
        self.associatedType = type
        self.predicate = predicate
        self.limit = limit
    }
}
