//
// TetraActuatorValue
// TetraCode
//
// Created by Alex Babaev on 22 November 2019.
// Copyright (c) 2019 LonelyBytes. All rights reserved.
//

import Foundation

public enum ActuatorKind: Hashable, CustomDebugStringConvertible {
    public enum LEDColor: CustomDebugStringConvertible {
        case red
        case yellow
        case green

        public var debugDescription: String {
            switch self {
                case .red: return "Red"
                case .yellow: return "Yellow"
                case .green: return "Green"
            }
        }
    }

    public enum LEDMatrixType: CustomDebugStringConvertible {
        case monochrome

        public var debugDescription: String {
            switch self {
                case .monochrome: return "Monochrome"
            }
        }
    }

    case motor
    case buzzer
    case analogLED(LEDColor)
    case digitalLED(LEDColor)
    case quadDisplay
    case ledMatrix(LEDMatrixType)

    public var debugDescription: String {
        switch self {
            case .motor: return "Motor"
            case .buzzer: return "Buzzer"
            case .analogLED(let color): return "Analog LED, \(color)"
            case .digitalLED(let color): return "Digital LED, \(color)"
            case .quadDisplay: return "QuadDisplay"
            case .ledMatrix(let type): return "Led Matrix, \(type)"
        }
    }
}

public protocol Actuator: class {
    var kind: ActuatorKind { get }
    var rawValue: UInt { get }

    var changedListener: () -> Void { get set }
}

public class AnalogActuator: Actuator, CustomDebugStringConvertible {
    public let kind: ActuatorKind
    public var changedListener: () -> Void = {}
    public private(set) var rawValue: UInt = 0
    private let maxValue: UInt
    public var value: Double = 0 {
        didSet {
            let newRawValue = UInt(Double(maxValue) * value)
            if newRawValue != rawValue {
                rawValue = newRawValue
                changedListener()
            }
        }
    }

    public init(kind: ActuatorKind, maxValue: UInt) {
        self.kind = kind
        self.maxValue = maxValue
    }

    public var debugDescription: String { "\(kind) ~> \(value) (\(rawValue))" }
}

public class DigitalActuator: Actuator, CustomDebugStringConvertible {
    public let kind: ActuatorKind
    public private(set) var rawValue: UInt = 0
    public var changedListener: () -> Void = {}
    public var value: Bool = false {
        didSet {
            let newRawValue: UInt = value ? 1023 : 0
            if newRawValue != rawValue {
                rawValue = newRawValue
                changedListener()
            }
        }
    }

    public func on() {
        value = true
    }

    public func off() {
        value = false
    }

    public init(kind: ActuatorKind) {
        self.kind = kind
    }

    public var debugDescription: String { "\(kind) ~> \(value) (\(rawValue))" }
}

public class QuadNumericDisplayActuator: Actuator, CustomDebugStringConvertible {
    public let kind: ActuatorKind
    public private(set) var rawValue: UInt = 0
    public var changedListener: () -> Void = {}
    public var value: String = "" {
        didSet {
            changedListener()
        }
    }

    public init(kind: ActuatorKind) {
        self.kind = kind
    }

    public var debugDescription: String { "\(kind) ~> \(value)" }
}

public class LEDMatrixActuator: Actuator, CustomDebugStringConvertible {
    public let kind: ActuatorKind
    public private(set) var rawValue: UInt = 0
    public var changedListener: () -> Void = {}
    public var value: Character = " " { // Make this custom matrix
        didSet {
            changedListener()
        }
    }

    public init(kind: ActuatorKind) {
        self.kind = kind
    }

    public var debugDescription: String { "\(kind) ~> \(value)" }
}
