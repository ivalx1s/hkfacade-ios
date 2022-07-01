import Foundation

public struct HKMindfulMinutes: Equatable, Hashable {
    public let start: Date
    public let end: Date

    public init(
            start: Date,
            end: Date) {
        self.start = start
        self.end = end
    }
}