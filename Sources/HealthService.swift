import Foundation
import HealthKit
import Combine

public protocol IHealthService {
    static var isAvailable: Bool { get }
    func checkAccess(domain: HKDomain) async -> Result<Void, HKError>
    func read(request: HKReadSamplesRequest) async -> Result<[HKStatsSample], HKError>
    func read(request: HKReadStatsRequest) -> AnyPublisher<HKStatisticsCollection, HKError>
    func write(request: HKWriteSampleRequest) async -> Result<Void, HKError>
}

public class HealthService: IHealthService {
    private let hkStore: HKHealthStore?
    
    public init() {
        self.hkStore = Self.isAvailable
            ? HKHealthStore()
            : nil
    }
}

// access
extension HealthService {
    public static var isAvailable: Bool { HKHealthStore.isHealthDataAvailable() }

    public func checkAccess(domain: HKDomain) async -> Result<Void, HKError> {
        switch await requestAccess(toShare: domain.associatedTypes, toRead: domain.associatedTypes) {
        case let .failure(err):
            return .failure(err)
        case let .success(flag):
            switch flag {
            case false: return .failure(.noAccessForDomain)
            case true: return .success(())
            }
        }
    }

    private func requestAccess(toShare: [HKQuantityType], toRead: [HKQuantityType]) async -> Result<Bool, HKError> {
        await withCheckedContinuation { continuation in
            guard let hkStore = hkStore else {
                return continuation.resume(returning:  .failure(.hkNotAvailable))
            }

            hkStore.requestAuthorization(
                    toShare: Set(toShare.compactMap { $0.asSample }),
                    read: Set(toRead.compactMap { $0.asHKObject })
            ) { flag, error in
                if let error = error {
                    return continuation.resume(returning: .failure(HKError.general(error)))
                }
                return continuation.resume(returning: .success(flag))
            }
        }
    }

    private func requestAccess(toShare: [HKQuantityType], toRead: [HKQuantityType]) -> AnyPublisher<Bool, HKError> {
        Deferred {
            Future<Bool, HKError> { promise in
                guard let hkStore = self.hkStore else {
                    promise(.failure(.hkNotAvailable))
                    return
                }

                hkStore.requestAuthorization(
                        toShare: Set(toShare.compactMap { $0.asSample }),
                        read: Set(toRead.compactMap { $0.asHKObject })
                ) { flag, error in
                    if let error = error {
                        promise(.failure(.general(error)))
                    } else {
                        promise(.success(flag))
                    }
                }
            }
        }.eraseToAnyPublisher()
    }
}

// stats aggregations
extension HealthService {
    public func read(request: HKReadStatsRequest) -> AnyPublisher<HKStatisticsCollection, HKError> {
        perform(request)
    }

    private func perform(_ request: HKReadStatsRequest) -> AnyPublisher<HKStatisticsCollection, HKError> {
        let subject = PassthroughSubject<HKStatisticsCollection, HKError>()

        guard let associatedType = request.associatedType.asQuantity else {
            return Fail(error: .failedToGetQuantityType).eraseToAnyPublisher()
        }

        let query = HKStatisticsCollectionQuery(
                quantityType: associatedType,
                quantitySamplePredicate: HKModelBuilder.build(
                        request.predicate,
                        units: request.associatedType.units
                ),
                options: request.options,
                anchorDate: request.anchor,
                intervalComponents: request.cadence
        )

        let notify: (HKStatisticsCollection?)->() = { collection in
            guard let collection = collection else {
                subject.send(completion: .failure(HKError.failedToRead))
                return
            }
            print("read \(request.associatedType): found: \(collection.statistics().count)")
            subject.send(collection)
        }

        query.initialResultsHandler = { query, collection, err in
            notify(collection)
        }
        query.statisticsUpdateHandler = { query, stats, collection, err in
            notify(collection)
        }

        let pub = subject
                .handleEvents(receiveCancel: { self.hkStore?.stop(query) })
                .eraseToAnyPublisher()

        hkStore?.execute(query)

        return pub
    }
}

