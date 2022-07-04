import HealthKit

public extension HKUnit {
    static var timesPerMinuteUnit: HKUnit { HKUnit.count().unitDivided(by: HKUnit.minute()) }
}