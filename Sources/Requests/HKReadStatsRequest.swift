import HealthKit

public struct HKReadStatsRequest {
       let associatedType: HKSampleType
       let anchor: Date
       let predicate: HKPredicate?
       let cadence: HKCadence
       let options: HKStatisticsOptions
}