import Foundation

public struct HKRriSession {
    public let period: HKClosedDateRange
    public let timestamps: [TimeInterval]

    public init(
            period: HKClosedDateRange,
            timestamps: [TimeInterval]
    ) {
        self.period = period
        self.timestamps = timestamps
    }
}