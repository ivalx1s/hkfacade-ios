import Foundation

public enum HKFCadence: Identifiable, Hashable, Comparable {
    case minutes(Int)
    case hours(Int)
    case days(Int)
    case weeks(Int)
    case months(Int)
    case years(Int)

    public var id: String {
        switch self {
        case .minutes: return "minutes"
        case .hours: return "hours"
        case .days: return "days"
        case .weeks: return "weeks"
        case .months: return "months"
        case .years: return "years"
        }
    }
    public var weight: Double {
        switch self {
        case let .minutes(val): return (Double(10) + Double(val)/10)
        case let .hours(val): return (Double(20) + Double(val)/10)
        case let .days(val): return (Double(30) + Double(val)/10)
        case let .weeks(val): return (Double(40) + Double(val)/10)
        case let .months(val): return (Double(50) + Double(val)/10)
        case let .years(val): return (Double(60) + Double(val)/10)
        }
    }

    public var dateComponent: DateComponents {
        switch self {
        case let .minutes(val): return DateComponents(minute: val)
        case let .hours(val): return DateComponents(hour: val)
        case let .days(val): return DateComponents(day: val)
        case let .weeks(val): return DateComponents(weekOfMonth: val)
        case let .months(val): return DateComponents(month: val)
        case let .years(val): return DateComponents(year: val)
        }
    }

    public static func <(lhs: HKFCadence, rhs: HKFCadence) -> Bool {
        lhs.weight < rhs.weight
    }
}