// correlations
extension HealthService {
    public func readCorrelation() async {
        var highCalorieFoods: [HKCorrelationQuery] = []

        let highCalorie = HKQuantity(unit: HKUnit.kilocalorie(), doubleValue: 400.0);

        let greaterThanHighCalorie = HKQuery.predicateForQuantitySamples(
                with: .greaterThanOrEqualTo,
                quantity: highCalorie
        )

        let energyConsumed = HKObjectType.quantityType(forIdentifier: .dietaryEnergyConsumed)!

        let samplePredicates = [energyConsumed: greaterThanHighCalorie]
        let foodType = HKCorrelationType.correlationType(forIdentifier: .food)!

        let query = HKCorrelationQuery(
                type: foodType,
                predicate: nil,
                samplePredicates: samplePredicates
        ) { query, results, error in

            if let correlations = results as? [HKCorrelationQuery] {
                for correlation in correlations {
                    highCalorieFoods.append(correlation)
                }

                print("\(highCalorieFoods.count)")
                print(highCalorieFoods)
            }
            else {
                print("An error occurred while searching for high calorie food")
            }

            print("Found \(highCalorieFoods.count) foods: \(highCalorieFoods)")
        }

        hkStore?.execute(query)
    }
}

// stats samples
extension HealthService {
    public func read(request: HKReadSamplesRequest) async -> Result<[HKStatsSample], HKError> {
        await perform(request)
    }

    private func perform(_ request: HKReadSamplesRequest) async -> Result<[HKStatsSample], HKError> {
        await withCheckedContinuation { continuation in
            guard let hkStore = hkStore else {
                return continuation.resume(returning: .failure(.hkNotAvailable))
            }

            let query = HKSampleQuery(
                    sampleType: request.associatedType.asSample!,
                    predicate: HKModelBuilder.build(
                            request.predicate,
                            units: request.associatedType.units
                    ),
                    limit: request.limit ?? HKObjectQueryNoLimit,
                    sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)]
            ) { (query, collection, error) in
                if let error = error {
                    return continuation.resume(returning: .failure(.general(error)))
                }
                guard let collection = collection else {
                    return continuation.resume(returning: .success([]))
                }

                let result = collection
                        .compactMap { ($0 as? HKQuantitySample) }
                        .map { HKModelBuilder.build($0, units: request.associatedType.units)}

                print("read \(request.associatedType): found: \(result.count)")
                return continuation.resume(returning: .success(result))
            }

            hkStore.execute(query)
        }
    }

    public func write(request: HKWriteSampleRequest) async -> Result<Void, HKError> {
        await perform(request)
    }

    private func perform(_ request: HKWriteSampleRequest) async -> Result<Void, HKError> {
        guard let qt = request.type.asQuantity else {
            return .failure(.failedToGetQuantityType)
        }
        let quantity = HKQuantity(unit: request.type.units, doubleValue: request.value)
        return await saveQuantitySample(
                type: qt,
                quantity: quantity,
                period: request.period
        )
    }

    private func saveQuantitySample(type: HealthKit.HKQuantityType, quantity: HKQuantity, period: HKClosedDateRange) async -> Result<Void, HKError> {
        await withCheckedContinuation { continuation in
            guard let hkStore = hkStore else {
                return continuation.resume(returning: .failure(.hkNotAvailable))

            }
            let sample = HKQuantitySample(type: type, quantity: quantity, start: period.start, end: period.end)

            hkStore.save(sample) { flag, err in
                if let err = err {
                    return continuation.resume(returning: .failure(.failedToSave(err)))
                }
                guard flag else {
                    return continuation.resume(returning: .failure(.failedToSaveSafe))
                }

                return continuation.resume(returning: .success(()))
            }
        }
    }
}