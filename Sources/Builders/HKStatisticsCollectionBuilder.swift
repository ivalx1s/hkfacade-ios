import HealthKit

public extension HKStatisticsCollection {
    var asUnitsPerMinute: [HKFStatsAggregation] {
        self
                .statistics()
                .map {
                    HKFStatsAggregation(
                            val: $0.averageQuantity()?.doubleValue(for: .timesPerMinuteUnit),
                            period: .init(start: $0.startDate, end: $0.endDate)
                    )
                }
    }

    var asUnitSamples: [HKFStatsAggregation] {
        self
                .statistics()
                .map {
                    HKFStatsAggregation(
                            val: $0.sumQuantity()?.doubleValue(for: HKUnit.count()),
                            period: .init(start: $0.startDate, end: $0.endDate)
                    )
                }
    }
}
