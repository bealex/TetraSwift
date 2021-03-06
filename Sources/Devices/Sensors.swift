//
// Sensors
// TetraSwift
//
// Created by Alex Babaev on 13 December 2019.
//

import Foundation

public class LightSensor: AnalogSensorWithFiltering {
    public init() {
        super.init(samplesCount: 8)
    }
}

public class MagneticSensor: AnalogSensorWithFiltering {
    public init() {
        super.init(samplesCount: 8, tolerance: 0.01)
    }
}

public class Potentiometer: AnalogSensorWithFiltering {
    public init() {
        super.init(samplesCount: 4, tolerance: 0.7)
    }
}

public class TemperatureSensor: AnalogSensorWithFiltering {
    public init() {
        super.init(samplesCount: 128, tolerance: 0.08) { rawAverage in
            // https://github.com/amperka/TroykaThermometer/blob/master/src/TroykaThermometer.cpp ‾\_(ツ)_/‾
            let sensorVoltage = rawAverage * (5.0 / 1023.0) // 5 — voltage, 1024 — maxValue
            let temperatureCelsius = (sensorVoltage - 0.5) * 100.0
            return temperatureCelsius
        }
    }
}

public class InfraredSensor: BooleanDigitalSensor {}

public class Button: BooleanDigitalSensor {}
