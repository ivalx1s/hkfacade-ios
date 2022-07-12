import Foundation
import HealthKit

struct HKFModelBuilder {

    static func build(_ stats: HKStatistics, metricType: HKFMetricType, aggregation: HKFAggregationType) -> HKFStatsAggregationSample? {
        let period = HKFPeriod(start: stats.startDate, end: stats.endDate)

        switch aggregation {
        case .avg:
            return .init(
                    value: buildValue(
                            rawValue: stats.averageQuantity()?.doubleValue(for: metricType.units),
                            type: metricType
                    ),
                    type: metricType,
                    period: period,
                    devices: [],
                    source: []
            )
        case .min:
            return .init(
                    value: buildValue(
                            rawValue: stats.minimumQuantity()?.doubleValue(for: metricType.units),
                            type: metricType
                    ),
                    type: metricType,
                    period: period,
                    devices: [],
                    source: []
            )
        case .max:
            return .init(
                    value: buildValue(
                            rawValue: stats.maximumQuantity()?.doubleValue(for: metricType.units),
                            type: metricType
                    ),
                    type: metricType,
                    period: period,
                    devices: [],
                    source: []
            )
        case .sum:
            return .init(
                    value: buildValue(
                            rawValue: stats.sumQuantity()?.doubleValue(for: metricType.units),
                            type: metricType
                    ),
                    type: metricType,
                    period: period,
                    devices: [],
                    source: []
            )
        case .mostRecent:
            return .init(
                    value: buildValue(
                            rawValue: stats.mostRecentQuantity()?.doubleValue(for: metricType.units),
                            type: metricType
                    ),
                    type: metricType,
                    period: period,
                    devices: [],
                    source: []
            )
        }
    }

    static func buildValue(rawValue: Double?, type: HKFMetricType) -> HKFValue {
        switch type {
        case .heartRate,
             .breathRate,
             .oxygenSaturation:
            return .nullableDouble(rawValue)
        case .sdnn:
            return .nullableDouble(rawValue)
        default:
            return .nullableDouble(rawValue)
        }
    }

    static func buildCategoryValue(type: HKFMetricType, value: Double) -> Int {
        switch type {
        case .mindfulMinutes:
            return 0
        default:
            return Int(lround(value))
        }
    }

    static func build(_ predicate: HKFPredicate?, units: HKUnit) -> NSPredicate? {
        guard let predicate = predicate else { return nil }
        return build(predicate: predicate, units: units)
    }

    static func build(predicate: HKFPredicate, units: HKUnit) -> NSPredicate {
        switch predicate {
        case let .not(subPredicate):
            return NSCompoundPredicate(notPredicateWithSubpredicate: build(predicate: subPredicate, units: units))

        case let .composite(logicalOperation, subPredicates):
            switch logicalOperation {
            case .and:
                return NSCompoundPredicate(andPredicateWithSubpredicates: subPredicates.map { build(predicate: $0, units: units)})
            case .or:
                return NSCompoundPredicate(orPredicateWithSubpredicates: subPredicates.map { build(predicate: $0, units: units) })
            }

        case let .quantity(comparisonOperator, value):
            return HKQuery.predicateForQuantitySamples(
                    with: comparisonOperator,
                    quantity: HKQuantity(unit: units, doubleValue: value)
            )
        case let .date(period):
            return HKQuery.predicateForSamples(
                    withStart: period.start,
                    end: period.end
            )
        case let .device(name):
            return HKQuery.predicateForObjects(
                    withDeviceProperty: HKDevicePropertyKeyName,
                    allowedValues: [name]
            )
        }
    }

    static func build(_ model: HKSample, type: HKFMetricType) -> HKFStatsSample {
        HKFStatsSample(
                value: .nullableDouble(buildValue(model, type: type)),
                type: type,
                period: .init(start: model.startDate, end: model.endDate),
                device: buildDevice(model.device),
                source: buildSource(model.source),
                meta: model.metadata
        )
    }

    static func buildValue(_ model: HKSample, type: HKFMetricType) -> Double? {
        if let model = model as? HKQuantitySample {
            return model.quantity.doubleValue(for: type.units)
        }
        if let model = model as? HKCategorySample {
            switch type {
            case .mindfulMinutes:
                return (model.endDate.timeIntervalSince(model.startDate) / 60)
            default:
                print("default HKCategorySample value")
                return Double(model.value)
            }
        }

        print("unsupported HKSample type")
        return nil
    }

    static func buildDevice(_ model: HealthKit.HKDevice?) -> HKFDevice? {
        guard let device = model else { return nil }
        return buildDevice(device)
    }

    static func buildSource(_ model: HealthKit.HKSource) -> HKFSource {
        .init(
                name: model.name,
                bundleId: model.bundleIdentifier
        )
    }

