import Foundation
import HealthKit

public enum HKLogicalOperation: String {
    case and
    case or
}

public indirect enum HKPredicate {
    case not(HKPredicate)
    case composite(HKLogicalOperation, [HKPredicate])
    case date(HKOpenDateRange)
    case quantity(operator: NSComparisonPredicate.Operator, value: Double)
}