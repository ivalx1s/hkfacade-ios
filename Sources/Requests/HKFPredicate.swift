import Foundation
import HealthKit

public enum HKFLogicalOperation: String {
    case and
    case or
}

public indirect enum HKFPredicate {
    case not(HKFPredicate)
    case composite(HKFLogicalOperation, [HKFPredicate])
    case date(HKFOpenDateRange)
    case quantity(operator: NSComparisonPredicate.Operator, value: Double)
    case source(name: String)
}