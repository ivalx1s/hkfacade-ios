import Foundation

public struct HKFSource: Equatable, Hashable {
    public let name: String
    public let bundleId: String


    public init(
            name: String,
            bundleId: String
    ) {
        self.name = name
        self.bundleId = bundleId
    }
}

public struct HKFDevice: Equatable, Hashable {
    public let name: String
    public let model: String
    public let hardwareVersion: String
    public let softwareVersion: String
    public let manufacturer: String

    public init(
            name: String,
            model: String,
            hardwareVersion: String,
            softwareVersion: String,
            manufacturer: String
    ) {
        self.name = name
        self.model = model
        self.hardwareVersion = hardwareVersion
        self.softwareVersion = softwareVersion
        self.manufacturer = manufacturer
    }
}