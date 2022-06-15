import Foundation
import HealthKit

public struct HKModelBuilder {

    public static func build(_ predicate: HKPredicate?, units: HKUnit) -> NSPredicate? {
        guard let predicate = predicate else { return nil }
        return build(predicate: predicate, units: units)
    }

    public static func build(predicate: HKPredicate, units: HKUnit) -> NSPredicate {
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
        }
    }

    public static func build(_ model: HKQuantitySample, units: HKUnit) -> HKStatsSample {
        HKStatsSample(
                val: model.quantity.doubleValue(for: units),
                period: .init(start: model.startDate, end: model.endDate),
                source: build(model.device)
        )
    }

    public static func build(_ model: HealthKit.HKDevice?) -> HKDevice? {
        guard let device = model else { return nil }
        return .init(
                name: device.name ?? "",
                hardwareVersion: device.hardwareVersion ?? "",
                softwareVersion: device.softwareVersion ?? "",
                manufacturer: device.manufacturer ?? ""
        )
    }
}
