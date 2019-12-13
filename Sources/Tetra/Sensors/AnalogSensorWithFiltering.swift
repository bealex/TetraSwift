//
// AnalogSensorWithFiltering
// TetraSwift
//
// Created by Alex Babaev on 13 December 2019.
//

import Foundation

public class AnalogSensorWithFiltering: AnalogSensing, CustomDebugStringConvertible {
    public let id: UUID = UUID()
    public let kind: DeviceKind
    public private(set) var rawValue: UInt = 0
    public private(set) var value: Double = 0

    private var rawAverage: Double = 0

    private let tolerance: Double
    private let sampleTimes: UInt
    private let calculate: (Double) -> Double

    public init(kind: DeviceKind, sampleTimes: UInt = 1, tolerance: Double = 0.1, calculate: @escaping (Double) -> Double = { $0 / 1023 }) {
        self.kind = kind
        self.sampleTimes = sampleTimes
        self.tolerance = tolerance
        self.calculate = calculate
    }

    private var samples: [UInt] = []

    /// Returns whether the value was changed.
    public func update(rawValue: UInt) -> Bool {
        samples.append(rawValue)
        while samples.count > sampleTimes {
            samples.remove(at: 0)
        }

        guard samples.count == sampleTimes else { return false }

        let averageRawValue: Double = samples.reduce(Double(0)) { $0 + Double($1) } / Double(sampleTimes)

        let valueChanged = abs(rawAverage - averageRawValue) > tolerance
        self.rawValue = UInt(averageRawValue)
        self.rawAverage = averageRawValue
        value = calculate(averageRawValue)

        return valueChanged
    }

    public var debugDescription: String { "\(kind) ~> \(value) (\(rawValue))" }
}
