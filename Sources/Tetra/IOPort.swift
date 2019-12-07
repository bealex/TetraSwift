//
// IOPort
// TetraCode
//
// Created by Alex Babaev on 24 November 2019.
// Copyright (c) 2019 LonelyBytes. All rights reserved.
//

public enum IOPort: Hashable, CustomDebugStringConvertible {
    case analog0
    case analog1
    case analog2
    case analog3
    case analog4
    case analog5

    // digital0 and digital1 are somewhere in the serial usage
    case digital2
    case digital3
    case digital4
    case digital5
    case digital6
    case digital7
    case digital8
    case digital9
    case digital10
    case digital11
    case digital12
    case digital13

    init?(sensorTetraId: UInt8) {
        switch sensorTetraId {
            case 0: self = .analog0
            case 1: self = .analog1
            case 2: self = .analog2
            case 3: self = .analog3
            case 4: self = .analog4
            case 5: self = .analog5
            case 6: self = .digital6
            case 7: self = .digital7
            default:
                fatalError("Got unknown Tetra Sensor ID")
        }
    }

    var tetraId: UInt8 {
        switch self {
            case .analog0: return 0
            case .analog1: return 1
            case .analog2: return 2
            case .analog3: return 3
            case .analog4: return 4
            case .analog5: return 5

            case .digital2: return 2
            case .digital3: return 3
            case .digital4: return 4
            case .digital5: return 5
            case .digital6: return 6
            case .digital7: return 7
            case .digital8: return 8
            case .digital9: return 9
            case .digital10: return 10
            case .digital11: return 11
            case .digital12: return 12
            case .digital13: return 13
        }
    }

    public var debugDescription: String {
        switch self {
            case .analog0: return "@a0"
            case .analog1: return "@a1"
            case .analog2: return "@a2"
            case .analog3: return "@a3"
            case .analog4: return "@a4"
            case .analog5: return "@a5"

            case .digital6: return "@d6"
            case .digital7: return "@d7"

            case .digital5: return "#a5"
            case .digital2: return "#a6"
            case .digital9: return "#a9"
            case .digital4: return "#m4"
            case .digital3: return "#m7"
            case .digital8: return "#m8"
            case .digital10: return "#m10"
            case .digital11: return "#m11"
            case .digital12: return "#m12"
            case .digital13: return "#m13"
        }
    }

    var tetraName: String {
        switch self {
            case .analog0: return "Analog Sensor 5"
            case .analog1: return "Analog Sensor 1"
            case .analog2: return "Analog Sensor 2"
            case .analog3: return "Analog Sensor 3"
            case .analog4: return "Analog Sensor 4"
            case .analog5: return "N/A"

            case .digital6: return "Digital Sensor 2"
            case .digital7: return "Digital Sensor 3"

            case .digital5: return "Analog 5"
            case .digital2: return "Analog 6"
            case .digital9: return "Analog 9"
            case .digital4: return "Motor 4"
            case .digital3: return "Motor 7"
            case .digital8: return "Motor 8"
            case .digital10: return "Digital 10"
            case .digital11: return "Digital 11"
            case .digital12: return "Digital 12"
            case .digital13: return "Digital 13"
        }
    }
}
