//
// TetraActuatorValue
// TetraCode
//
// Created by Alex Babaev on 22 November 2019.
// Copyright (c) 2019 LonelyBytes. All rights reserved.
//

import Foundation

enum TetraActuatorValue {
    case motor4(Int) // ???
    case motor7(Int) // ???
    case motor8(Int) // ???

    case pwm9(Int) // Led?

    case ledAnalog5(Int) // ???
    case ledAnalog6(Int) // ???

    case ledDigital10(Bool) // ???
    case ledDigital11(Bool) // ???
    case ledDigital12(Bool) // ???
    case ledDigital13(Bool) // ???

    var bytes: [UInt8] {
        let sensorId: UInt8
        let newValue: Int
        switch self {
            case .motor4(let value):
                sensorId = 4
                newValue = value
            case .motor7(let value):
                sensorId = 7
                newValue = value
            case .motor8(let value):
                sensorId = 8
                newValue = value
            case .pwm9(let value):
                sensorId = 8
                newValue = value
            case .ledAnalog5(let value):
                sensorId = 5
                newValue = value
            case .ledAnalog6(let value):
                sensorId = 6
                newValue = value
            case .ledDigital10(let value):
                sensorId = 10
                newValue = value ? 1023 : 0
            case .ledDigital11(let value):
                sensorId = 11
                newValue = value ? 1023 : 0
            case .ledDigital12(let value):
                sensorId = 12
                newValue = value ? 1023 : 0
            case .ledDigital13(let value):
                sensorId = 13
                newValue = value ? 1023 : 0
        }

        // This is PicoBoard protocol, essentially all of it :-)
        return [
            UInt8(truncatingIfNeeded: 0b10000000 | (UInt(sensorId & 0b1111) << 3) | (UInt(newValue >> 7) & 0b111)),
            UInt8(truncatingIfNeeded: newValue & 0b1111111)
        ]
    }
}
