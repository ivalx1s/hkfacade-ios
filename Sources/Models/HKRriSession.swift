import Foundation

public struct HKRriSession: Equatable, Hashable {
    public let period: HKPeriod
    public let timestamps: [TimeInterval]

    public init(
            period: HKPeriod,
            timestamps: [TimeInterval]
    ) {
        self.period = period
        self.timestamps = timestamps
    }
}