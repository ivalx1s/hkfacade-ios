import Foundation

public enum HKError: Error {
    case hkNotAvailable
    case noAccessForDomain
    case typeIsNotInDomain
    case failedToGetQuantityType
    case general(Error)
    case failedToSave(Error)
    case failedToSaveSafe
    case failedToRead
    case failedToRead_unsupportedType
    case failedToSave_unsupportedType
}
