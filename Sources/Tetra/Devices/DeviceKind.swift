//
// DeviceKind
// TetraSwift
//
// Created by Alex Babaev on 13 December 2019.
//

import Foundation

public enum DeviceKind: Hashable, CustomDebugStringConvertible {
    // MARK: - Sensors

    case lightSensor
    case potentiometer
    case magneticSensor
    case temperatureSensor
    case infraredSensor

    // MARK: - Actuators

    public enum LEDColor: Hashable, CustomDebugStringConvertible {
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

    public enum LEDMatrixType: Hashable, CustomDebugStringConvertible {
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

    // MARK: - Combined Devices

    case button

    public var debugDescription: String {
        switch self {
            case .lightSensor: return "Light Sensor"
            case .magneticSensor: return "Magnetic Sensor"
            case .temperatureSensor: return "Temperature Sensor"
            case .infraredSensor: return "Infrared Sensor"
            case .potentiometer: return "Potentiometer"

            case .motor: return "Motor"
            case .buzzer: return "Buzzer"
            case .analogLED(let color): return "Analog LED, \(color)"
            case .digitalLED(let color): return "Digital LED, \(color)"
            case .quadDisplay: return "QuadDisplay"
            case .ledMatrix(let type): return "Led Matrix, \(type)"

            case .button: return "Button"
        }
    }
}
