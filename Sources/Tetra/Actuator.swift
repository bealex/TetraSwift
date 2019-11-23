//
// TetraActuatorValue
// TetraCode
//
// Created by Alex Babaev on 22 November 2019.
// Copyright (c) 2019 LonelyBytes. All rights reserved.
//

import Foundation

enum ActuatorKind: Hashable, CustomDebugStringConvertible {
    case motor4
    case motor7
    case motor8

    case buzzer

    case ledAnalog5
    case ledAnalog6

    case ledDigital10
    case ledDigital11
    case ledDigital12
    case ledDigital13

    var debugDescription: String {
        switch self {
            case .motor4: return "Motor 4"
            case .motor7: return "Motor 7"
            case .motor8: return "Motor 8"
            case .buzzer: return "Buzzer"
            case .ledAnalog5: return "Analog Led 5 (Yellow)"
            case .ledAnalog6: return "Analog Led 6 (Red)"
            case .ledDigital10: return "Digital Led 10 (Green)"
            case .ledDigital11: return "Digital Led 11 (Yellow)"
            case .ledDigital12: return "Digital Led 12 (Yellow)"
            case .ledDigital13: return "Digital Led 13 (Red)"
        }
    }
}

protocol Actuator: class {
    var kind: ActuatorKind { get }
    var id: UInt8 { get }
    var rawValue: UInt { get }

    var changedListener: (_ id: UInt8, _ rawValue: UInt) -> Void { get set }
}

class AnalogActuator: Actuator, CustomDebugStringConvertible {
    let kind: ActuatorKind
    let id: UInt8
    var changedListener: (UInt8, UInt) -> Void = { _, _ in }
    private(set) var rawValue: UInt = 0
    private let maxValue: UInt
    var value: Double = 0 {
        didSet {
            let newRawValue = UInt(Double(maxValue) * value)
            if newRawValue != rawValue {
                rawValue = newRawValue
                changedListener(id, rawValue)
            }
        }
    }

    init(kind: ActuatorKind, id: UInt8, maxValue: UInt) {
        self.kind = kind
        self.id = id
        self.maxValue = maxValue
    }

    var debugDescription: String { "\(kind) ~> \(value) (\(rawValue))" }
}

class DigitalActuator: Actuator, CustomDebugStringConvertible {
    let kind: ActuatorKind
    let id: UInt8
    private(set) var rawValue: UInt = 0
    var changedListener: (UInt8, UInt) -> Void = { _, _ in }
    var value: Bool = false {
        didSet {
            let newRawValue: UInt = value ? 1023 : 0
            if newRawValue != rawValue {
                rawValue = newRawValue
                changedListener(id, rawValue)
            }
        }
    }

    func on() {
        value = true
    }

    func off() {
        value = false
    }

    init(kind: ActuatorKind, id: UInt8) {
        self.kind = kind
        self.id = id
    }

    var debugDescription: String { "\(kind) ~> \(value) (\(rawValue))" }
}
