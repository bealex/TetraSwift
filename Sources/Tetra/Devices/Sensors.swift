//
// Sensors
// TetraSwift
//
// Created by Alex Babaev on 13 December 2019.
//

import Foundation

public class LightSensor: AnalogSensorWithFiltering {
    public init() {
        super.init(kind: .lightSensor, sampleTimes: 8)
    }
}

public class MagneticSensor: AnalogSensorWithFiltering {
    public init() {
        super.init(kind: .magneticSensor, sampleTimes: 8, tolerance: 0.01)
    }
}

public class Potentiometer: AnalogSensorWithFiltering {
    public init() {
        super.init(kind: .potentiometer, sampleTimes: 4, tolerance: 0.7)
    }
}

public class TemperatureSensor: AnalogSensorWithFiltering {
    public init() {
        super.init(kind: .temperatureSensor, sampleTimes: 32, tolerance: 0.05) { rawAverage in
            // https://github.com/amperka/TroykaThermometer/blob/master/src/TroykaThermometer.cpp ¯\_(ツ)_/¯
            let sensorVoltage = rawAverage * (5.0 / 1023.0) // 5 — voltage, 1024 — maxValue
            let temperatureCelsius = (sensorVoltage - 0.5) * 100.0
            return temperatureCelsius
        }
    }
}

public class InfraredSensor: BooleanDigitalSensor {
    public init() {
        super.init(kind: .infraredSensor)
    }
}

public class Button: BooleanDigitalSensor {
    public init() {
        super.init(kind: .button)
    }
}
