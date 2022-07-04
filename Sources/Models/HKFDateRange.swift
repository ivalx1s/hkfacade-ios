import Foundation

public struct HKFOpenDateRange {
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

public struct HKFPeriod: Hashable, Equatable {
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