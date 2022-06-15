import HealthKit

public struct HKReadStatsRequest {
    let associatedType: HKQuantityType
    let anchor: Date
    let predicate: HKPredicate?
    let cadence: DateComponents
    let options: HKStatisticsOptions

    public init(
            type: HKQuantityType,
            anchor: Date,
            predicate: HKPredicate? = nil,
            cadence: DateComponents,
            options: HKStatisticsOptions
    ) {
        self.associatedType = type
        self.anchor = anchor
        self.predicate = predicate
        self.cadence = cadence
        self.options = options
    }
}
