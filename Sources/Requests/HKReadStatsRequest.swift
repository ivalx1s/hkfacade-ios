import HealthKit

public struct HKReadStatsRequest {
    let associatedType: HKSampleType
    let anchor: Date
    let predicate: HKPredicate?
    let cadence: HKCadence
    let options: HKStatisticsOptions

    public init(
            type: HKSampleType,
            anchor: Date,
            predicate: HKPredicate? = nil,
            cadence: HKCadence,
            options: HKStatisticsOptions
    ) {
        self.associatedType = type
        self.anchor = anchor
        self.predicate = predicate
        self.cadence = cadence
        self.options = options
    }
}
