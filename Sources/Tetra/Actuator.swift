//
// TetraActuatorValue
// TetraCode
//
// Created by Alex Babaev on 22 November 2019.
// Copyright (c) 2019 LonelyBytes. All rights reserved.
//

import Foundation

enum ActuatorKind: Hashable, CustomDebugStringConvertible {
    enum LEDColor: CustomDebugStringConvertible {
        case red
        case yellow
        case green

        var debugDescription: String {
            switch self {
                case .red: return "Red"
                case .yellow: return "Yellow"
                case .green: return "Green"
            }
        }
    }

    case motor
    case buzzer
    case analogLED(LEDColor)
    case digitalLED(LEDColor)

    var debugDescription: String {
        switch self {
            case .motor: return "Motor"
            case .buzzer: return "Buzzer"
            case .analogLED(let color): return "Analog LED, \(color)"
            case .digitalLED(let color): return "Digital LED, \(color)"
        }
    }
}

protocol Actuator: class {
    var kind: ActuatorKind { get }
    var port: IOPort { get }
    var rawValue: UInt { get }

    var changedListener: (_ id: IOPort, _ rawValue: UInt) -> Void { get set }
}

class AnalogActuator: Actuator, CustomDebugStringConvertible {
    let kind: ActuatorKind
    let port: IOPort
    var changedListener: (IOPort, UInt) -> Void = { _, _ in }
    private(set) var rawValue: UInt = 0
    private let maxValue: UInt
    var value: Double = 0 {
        didSet {
            let newRawValue = UInt(Double(maxValue) * value)
            if newRawValue != rawValue {
                rawValue = newRawValue
                changedListener(port, rawValue)
            }
        }
    }

    init(kind: ActuatorKind, port: IOPort, maxValue: UInt) {
        self.kind = kind
        self.port = port
        self.maxValue = maxValue
    }

    var debugDescription: String { "\(kind) ~> \(value) (\(rawValue))" }
}

class DigitalActuator: Actuator, CustomDebugStringConvertible {
    let kind: ActuatorKind
    let port: IOPort
    private(set) var rawValue: UInt = 0
    var changedListener: (IOPort, UInt) -> Void = { _, _ in }
    var value: Bool = false {
        didSet {
            let newRawValue: UInt = value ? 1023 : 0
            if newRawValue != rawValue {
                rawValue = newRawValue
                changedListener(port, rawValue)
            }
        }
    }

    func on() {
        value = true
    }

    func off() {
        value = false
    }

    init(kind: ActuatorKind, port: IOPort) {
        self.kind = kind
        self.port = port
    }

    var debugDescription: String { "\(kind) ~> \(value) (\(rawValue))" }
}
