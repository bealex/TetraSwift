//
// DeviceKind
// TetraSwift
//
// Created by Alex Babaev on 13 December 2019.
//

import Foundation

public enum DeviceKind: Hashable {
    // MARK: - Sensors

    case lightSensor
    case potentiometer
    case magneticSensor
    case temperatureSensor
    case infraredSensor

    // MARK: - Actuators

    public enum LEDColor: Hashable {
        case red
        case yellow
        case green
    }

    case motor
    case buzzer
    case analogLED(LEDColor)
    case digitalLED(LEDColor)
    case quadDisplay
    case ledMatrix

    // MARK: - Combined Devices

    case button
}