    static func buildDevice(_ model: HealthKit.HKDevice) -> HKFDevice {
        .init(
                name: model.name ?? "",
                model: model.model ?? "",
                hardwareVersion: model.hardwareVersion ?? "",
                softwareVersion: model.softwareVersion ?? "",
                manufacturer: model.manufacturer ?? ""
        )
    }

    static func reduce(_ collection: [HKFStatsSample], type: HKFMetricType, by aggregation: HKFAggregationType, period: HKFPeriod?) -> HKFStatsAggregationSample? {
        let collection = collection.lazy.sorted {$0.date < $1.date}
        let sources = collection.compactMap { $0.device }
        guard let first = collection.first,
              let last = collection.last
        else { return nil }

        let period: HKFPeriod = period ?? .init(
                start: first.period.start,
                end: last.period.start
        )

        switch aggregation {
        case .mostRecent:
            guard let last = collection.last else { return nil }
            return
                    .init(value: last.value, type: last.type, period: last.period, devices: sources, source: collection)
        case .min:
            guard let min = (collection.min { $0.value < $1.value }) else { return nil }
            return .init(value: min.value, type: min.type, period: min.period, devices: sources, source: collection)
        case .max:
            guard let max = (collection.max { $0.value < $1.value }) else { return nil }
            return .init(value: max.value, type: max.type, period: max.period, devices: sources, source: collection)
        case .avg:
            switch type {
            case .heartRate, .breathRate,.oxygenSaturation,.sdnn, .bloodPressureSystolic, .bloodPressureDiastolic,
                 .steps, .distance,
                 .basalEnergy, .activeEnergy:
                let avg = collection.lazy.compactMap { $0.value.asDouble }.average
                return .init(value: .nullableDouble(avg), type: type, period: period, devices: sources, source: collection)
            case .mindfulMinutes:
                let avg = collection.lazy.compactMap { $0.value.asMindfulMinutes?.interval }.average
                return .init(value: .nullableDouble(avg), type: type, period: period, devices: sources, source: collection)
            case .bloodPressure:
                let values = collection.lazy.compactMap { $0.value.asBloodPressure }
                let systolicAvg = values.lazy.map { $0.systolic }.average
                let diastolicAvg = values.lazy.map { $0.diastolic }.average
                return .init(value: .bloodPressure(.init(systolic: systolicAvg ?? 0, diastolic: diastolicAvg ?? 0)), type: .bloodPressure, period: period, devices: sources, source: collection)
            case .rri:
                let avg = collection
                        .compactMap { $0.value.asRriSession }
                        .compactMap { $0.timestamps.average  }
                        .average
                return .init(value: .nullableDouble(avg), type: .rri, period: period, devices: sources, source: collection)
            }
        case .sum:
            switch type {
            case .heartRate, .breathRate,.oxygenSaturation,.sdnn, .bloodPressureSystolic, .bloodPressureDiastolic,
                 .steps, .distance,
                 .basalEnergy, .activeEnergy:
                let sum = collection.lazy.compactMap { $0.value.asDouble }.sum
                return .init(value: .nullableDouble(sum), type: type, period: period, devices: sources, source: collection)
            case .mindfulMinutes:
                let sum = collection.lazy.compactMap { $0.value.asMindfulMinutes?.interval }.sum
                return .init(value: .nullableDouble(sum), type: type, period: period, devices: sources, source: collection)
            case .bloodPressure:
                return nil
            case .rri:
                return nil
            }
        }
    }

    static func buildReadSamplesRequest(by readStatsRequest: HKReadStatsRequest) -> HKReadSamplesRequest? {
        switch readStatsRequest.associatedType {
        case .heartRate, .breathRate, .oxygenSaturation, .sdnn:
            return .init(
                    type: .discreteSample(associatedType: readStatsRequest.associatedType),
                    predicate: readStatsRequest.predicate
            )
        case .mindfulMinutes:
            return .init(
                    type: .mindfulMinutesSample,
                    predicate: readStatsRequest.predicate
            )
        case .bloodPressure:
            return .init(
                    type: .bloodPressureSample,
                    predicate: readStatsRequest.predicate
            )
        case .rri:
            return .init(
                    type: .heartbeatSeries,
                    predicate: readStatsRequest.predicate
            )
        default:
            return nil
        }
    }

    static func buildDevice(_ device: HKFDevice) -> HealthKit.HKDevice {
        .init(
                name: device.name,
                manufacturer: device.manufacturer,
                model: device.model,
                hardwareVersion: device.hardwareVersion,
                firmwareVersion: nil,
                softwareVersion: device.softwareVersion,
                localIdentifier: nil,
                udiDeviceIdentifier: nil
        )
    }
}
