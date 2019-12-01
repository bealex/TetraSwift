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

protocol Sensor: IdentifiableDevice {
    var kind: SensorKind { get }
    var rawValue: UInt { get }

    func update(rawValue: UInt) -> Bool
}

class AnalogSensor: Sensor, CustomDebugStringConvertible {
    let id: UUID = UUID()
    let kind: SensorKind
    private(set) var rawValue: UInt = 0
    private(set) var rawAverage: Double = 0
    private(set) var value: Double = 0

    private let tolerance: Double
    private let sampleTimes: UInt
    private let calculate: (Double) -> Double

    init(kind: SensorKind, sampleTimes: UInt = 1, tolerance: Double = 0.1, calculate: @escaping (Double) -> Double = { $0 / 1023 }) {
        self.kind = kind
        self.sampleTimes = sampleTimes
        self.tolerance = tolerance
        self.calculate = calculate
    }

    private var samples: [UInt] = []

    /// Returns whether the value was changed.
    func update(rawValue: UInt) -> Bool {
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

    var debugDescription: String { "\(kind) ~> \(value) (\(rawValue))" }
}

class DigitalSensor: Sensor, CustomDebugStringConvertible {
    let id: UUID = UUID()
    let kind: SensorKind
    private(set) var rawValue: UInt = 0
    private(set) var value: Bool = false

    init(kind: SensorKind) {
        self.kind = kind
    }

    /// Returns whether the value was changed.
    func update(rawValue: UInt) -> Bool {
        let valueChanged = self.rawValue != rawValue
        self.rawValue = rawValue
        value = rawValue <= 512

        return valueChanged
    }

    var debugDescription: String { "\(kind) ~> \(value) (\(rawValue))" }
}
