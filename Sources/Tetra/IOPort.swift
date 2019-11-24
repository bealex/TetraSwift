//
// IOPort
// TetraCode
//
// Created by Alex Babaev on 24 November 2019.
// Copyright (c) 2019 LonelyBytes. All rights reserved.
//

enum IOPort: Hashable, CustomDebugStringConvertible {
    case analogSensor1
    case analogSensor2
    case analogSensor3
    case analogSensor4
    case analogSensor5

    case unknownSensor5 // It is here, but I do not know what it is

    case digitalSensor2
    case digitalSensor3

    case analog5
    case analog6
    case analog9

    case motor4
    case motor7
    case motor8

    case digital10
    case digital11
    case digital12
    case digital13

    init?(sensorTetraId: UInt8) {
        switch sensorTetraId {
            case 0: self = .analogSensor5
            case 1: self = .analogSensor1
            case 2: self = .analogSensor2
            case 3: self = .analogSensor3
            case 4: self = .analogSensor4
            case 5: self = .unknownSensor5
            case 6: self = .digitalSensor2
            case 7: self = .digitalSensor3
            default:
                fatalError("Got unknown Tetra Sensor ID")
        }
    }

    var tetraId: UInt8 {
        switch self {
            case .analogSensor1: return 1
            case .analogSensor2: return 2
            case .analogSensor3: return 3
            case .analogSensor4: return 4
            case .unknownSensor5: return 5
            case .analogSensor5: return 0
            case .digitalSensor2: return 6
            case .digitalSensor3: return 7

            case .analog5: return 5
            case .analog6: return 6
            case .analog9: return 9
            case .motor4: return 4
            case .motor7: return 7
            case .motor8: return 8
            case .digital10: return 10
            case .digital11: return 11
            case .digital12: return 12
            case .digital13: return 13
        }
    }

    var debugDescription: String {
        switch self {
            case .analogSensor1: return "@a1"
            case .analogSensor2: return "@a2"
            case .analogSensor3: return "@a3"
            case .analogSensor4: return "@a4"
            case .unknownSensor5: return "@?5"
            case .analogSensor5: return "@a0"
            case .digitalSensor2: return "@d6"
            case .digitalSensor3: return "@d7"

            case .analog5: return "#a5"
            case .analog6: return "#a6"
            case .analog9: return "#a9"
            case .motor4: return "#m4"
            case .motor7: return "#m7"
            case .motor8: return "#m8"
            case .digital10: return "#m10"
            case .digital11: return "#m11"
            case .digital12: return "#m12"
            case .digital13: return "#m13"
        }
    }
}
