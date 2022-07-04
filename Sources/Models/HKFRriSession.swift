import Foundation

public struct HKFRriSession: Equatable, Hashable {
    public let period: HKFPeriod
    public let timestamps: [TimeInterval]

    public init(
            period: HKFPeriod,
            timestamps: [TimeInterval]
    ) {
        self.period = period
        self.timestamps = timestamps
    }
}