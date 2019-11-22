//
// TetraSensorValue
// TetraCode
//
// Created by Alex Babaev on 22 November 2019.
// Copyright (c) 2019 LonelyBytes. All rights reserved.
//

import Foundation

extension Tetra {
    struct Sensor: Equatable, CustomDebugStringConvertible {
        enum Kind: Hashable {
            case unknown(id: UInt8)

            case light
            case potentiometer
            case magnetic
            case temperature

            case infrared

            case motor // ???

            case button2
            case button3
        }

        var kind: Kind
        var id: UInt8
        var tolerance: Int

        static func == (lhs: Sensor, rhs: Sensor) -> Bool {
            lhs.kind == rhs.kind && lhs.id == rhs.id
        }

        var debugDescription: String {
            switch kind {
                case .light:
                    return "Light Sensor"
                case .magnetic:
                    return "Magnetic Sensor"
                case .temperature:
                    return "Temperature Sensor"
                case .infrared:
                    return "Infrared Sensor"
                case .potentiometer:
                    return "Potentiometer"
                case .motor:
                    return "Motor"
                case .button2:
                    return "Button 2"
                case .button3:
                    return "Button 3"
                case .unknown(let id):
                    return "Unknown Sensor / id \(id)"
            }
        }
    }

    static let sensorsById: [UInt8: Sensor] = [
        0: Sensor(kind: .light, id: 0, tolerance: 0),
        1: Sensor(kind: .potentiometer, id: 1, tolerance: 0),
        2: Sensor(kind: .magnetic, id: 2, tolerance: 0),
        3: Sensor(kind: .temperature, id: 3, tolerance: 0),
        4: Sensor(kind: .infrared, id: 4, tolerance: 0),
        5: Sensor(kind: .motor, id: 5, tolerance: 0),
        6: Sensor(kind: .button2, id: 6, tolerance: 0),
        7: Sensor(kind: .button3, id: 7, tolerance: 0),
    ]

    // swiftlint:disable force_unwrapping
    static let sensorsByKind: [Sensor.Kind: Sensor] = [
        .light: Tetra.sensorsById[0]!,
        .potentiometer: Tetra.sensorsById[1]!,
        .magnetic: Tetra.sensorsById[2]!,
        .temperature: Tetra.sensorsById[3]!,
        .infrared: Tetra.sensorsById[4]!,
        .motor: Tetra.sensorsById[5]!,
        .button2: Tetra.sensorsById[6]!,
        .button3: Tetra.sensorsById[7]!,
    ]
    // swiftlint:enable force_unwrapping
}

extension Tetra.Sensor {
    struct Value: Equatable {
        var sensor: Tetra.Sensor
        var rawValue: UInt

        init(sensor: Tetra.Sensor, rawValue: UInt) {
            self.sensor = sensor
            self.rawValue = rawValue
        }

        var digitalValue: Bool { rawValue <= 512 }
        var analogValue: Double { Double(rawValue) / 1023}

        var debugDescription: String {
            let valueString: String
            switch sensor.kind {
                case .light: valueString = "\(analogValue)"
                case .magnetic: valueString = "\(analogValue)"
                case .temperature: valueString = "\(analogValue)"
                case .infrared: valueString = "\(analogValue)"
                case .potentiometer: valueString = "\(analogValue)"
                case .motor: valueString = "\(analogValue)"
                case .button2: valueString = "\(digitalValue ? "pressed" : "not pressed")"
                case .button3: valueString = "\(digitalValue ? "pressed" : "not pressed")"
                case .unknown: valueString = "\(analogValue)"
            }
            return "\(sensor.kind): \(valueString)"
        }

        static func == (lhs: Value, rhs: Value) -> Bool {
            lhs.sensor == rhs.sensor && abs(Int(lhs.rawValue) - Int(rhs.rawValue)) <= lhs.sensor.tolerance
        }
    }
}
