//
// TetraSensorValue
// TetraCode
//
// Created by Alex Babaev on 22 November 2019.
// Copyright (c) 2019 LonelyBytes. All rights reserved.
//

import Foundation

enum TetraSensorValue: CustomDebugStringConvertible {
    case unknown(id: UInt8, value: UInt) // Looks like unknown is motor current position ???

    case lightSensor(UInt)
    case potentiometer(UInt)
    case magneticSensor(UInt)
    case temperatureSensor(UInt)

    case infraredSensor(UInt) // Bool ???

    case button2(Bool)
    case button3(Bool)

    init(bytes: [UInt8]) {
        guard bytes.count == 2 else {
            self = .unknown(id: 255, value: 0)
            return
        }

        // This is PicoBoard protocol, essentially all of it :-)
        let id = (bytes[0] >> 3) & 0b1111
        let value = (UInt((bytes[0] & 0b111)) << 7) | (UInt(bytes[1]) & 0b1111111)

        switch id {
            case 0:  self = .lightSensor(value)
            case 1:  self = .potentiometer(value)
            case 2:  self = .magneticSensor(value)
            case 3:  self = .temperatureSensor(value)
            case 4:  self = .infraredSensor(value)
            case 5:  self = .unknown(id: id, value: value)
            case 6:  self = .button2(value < 512)
            case 7:  self = .button3(value < 512)
            default: self = .unknown(id: id, value: value)
        }
    }

    var debugDescription: String {
        switch self {
            case .lightSensor(let value):
                return "Light Sensor: \(value)"
            case .magneticSensor(let value):
                return "Magnetic Sensor: \(value)"
            case .temperatureSensor(let value):
                return "Temperature Sensor: \(value)"
            case .infraredSensor(let value):
                return "Infrared Sensor: \(value)"
            case .potentiometer(let value):
                return "Potentiometer: \(value)"
            case .button2(let value):
                return "Button 2: \(value ? "pressed" : "not pressed")"
            case .button3(let value):
                return "Button 3: \(value ? "pressed" : "not pressed")"
            case .unknown(let id, let value):
                return "Unknown Sensor / id \(id): \(value)"
        }
    }
}
