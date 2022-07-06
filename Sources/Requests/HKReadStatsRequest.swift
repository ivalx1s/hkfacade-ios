import HealthKit

public struct HKReadStatsRequest {
       public let associatedType: HKFMetricType
       public let anchor: Date
       public let predicate: HKFPredicate?
       public let cadence: HKFCadence
       public let aggregation: HKFAggregationType

       public init(
               associatedType: HKFMetricType,
               anchor: Date,
               cadence: HKFCadence,
               predicate: HKFPredicate?,
               aggregation: HKFAggregationType
       ) {
              self.associatedType = associatedType
              self.anchor = anchor
              self.cadence = cadence
              self.predicate = predicate
              self.aggregation = aggregation
       }
}