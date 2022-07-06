import HealthKit

public struct HKReadStatsRequest {
       public let associatedType: HKFMetricType
       public let anchor: Date
       public let predicate: HKPredicate?
       public let cadence: HKFCadence
       public let aggregationType: HKFAggregationType

       public init(
               associatedType: HKFMetricType,
               anchor: Date,
               cadence: HKFCadence,
               predicate: HKPredicate?,
               aggregationType: HKFAggregationType
       ) {
              self.associatedType = associatedType
              self.anchor = anchor
              self.cadence = cadence
              self.predicate = predicate
              self.aggregationType = aggregationType
       }
}