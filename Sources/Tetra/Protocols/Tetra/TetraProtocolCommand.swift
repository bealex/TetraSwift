//
// TetraProtocolCommand
// TetraCode
//
// Created by Alex Babaev on 25 November 2019.
// Copyright (c) 2019 LonelyBytes. All rights reserved.
//

import Foundation

extension TetraBoard {
    struct Packet {
        enum Command: Equatable {
            case handshake
            case configuration
            case sensors
            case singleActuator
            case allActuators

            init?(from code: UInt8) {
                switch code {
                    case 0b00000000: self = .handshake
                    case 0b00000001: self = .configuration
                    case 0b00000010: self = .sensors
                    case 0b00000011: self = .singleActuator
                    case 0b00000100: self = .allActuators
                    default: return nil
                }
            }

            var code: UInt8 {
                switch self {
                    case .handshake: return 0b00000000
                    case .configuration: return 0b00000001
                    case .sensors: return 0b00000010
                    case .singleActuator: return 0b00000011
                    case .allActuators: return 0b00000100
                }
            }
        }

        let command: Command
        let data: [UInt8]
    }
}
