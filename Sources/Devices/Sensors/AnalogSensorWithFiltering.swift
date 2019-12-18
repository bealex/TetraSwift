//
// AnalogSensorWithFiltering
// TetraSwift
//
// Created by Alex Babaev on 13 December 2019.
//

import Foundation

public class AnalogSensorWithFiltering: Sensor {
    private let decoder: Analog10bitDecoder
    public let sensorValue: SensorValue<Double> = SensorValue(value: 0)

    private let tolerance: Double
    private let calculate: (Double) -> Double

    public init(samplesCount: Int = 1, tolerance: Double = 0.1, calculate: @escaping (Double) -> Double = { $0 / 1023.0 }) {
        decoder = Analog10bitDecoder(samplesCount: samplesCount)
        self.tolerance = tolerance
        self.calculate = calculate
    }

    private var lastValue: Double = 0

    /// Returns whether the value was changed.
    public func update(rawValue: Any) throws {
        let decodedValue = try decoder.decode(value: rawValue)
        guard abs(lastValue - decodedValue) > tolerance else { return }

        lastValue = decodedValue
        sensorValue.value = calculate(lastValue)
    }
}
