import Foundation

public struct HKOpenDateRange {
    public let start: Date?
    public let end: Date?
    public init(
            start: Date?,
            end: Date?
    ) {
        self.start = start
        self.end = end
    }
}

public struct HKPeriod: Hashable, Equatable {
    public let start: Date
    public let end: Date
    public init(
            start: Date,
            end: Date
    ) {
        self.start = start
        self.end = end
    }
}