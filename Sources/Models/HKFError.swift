import Foundation

public enum HKFError: Error {
    case hkNotAvailable
    case noAccessForDomain
    case typeIsNotInDomain
    case failedToGetQuantityType
    case failedToReadStats(msg: String)
    case general(Error)
    case failedToSaveQuantitySample
    case failedToSaveCategorySample
    case failedToSave(Error)
    case failedToSaveSafe
    case failedToRead(Error)
    case failedToRead_noStats
    case failedToRead_unsupportedType
    case failedToSave_unsupportedType
    case failedToSave_invalidPeriod
}
