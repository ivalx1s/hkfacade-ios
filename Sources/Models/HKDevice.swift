import Foundation

public struct HKDevice: Equatable, Hashable {
    public let name: String
    public let hardwareVersion: String
    public let softwareVersion: String
    public let manufacturer: String
}