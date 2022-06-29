import Foundation
import HealthKit
import Combine


public protocol IHealthService {
    var isAvailable: Bool { get }
    func checkAccess(_ domains: HKDomain...) async -> Result<Void, HKError>
    func read(request: HKReadSamplesRequest) async -> Result<[HKStatsSample], HKError>
    func read(request: HKReadStatsRequest) -> AnyPublisher<HKStatisticsCollection, HKError>
    func write(request: HKWriteSampleRequest) async -> Result<Void, HKError>
}

public class HealthService: IHealthService {
    private let hkStore: HKHealthStore?
    
    public init() {
        self.hkStore = HKHealthStore.isHealthDataAvailable()
            ? HKHealthStore()
            : nil
    }
}

// access
extension HealthService {
    public var isAvailable: Bool { HKHealthStore.isHealthDataAvailable() }

    public func checkAccess(_ domains: HKDomain...) async -> Result<Void, HKError> {
        let types = domains.flatMap {$0.associatedTypes}

        switch await requestAccess(toShare: types, toRead: types) {
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
                    toShare: Set(toShare.compactMap { $0.asSampleType }),
                    read: Set(toRead.compactMap { $0.asHKQuantityType })
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
                        toShare: Set(toShare.compactMap { $0.asSampleType }),
                        read: Set(toRead.compactMap { $0.asHKQuantityType })
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

        guard let associatedType = request.associatedType.asQuantityType else {
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
                intervalComponents: request.cadence.dateComponent
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

            guard let sampleType = request.associatedType.asSampleType else {
                return continuation.resume(returning: .failure(.failedToRead_unsupportedType))
            }

            let query = HKSampleQuery(
                    sampleType: sampleType,
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
                        .map { HKModelBuilder.build($0, type: request.associatedType)}

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
        if let qt = request.type.asQuantityType {
            return await performQuantityRequest(request, qt: qt)
        }

        if let ct = request.type.asHKCategoryType {
            return await performCategoryRequest(request, ct: ct)
        }

        return .failure(.failedToSave_unsupportedType)
    }

    private func performQuantityRequest(_ request: HKWriteSampleRequest, qt: HealthKit.HKQuantityType) async -> Result<Void, HKError> {
        let quantity = HKQuantity(unit: request.type.units, doubleValue: request.value)
        return await saveQuantitySample(
                type: qt,
                quantity: quantity,
                period: request.period,
                device: HKModelBuilder.buildDevice(request.device)
        )
    }

    private func performCategoryRequest(_ request: HKWriteSampleRequest, ct: HealthKit.HKCategoryType, device: HealthKit.HKDevice? = nil) async -> Result<Void, HKError> {
        let sample = HKCategorySample(
                type: ct,
                value: HKModelBuilder.buildCategoryValue(request: request),
                start: request.period.start,
                end: request.period.end,
                device: HKModelBuilder.buildDevice(request.device),
                metadata: nil
        )
        return await saveSample(sample)
    }


    private func saveQuantitySample(type: HealthKit.HKQuantityType, quantity: HKQuantity, period: HKClosedDateRange, device: HealthKit.HKDevice? = nil) async -> Result<Void, HKError> {
        let sample = HKQuantitySample(type: type, quantity: quantity, start: period.start, end: period.end, device: device, metadata: nil)
        return await saveSample(sample)
    }

    private func saveSample(_ hkSample: HKSample) async -> Result<Void, HKError> {
        await withCheckedContinuation { continuation in
            guard let hkStore = hkStore else {
                return continuation.resume(returning: .failure(.hkNotAvailable))
            }

            hkStore.save(hkSample) { flag, err in
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