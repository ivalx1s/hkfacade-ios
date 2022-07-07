import Foundation
import HealthKit
import Combine
import Algorithms

public protocol AnyHKFacade {
    var isAvailable: Bool { get }
    func checkAccess(_ domains: HKFDomain...) async -> Result<Void, HKFError>
    func readSamples(request: HKReadSamplesRequest) async -> Result<[HKFStatsSample], HKFError>
    func quantityStatsSubscription(request: HKReadStatsRequest) -> AnyPublisher<HKFStatsCollection, HKFError>
    func readStats(request: HKReadStatsRequest) async -> Result<HKFStatsCollection, HKFError>
    func write(request: HKWriteRequest) async -> Result<Void, HKFError>

    func remoteDataStream(request: HKReadStatsRequest) -> AsyncStream<Result<HKStatisticsCollection, HKFError>>
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

    public func checkAccess(_ domains: HKFDomain...) async -> Result<Void, HKFError> {
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

    private func requestAccess(toShare: [HKFMetricType], toRead: [HKFMetricType]) async -> Result<Bool, HKFError> {
        await withCheckedContinuation { continuation in
            guard let hkStore = hkStore else {
                return continuation.resume(returning:  .failure(.hkNotAvailable))
            }

            hkStore.requestAuthorization(
                    toShare: Set(toShare.compactMap { $0.asSampleType }),
                    read: Set(toRead.compactMap { $0.asHKQuantityType })
            ) { flag, error in
                if let error = error {
                    return continuation.resume(returning: .failure(HKFError.general(error)))
                }
                return continuation.resume(returning: .success(flag))
            }
        }
    }

    private func requestAccess(toShare: [HKFMetricType], toRead: [HKFMetricType]) -> AnyPublisher<Bool, HKFError> {
        Deferred {
            Future<Bool, HKFError> { promise in
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
    public func readSamples(request: HKReadSamplesRequest) async -> Result<[HKFStatsSample], HKFError> {
        switch request.type {
        case let .discreteSample(type):
            return await readSamples(type: type, predicate: request.predicate, limit: request.limit)

        case .bloodPressureSample:
            return await readBloodPressureSamples(predicate: request.predicate, limit: request.limit)

        case .mindfulMinutesSample:
            return await readMindfulMinutesSamples(predicate: request.predicate, limit: request.limit)

        case .heartbeatSeries:
            switch await readRriSeries(predicate: request.predicate, limit: request.limit) {
            case let .success(sessions):
                return .success(
                        sessions
                                .map {HKFStatsSample(value: .rriSession($0), type: .rri, period: $0.period, source: nil)}
                )
            case let .failure(err):
                return .failure(err)
            }
        }
    }
}

// write
extension HKFacade {
    public func write(request: HKWriteRequest) async -> Result<Void, HKFError> {
        switch request.type {
        case let .quantitySample(qt, val, period):
            return await writeQuantitySample(type: qt, value: val, period: period, device: request.device)
        case let .bloodPressureSample(value, period):
            return await writeBloodPressureSample(value: value, period: period, device: request.device)
        case let .categorySample(ct, val, period):
            return await writeCategorySample(type: ct, value: val, period: period, device: request.device)
        case let .mindfulMinutesSample(value):
            return await writeMindfulMinutesSample(value: value, device: request.device)
        case let .heartbeat(session):
            return await writeRri(session: session, device: request.device)
        }
    }
}

// mindful minutes
extension HKFacade {
    private func readMindfulMinutesSamples(predicate: HKFPredicate?, limit: Int?) async -> Result<[HKFStatsSample], HKFError> {
        let mindfulMinutesType = HKFMetricType.mindfulMinutes

        let mindfulMinutesRes = await readSamples(type: mindfulMinutesType, predicate: predicate, limit: nil)
        switch mindfulMinutesRes {
        case let .success(samples):
            return .success(
                samples
                    .map {
                        HKFStatsSample(
                                value: .mindfulMinutes(.init(start: $0.period.start, end: $0.period.end)),
                                type: .mindfulMinutes,
                                period: $0.period,
                                source: $0.source
                        )
                    }
            )
        case let .failure(err):
            return .failure(err)
        }

    }

    public func writeMindfulMinutesSample(value: HKFMindfulMinutes, device: HKFDevice) async -> Result<Void, HKFError> {
        guard value.start < value.end else {
            return .failure(.failedToSave_invalidPeriod)
        }

        let mindfulMinutesType = HKFMetricType.mindfulMinutes
        return await writeCategorySample(type: mindfulMinutesType, value: 0, period: .init(start: value.start, end: value.end), device: device)
    }
}

// bloodPressure
extension HKFacade {
    public func readBloodPressureSamples(predicate: HKFPredicate?, limit: Int?) async -> Result<[HKFStatsSample], HKFError> {
        let bpSystolicType = HKFMetricType.bloodPressureSystolic
        let bpDiastolicType = HKFMetricType.bloodPressureDiastolic

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

    public func writeBloodPressureSample(value: HKFBloodPressure, period: HKFPeriod, device: HKFDevice) async -> Result<Void, HKFError> {
        let bpSystolicType = HKFMetricType.bloodPressureSystolic
        let bpDiastolicType = HKFMetricType.bloodPressureDiastolic

        async let systolicRes = writeQuantitySample(type: bpSystolicType, value: value.systolic, period: period, device: device)
        async let diastolicRes = writeQuantitySample(type: bpDiastolicType, value: value.diastolic, period: period, device: device)
        guard
                case .success = await systolicRes,
                case .success = await diastolicRes
        else {
            return .failure(.failedToRead_noStats )
        }
        return .success(())
    }
}

// rri
extension HKFacade {
    private func writeRri(session: HKFRriSession, device: HKFDevice) async -> Result<Void, HKFError> {
        guard let hkStore = hkStore else { return .failure(.hkNotAvailable) }

        let rriBuilder = HKHeartbeatSeriesBuilder(
                healthStore: hkStore,
                device: HKFModelBuilder.buildDevice(device),
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

    public func readRriSeries(predicate: HKFPredicate?, limit: Int?) async -> Result<[HKFRriSession], HKFError> {
        let sessionsRes = await readHeartbeatSessions(predicate: predicate, limit: limit)

        switch sessionsRes {
        case let .success(sessions):
            let sessionsWithSeries: [HKFRriSession] =
                    await sessions.concurrentMap {[weak self] session in
                        let period = HKFPeriod(start: session.startDate, end: session.endDate)
                        let seriesRes = await self?.readHeartbeatSeries(for: session)
                        switch seriesRes {
                        case let .success(series):
                            return HKFRriSession(period: period, timestamps: series)
                        case let .failure(err):
                            print("failed to read rri session: \(err)")
                            return HKFRriSession(period: period, timestamps: [])
                        case .none:
                            return HKFRriSession(period: period, timestamps: [])
                        }
                    }

            return .success(sessionsWithSeries)

        case let .failure(err):
            return .failure(.failedToRead(err))
        }
    }

    private func readHeartbeatSessions(predicate: HKFPredicate?, limit: Int?) async -> Result<[HKHeartbeatSeriesSample], HKFError> {
        await withCheckedContinuation { continuation in
            let type: HKFMetricType = .rri

            guard let hkStore = hkStore else {
                return continuation.resume(returning: .failure(.hkNotAvailable))
            }

            let hbSeriesSampleType = HKSeriesType.heartbeat()

            let heartbeatSeriesSampleQuery = HKSampleQuery(
                    sampleType: hbSeriesSampleType,
                    predicate: HKFModelBuilder.build(
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

    private func readHeartbeatSeries(for session: HKHeartbeatSeriesSample) async -> Result<[TimeInterval], HKFError> {
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
    public func remoteDataStream(
            request: HKReadStatsRequest
    ) -> AsyncStream<Result<HKStatisticsCollection, HKFError>> {
        AsyncStream { continuation in
            Task {
                guard let associatedType = request.associatedType.asQuantityType else {
                    continuation.yield(.failure(.failedToGetQuantityType))
                    return
                }

                let query = HKStatisticsCollectionQuery(
                        quantityType: associatedType,
                        quantitySamplePredicate: HKFModelBuilder.build(
                                request.predicate,
                                units: request.associatedType.units
                        ),
                        options: request.aggregation.asStatsOption,
                        anchorDate: request.anchor,
                        intervalComponents: request.cadence.dateComponent
                )

                let notify: (HKStatisticsCollection?)->() = { collection in
                    guard let collection = collection else {
                        continuation.yield(.failure(HKFError.failedToRead_noStats))
                        continuation.finish()
                        return
                    }
                    print("read \(request.associatedType): found: \(collection.statistics().count)")

                    continuation.yield(.success(collection))
                }

                query.initialResultsHandler = { query, collection, err in
                    notify(collection)
                }
                query.statisticsUpdateHandler = { query, stats, collection, err in
                    notify(collection)
                }
                hkStore?.execute(query)
            }
        }
    }

    public func readStats(request: HKReadStatsRequest) async -> Result<HKFStatsCollection, HKFError> {
        guard let samplesRequest = HKFModelBuilder.buildReadSamplesRequest(by: request) else {
            return .failure(.failedToReadStats(msg: "build request failed: \(request.associatedType) is not supported"))
        }

        let res = await readSamples(request: samplesRequest)
        guard case let .success(collection) = res else {
            return .failure(.failedToReadStats(msg: "error occurred"))
        }
        
        let stats = collection
                .groupBy(request.cadence.calendarComponents)
                .lazy
                .sorted{
                    ($0.key.asDate ?? Date()) < ($1.key.asDate ?? Date())
                }
                .compactMap {
                    HKFModelBuilder.reduce($0.value, type: request.associatedType, by: request.aggregation, period: buildPeriod($0.key, cadence: request.cadence))
                }

        return .success(HKFStatsCollection(stats: stats, aggregation: request.aggregation, metricType: request.associatedType))
    }

    private func buildPeriod(_ dateComponents: DateComponents, cadence: HKFCadence) -> HKFPeriod? {
        guard let start = Calendar.current.date(from: dateComponents) else { return nil }
        let end: Date!
        switch cadence {
        case .years: end = start.add(years: 1)
        case .months: end = start.add(months: 1)
        case .weeks: end = start.add(weeks: 1)
        case .days: end = start.add(days: 1)
        case .hours: end = start.add(hours: 1)
        case .minutes: end = start.add(months: 1)
        }

        return .init(start: start, end: end)
    }

    public func quantityStatsSubscription(request: HKReadStatsRequest) -> AnyPublisher<HKFStatsCollection, HKFError> {
        let subject = PassthroughSubject<HKFStatsCollection, HKFError>()

        guard let associatedType = request.associatedType.asQuantityType else {
            return Fail(error: .failedToReadStats(msg: "Stats requests are only available for quantity types"))
                    .eraseToAnyPublisher()
        }

        let query = HKStatisticsCollectionQuery(
                quantityType: associatedType,
                quantitySamplePredicate: HKFModelBuilder.build(
                        request.predicate,
                        units: request.associatedType.units
                ),
                options: request.aggregation.asStatsOption,
                anchorDate: request.anchor,
                intervalComponents: request.cadence.dateComponent
        )

        let notify: (HKStatisticsCollection?)->() = { collection in
            guard let collection = collection else {
                subject.send(.init(
                        stats: [],
                        aggregation: request.aggregation,
                        metricType: request.associatedType
                ))
                return
            }

            print("read \(request.associatedType): found: \(collection.statistics().count)")

            subject.send(.init(
                    stats: collection.statistics()
                            .compactMap { HKFModelBuilder.build($0, metricType: request.associatedType, aggregation: request.aggregation) },
                    aggregation: request.aggregation,
                    metricType: request.associatedType
            ))
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

    private func readSamples(type: HKFMetricType, predicate: HKFPredicate?, limit: Int?) async -> Result<[HKFStatsSample], HKFError> {
        await withCheckedContinuation { continuation in
            guard let hkStore = hkStore else {
                return continuation.resume(returning: .failure(.hkNotAvailable))
            }

            guard let sampleType = type.asSampleType else {
                return continuation.resume(returning: .failure(.failedToRead_unsupportedType))
            }

            let query = HKSampleQuery(
                    sampleType: sampleType,
                    predicate: HKFModelBuilder.build(
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
                        .map { HKFModelBuilder.build($0, type: type)}

                print("read \(type): found: \(result.count)")
                return continuation.resume(returning: .success(result))
            }

            hkStore.execute(query)
        }
    }

    private func writeQuantitySample(type: HKFMetricType, value: Double, period: HKFPeriod, device: HKFDevice) async -> Result<Void, HKFError> {
        guard let qt = type.asQuantityType else {
            return .failure(.failedToSaveCategorySample)
        }

        let sample = HKQuantitySample(
                type: qt,
                quantity: HKQuantity(unit: type.units, doubleValue: value),
                start: period.start, end: period.end,
                device: HKFModelBuilder.buildDevice(device),
                metadata: nil
        )
        return await saveSample(sample)
    }

    private func writeCategorySample(type: HKFMetricType, value: Double, period: HKFPeriod, device: HKFDevice) async -> Result<Void, HKFError> {
        guard let ct = type.asHKCategoryType else {
            return .failure(.failedToSaveCategorySample)
        }

        let sample = HKCategorySample(
                type: ct,
                value: HKFModelBuilder.buildCategoryValue(type: type, value: value),
                start: period.start,
                end: period.end,
                device: HKFModelBuilder.buildDevice(device),
                metadata: nil
        )

        return await saveSample(sample)
    }

    private func saveSample(_ hkSample: HKSample) async -> Result<Void, HKFError> {
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
                print("metric stored: \(hkSample.sampleType)")
                return continuation.resume(returning: .success(()))
            }
        }
    }
}
