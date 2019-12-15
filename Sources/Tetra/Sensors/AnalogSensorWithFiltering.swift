//
// AnalogSensorWithFiltering
// TetraSwift
//
// Created by Alex Babaev on 13 December 2019.
//

import Foundation

public class AnalogSensorWithFiltering: AnalogSensor, CustomDebugStringConvertible {
    public let id: UUID = UUID()
    public let kind: DeviceKind
    public private(set) var rawValue: UInt = 0

    @SensorValue
    public private(set) var value: Double = 0
    public var hasListeners: Bool { _value.hasListeners }

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
    public func update(rawValue: UInt) {
        samples.append(rawValue)
        while samples.count > sampleTimes {
            samples.remove(at: 0)
        }

        guard samples.count == sampleTimes else { return }

        let averageRawValue: Double = samples.reduce(Double(0)) { $0 + Double($1) } / Double(sampleTimes)
        guard abs(rawAverage - averageRawValue) > tolerance else { return }

        self.rawValue = UInt(averageRawValue)
        self.rawAverage = averageRawValue
        value = calculate(averageRawValue)
    }

    public func whenValueChanged(listener: @escaping (_ value: Double) -> Void) {
        _value.whenValueChanged(do: listener)
    }

    public func when(lessThan compareValue: Double, listener: @escaping (_ value: Double) -> Void) {
        _value.when(lessThan: compareValue, do: listener)
    }

    public func when(greaterThan compareValue: Double, listener: @escaping (_ value: Double) -> Void) {
        _value.when(greaterThan: compareValue, do: listener)
    }

    public var debugDescription: String { "\(kind) ~> \(value) (\(rawValue))" }
}
