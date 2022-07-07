import Foundation
extension DateComponents {
    var asDate: Date? {
        Calendar.current.date(from: self)
    }
}

extension Date {
    func add(
            years: Int = 0,
            months: Int = 0,
            weeks: Int = 0,
            days: Int = 0,
            hours: Int = 0,
            minutes: Int = 0,
            seconds: Int = 0
    ) -> Date {
        var dateComponent = DateComponents()
        dateComponent.year = years
        dateComponent.month = months
        dateComponent.weekOfYear = weeks
        dateComponent.day = days
        dateComponent.hour = hours
        dateComponent.minute = minutes
        dateComponent.second = seconds

        return
                Calendar.current.date(byAdding: dateComponent, to: self)
                        ?? self
    }
}
