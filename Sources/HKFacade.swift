import Foundation
import HealthKit
import Combine

public protocol AnyHKFacade {
    var isAvailable: Bool { get }
    func checkAccess(_ domains: HKDomain...) async -> Result<Void, HKError>

    func read(request: HKReadSamplesRequest) async -> Result<[HKStatsSample], HKError>
    func read(request: HKReadStatsRequest) -> AnyPublisher<HKStatisticsCollection, HKError>

    func write(request: HKWriteRequest) async -> Result<Void, HKError>
}

public class HKFacade: AnyHKFacade {
    private let hkStore: HKHealthStore?
    
    public init() {
        self.hkStore = HKHealthStore.isHealthDataAvailable()
            ? HKHealthStore()
            : nil
    }
}


// access
extension HKFacade {
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

    private func requestAccess(toShare: [HKSampleType], toRead: [HKSampleType]) async -> Result<Bool, HKError> {
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

    private func requestAccess(toShare: [HKSampleType], toRead: [HKSampleType]) -> AnyPublisher<Bool, HKError> {
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

// read samples
extension HKFacade {
    public func read(request: HKReadSamplesRequest) async -> Result<[HKStatsSample], HKError> {
        switch request.type {
        case let .discreteSample(type, predicate, limit):
            return await readSamples(type: type, predicate: predicate, limit: limit)
        case let .bloodPressureSample(predicate, limit):
            return await readBloodPressure(predicate: predicate, limit: limit)
        case let .heartbeatSeries(predicate, limit):
            switch await readRri(predicate: predicate, limit: limit) {
            case let .success(sessions):
                return .success(
                        sessions
                                .map {HKStatsSample(value: .rriSession($0), type: .rri, period: $0.period, source: nil)}
                )
            case let .failure(err):
                return .failure(err)
            }
        }
    }
}

// write
extension HKFacade {
    public func write(request: HKWriteRequest) async -> Result<Void, HKError> {
        switch request.type {
        case let .quantitySample(qt, val, period):
            return await writeQuantitySample(type: qt, value: val, period: period, device: request.device)
        case let .categorySample(ct, val, period):
            return await writeCategorySample(type: ct, value: val, period: period, device: request.device)
        case let .heartbeat(session):
            return await writeRri(session: session, device: request.device)
        }
    }
}

// bloodPressure
extension HKFacade {
    public func readBloodPressure(predicate: HKPredicate?, limit: Int?) async -> Result<[HKStatsSample], HKError> {
        let bpSystolicType = HKSampleType.bloodPressureSystolic
        let bpDiastolicType = HKSampleType.bloodPressureDiastolic

        async let systolicRes = readSamples(type: bpSystolicType, predicate: predicate, limit: limit)
        async let diastolicRes = readSamples(type: bpDiastolicType, predicate: predicate, limit: limit)
        guard
                case let .success(systolic) = await systolicRes,
                case let .success(diastolic) = await diastolicRes
        else {
            return .failure(.failedToRead_noStats )
        }

        return .success(
                zip(systolic, diastolic)
                        .compactMap {s, d in
                            guard
                                    s.period == d.period,
                                    let sVal = s.value.asDouble,
                                    let dVal = d.value.asDouble
                            else {
                                return nil
                            }

                            return .init(
                                    value: .bloodPressure(.init(
                                            systolic: sVal,
                                            diastolic: dVal
                                    )),
                                    type: .bloodPressure,
                                    period: s.period,
                                    source: s.source
                            )
                        }
        )
    }
}

// rri
extension HKFacade {
    private func writeRri(session: HKRriSession, device: HKDevice) async -> Result<Void, HKError> {
        guard let hkStore = hkStore else { return .failure(.hkNotAvailable) }

        let rriBuilder = HKHeartbeatSeriesBuilder(
                healthStore: hkStore,
                device: HKModelBuilder.buildDevice(device),
                start: session.period.start
        )

        await session
                .timestamps
                .concurrentForEach { timestamp in
                    try? await rriBuilder.addHeartbeat(at: timestamp, precededByGap: true)
                }
        do {
            try await rriBuilder.finishSeries()
            return .success(())
        } catch {
            return .failure(.failedToSave(error))
        }
    }

    public func readRri(predicate: HKPredicate?, limit: Int?) async -> Result<[HKRriSession], HKError> {
        let sessionsRes = await readHeartbeatSessions(predicate: predicate, limit: limit)

        switch sessionsRes {
        case let .success(sessions):
            let sessionsWithSeries: [HKRriSession] =
                    await sessions.concurrentMap {[weak self] session in
                        let period = HKClosedDateRange(start: session.startDate, end: session.endDate)
                        let seriesRes = await self?.readHeartbeatSeries(for: session)
                        switch seriesRes {
                        case let .success(series):
                            return HKRriSession(period: period, timestamps: series)
                        case let .failure(err):
                            print("failed to read rri session: \(err)")
                            return HKRriSession(period: period, timestamps: [])
                        case .none:
                            return HKRriSession(period: period, timestamps: [])
                        }
                    }

            return .success(sessionsWithSeries)

        case let .failure(err):
            return .failure(.failedToRead(err))
        }
    }

    private func readHeartbeatSessions(predicate: HKPredicate?, limit: Int?) async -> Result<[HKHeartbeatSeriesSample], HKError> {
        await withCheckedContinuation { continuation in
            let type: HKSampleType = .rri

            guard let hkStore = hkStore else {
                return continuation.resume(returning: .failure(.hkNotAvailable))
            }

            let hbSeriesSampleType = HKSeriesType.heartbeat()

            let heartbeatSeriesSampleQuery = HKSampleQuery(
                    sampleType: hbSeriesSampleType,
                    predicate: HKModelBuilder.build(
                            predicate,
                            units: type.units
                    ),
                    limit: limit ?? HKObjectQueryNoLimit,
                    sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)])
            { (sampleQuery, samples, error) in
                let sessions = samples?
                        .compactMap { $0 as? HKHeartbeatSeriesSample }
                        ?? []

                return continuation.resume(returning: .success(sessions))
            }

            hkStore.execute(heartbeatSeriesSampleQuery)
        }
    }

    private func readHeartbeatSeries(for session: HKHeartbeatSeriesSample) async -> Result<[TimeInterval], HKError> {
        await withCheckedContinuation { continuation in
            guard let hkStore = hkStore else {
                return continuation.resume(returning: .failure(.hkNotAvailable))
            }
            var data: [TimeInterval] = []
            let query = HKHeartbeatSeriesQuery(heartbeatSeries: session) {
                (query, timeSinceSeriesStart, precededByGap, done, error) in

                data.append(timeSinceSeriesStart)
                if done {
                    return continuation.resume(returning: .success(data))
                }
            }

            hkStore.execute(query)
        }
    }
}

// stats aggregations
extension HKFacade {
    public func read(request: HKReadStatsRequest) -> AnyPublisher<HKStatisticsCollection, HKError> {
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
                subject.send(completion: .failure(HKError.failedToRead_noStats))
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
extension HKFacade {
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
extension HKFacade {

    private func readSamples(type: HKSampleType, predicate: HKPredicate?, limit: Int?) async -> Result<[HKStatsSample], HKError> {
        await withCheckedContinuation { continuation in
            guard let hkStore = hkStore else {
                return continuation.resume(returning: .failure(.hkNotAvailable))
            }

            guard let sampleType = type.asSampleType else {
                return continuation.resume(returning: .failure(.failedToRead_unsupportedType))
            }

            let query = HKSampleQuery(
                    sampleType: sampleType,
                    predicate: HKModelBuilder.build(
                            predicate,
                            units: type.units
                    ),
                    limit: limit ?? HKObjectQueryNoLimit,
                    sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)]
            ) { (query, collection, error) in
                if let error = error {
                    return continuation.resume(returning: .failure(.general(error)))
                }
                guard let collection = collection else {
                    return continuation.resume(returning: .success([]))
                }

                let result = collection
                        .map { HKModelBuilder.build($0, type: type)}

                print("read \(type): found: \(result.count)")
                return continuation.resume(returning: .success(result))
            }

            hkStore.execute(query)
        }
    }

    private func writeQuantitySample(type: HKSampleType, value: Double, period: HKClosedDateRange, device: HKDevice) async -> Result<Void, HKError> {
        guard let qt = type.asQuantityType else {
            return .failure(.failedToSaveCategorySample)
        }

        let sample = HKQuantitySample(
                type: qt,
                quantity: HKQuantity(unit: type.units, doubleValue: value),
                start: period.start, end: period.end,
                device: HKModelBuilder.buildDevice(device),
                metadata: nil
        )
        return await saveSample(sample)
    }

    private func writeCategorySample(type: HKSampleType, value: Double, period: HKClosedDateRange, device: HKDevice) async -> Result<Void, HKError> {
        guard let ct = type.asHKCategoryType else {
            return .failure(.failedToSaveCategorySample)
        }

        let sample = HKCategorySample(
                type: ct,
                value: HKModelBuilder.buildCategoryValue(type: type, value: value),
                start: period.start,
                end: period.end,
                device: HKModelBuilder.buildDevice(device),
                metadata: nil
        )

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