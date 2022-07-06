import Foundation

public struct HKFMindfulMinutes: Equatable, Hashable {
    public let start: Date
    public let end: Date

    public init(
            start: Date,
            end: Date) {
        self.start = start
        self.end = end
    }

    var interval: TimeInterval {
        end.timeIntervalSince(start)
    }
}