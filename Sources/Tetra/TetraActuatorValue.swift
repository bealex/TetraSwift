//
// TetraActuatorValue
// TetraCode
//
// Created by Alex Babaev on 22 November 2019.
// Copyright (c) 2019 LonelyBytes. All rights reserved.
//

import Foundation

enum TetraActuatorValue {
    case motor4(UInt) // ???
    case motor7(UInt) // ???
    case motor8(UInt) // ???

    case buzzer(UInt) // Led?

    case ledAnalog5(UInt) // ???
    case ledAnalog6(UInt) // ???

    case ledDigital10(Bool) // ???
    case ledDigital11(Bool) // ???
    case ledDigital12(Bool) // ???
    case ledDigital13(Bool) // ???

    var data: (sensorId: UInt8, value: UInt) {
        let sensorId: UInt8
        let newValue: UInt
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
            case .buzzer(let value):
                sensorId = 9
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
        return (sensorId: sensorId, value: newValue)
    }
}
