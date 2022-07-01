import Foundation

public struct HKReadRriSeriesRequest {
    let associatedType: HKSampleType
    let predicate: HKPredicate?
    let limit: Int?

    public init(
            predicate: HKPredicate?,
            limit: Int? = nil
    ) {
        self.associatedType = .rri
        self.predicate = predicate
        self.limit = limit
    }
}