import HealthKit

public extension HKUnit {
    static var beatsPerMinuteUnit: HKUnit { HKUnit.count().unitDivided(by: HKUnit.minute()) }
}