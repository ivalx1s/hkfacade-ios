import Foundation

public enum HKFCadence: Identifiable, Hashable, Comparable {
    case minutes(Int = 1)
    case hours(Int = 1)
    case days(Int = 1)
    case weeks(Int = 1)
    case months(Int = 1)
    case years(Int = 1)

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

    public var calendarComponents: Set<Calendar.Component> {
        switch self {
        case .years: return [.year]
        case .months: return [.year, .month]
        case .weeks: return [.year, .month, .weekOfMonth]
        case .days: return [.year, .month, .day]
        case .hours: return [.year, .month, .day, .hour]
        case .minutes: return [.year, .month, .day, .hour, .minute]
        }
    }

    public static func <(lhs: HKFCadence, rhs: HKFCadence) -> Bool {
        lhs.weight < rhs.weight
    }
}