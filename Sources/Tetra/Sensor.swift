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

    case motor // ???

    case button2
    case button3

    var debugDescription: String {
        switch self {
            case .light: return "Light Sensor"
            case .magnetic: return "Magnetic Sensor"
            case .temperature: return "Temperature Sensor"
            case .infrared: return "Infrared Sensor"
            case .potentiometer: return "Potentiometer"
            case .motor: return "Motor"
            case .button2: return "Button 2"
            case .button3: return "Button 3"
        }
    }
}

protocol Sensor {
    var kind: SensorKind { get }
    var id: UInt8 { get }
    var rawValue: UInt { get }

    func update(rawValue: UInt) -> Bool
}

class AnalogSensor: Sensor, CustomDebugStringConvertible {
    let kind: SensorKind
    let id: UInt8
    private(set) var rawValue: UInt = 0
    private(set) var value: Double = 0

    init(kind: SensorKind, id: UInt8) {
        self.kind = kind
        self.id = id
    }

    /// Returns whether the value was changed.
    func update(rawValue: UInt) -> Bool {
        let valueChanged = self.rawValue != rawValue
        self.rawValue = rawValue
        value = Double(rawValue) / 1023

        return valueChanged
    }

    var debugDescription: String { "\(kind) ~> \(value) (\(rawValue))" }
}

class DigitalSensor: Sensor, CustomDebugStringConvertible {
    let kind: SensorKind
    let id: UInt8
    private(set) var rawValue: UInt = 0
    private(set) var value: Bool = false

    init(kind: SensorKind, id: UInt8) {
        self.kind = kind
        self.id = id
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
