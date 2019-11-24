//
// TetraSensorValue
// TetraCode
//
// Created by Alex Babaev on 22 November 2019.
// Copyright (c) 2019 LonelyBytes. All rights reserved.
//

import Foundation

enum SensorKind: Hashable, CustomDebugStringConvertible {
    case light
    case potentiometer
    case magnetic
    case temperature
    case infrared
    case button

    var debugDescription: String {
        switch self {
            case .light: return "Light Sensor"
            case .magnetic: return "Magnetic Sensor"
            case .temperature: return "Temperature Sensor"
            case .infrared: return "Infrared Sensor"
            case .potentiometer: return "Potentiometer"
            case .button: return "Button"
        }
    }
}

protocol Sensor {
    var kind: SensorKind { get }
    var port: IOPort { get }
    var rawValue: UInt { get }

    func update(rawValue: UInt) -> Bool
}

class AnalogSensor: Sensor, CustomDebugStringConvertible {
    let kind: SensorKind
    let port: IOPort
    private(set) var rawValue: UInt = 0
    private(set) var value: Double = 0

    private let sampleTimes: UInt
    private let calculate: (UInt) -> Double

    init(kind: SensorKind, port: IOPort, sampleTimes: UInt = 1, calculate: @escaping (UInt) -> Double = { Double($0) / 1023 }) {
        self.kind = kind
        self.port = port
        self.sampleTimes = sampleTimes
        self.calculate = calculate
    }

    private var samples: [UInt] = []

    /// Returns whether the value was changed.
    func update(rawValue: UInt) -> Bool {
        samples.append(rawValue)
        while samples.count > sampleTimes {
            samples.remove(at: 0)
        }

        let averageRawValue = samples.reduce(UInt(0), +) / sampleTimes

        let valueChanged = self.rawValue != averageRawValue
        self.rawValue = averageRawValue
        value = calculate(averageRawValue)

        return valueChanged
    }

    var debugDescription: String { "\(kind):\(port) ~> \(value) (\(rawValue))" }
}

class DigitalSensor: Sensor, CustomDebugStringConvertible {
    let kind: SensorKind
    let port: IOPort
    private(set) var rawValue: UInt = 0
    private(set) var value: Bool = false

    init(kind: SensorKind, port: IOPort) {
        self.kind = kind
        self.port = port
    }

    /// Returns whether the value was changed.
    func update(rawValue: UInt) -> Bool {
        let valueChanged = self.rawValue != rawValue
        self.rawValue = rawValue
        value = rawValue <= 512

        return valueChanged
    }

    var debugDescription: String { "\(kind):\(port) ~> \(value) (\(rawValue))" }
}
