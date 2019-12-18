//
// BooleanDigitalSensor
// TetraSwift
//
// Created by Alex Babaev on 13 December 2019.
//

import Foundation

public class BooleanDigitalSensor: Sensor {
    private let decoder: Digital10bitDecoder = .init()
    public let sensorValue: SensorValue<Bool> = SensorValue(value: false)

    public init() {}

    /// Returns whether the value was changed.
    public func update(rawValue: Any) throws {
        let value = try decoder.decode(value: rawValue)
        guard self.sensorValue.value != value else { return }

        self.sensorValue.value = value
    }
}
