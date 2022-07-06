import Foundation

protocol AnyDated {
    var date: Date { get }
}

extension Sequence where Element: AnyDated {
    func groupBy(_ components: Set<Calendar.Component>) -> Dictionary<DateComponents, [Element]> {
        Dictionary(grouping: self) { (item: AnyDated) -> DateComponents in
            Calendar.current.dateComponents(components, from: (item.date))
        }
    }
}

extension Array where Element: BinaryFloatingPoint {
    var average: Double? {
        guard let sum = sum else { return nil }
        return Double(sum) / Double(self.count)
    }

    var sum: Double? {
        if self.isEmpty {
            return nil
        } else {
            let sum = self.reduce(0.0, +)
            return Double(sum)
        }
    }
}
