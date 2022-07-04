import HealthKit

public struct HKReadStatsRequest {
       public let associatedType: HKFMetricType
       public let anchor: Date
       public let predicate: HKPredicate?
       public let cadence: HKFCadence
       public let options: HKStatisticsOptions

       public init(
               associatedType: HKFMetricType,
               anchor: Date,
               cadence: HKFCadence,
               predicate: HKPredicate?,
               options: HKStatisticsOptions
       ) {
              self.associatedType = associatedType
              self.anchor = anchor
              self.cadence = cadence
              self.predicate = predicate
              self.options = options
       }
}