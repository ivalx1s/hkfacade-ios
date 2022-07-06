import Foundation
import HealthKit

public struct HKFModelBuilder {

    public static func build(_ stats: HKStatistics, metricType: HKFMetricType, aggregation: HKFAggregationType) -> HKFStatsSample? {
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
                    source: nil
            )
        case .min:
            return .init(
                    value: buildValue(
                            rawValue: stats.minimumQuantity()?.doubleValue(for: metricType.units),
                            type: metricType
                    ),
                    type: metricType,
                    period: period,
                    source: nil
            )
        case .max:
            return .init(
                    value: buildValue(
                            rawValue: stats.maximumQuantity()?.doubleValue(for: metricType.units),
                            type: metricType
                    ),
                    type: metricType,
                    period: period,
                    source: nil
            )
        case .sum:
            return .init(
                    value: buildValue(
                            rawValue: stats.sumQuantity()?.doubleValue(for: metricType.units),
                            type: metricType
                    ),
                    type: metricType,
                    period: period,
                    source: nil
            )
        case .mostRecent:
            return .init(
                    value: buildValue(
                            rawValue: stats.mostRecentQuantity()?.doubleValue(for: metricType.units),
                            type: metricType
                    ),
                    type: metricType,
                    period: period,
                    source: nil
            )
        }
    }

    public static func buildValue(rawValue: Double?, type: HKFMetricType) -> HKFValue {
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

    public static func buildCategoryValue(type: HKFMetricType, value: Double) -> Int {
        switch type {
        case .mindfulMinutes:
            return 0
        default:
            return Int(lround(value))
        }
    }

    public static func build(_ predicate: HKFPredicate?, units: HKUnit) -> NSPredicate? {
        guard let predicate = predicate else { return nil }
        return build(predicate: predicate, units: units)
    }

    public static func build(predicate: HKFPredicate, units: HKUnit) -> NSPredicate {
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
        case let .source(name):
            return HKQuery.predicateForObjects(
                    withDeviceProperty: HKDevicePropertyKeyName,
                    allowedValues: [name]
            )
        }
    }

    public static func build(_ model: HKSample, type: HKFMetricType) -> HKFStatsSample {
        HKFStatsSample(
                value: .nullableDouble(buildValue(model, type: type)),
                type: type,
                period: .init(start: model.startDate, end: model.endDate),
                source: build(model.device)
        )
    }

    public static func buildValue(_ model: HKSample, type: HKFMetricType) -> Double? {
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

    public static func build(_ model: HealthKit.HKDevice?) -> HKFDevice? {
        guard let device = model else { return nil }
        return .init(
                name: device.name ?? "",
                model: device.model ?? "",
                hardwareVersion: device.hardwareVersion ?? "",
                softwareVersion: device.softwareVersion ?? "",
                manufacturer: device.manufacturer ?? ""
        )
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
