//
// SensorCalculations
// TetraCode
//
// Created by Alex Babaev on 25 November 2019.
// Copyright (c) 2019 LonelyBytes. All rights reserved.
//

import Foundation

enum SensorCalculator {
    static func celsiusTemperature(rawAverage: Double) -> Double {
        // https://github.com/amperka/TroykaThermometer/blob/master/src/TroykaThermometer.cpp ¯\_(ツ)_/¯
        let sensorVoltage = rawAverage * (5.0 / 1023.0) // 5 — voltage, 1024 — maxValue
        let temperatureCelsius = (sensorVoltage - 0.5) * 100.0
        return temperatureCelsius
    }
}
