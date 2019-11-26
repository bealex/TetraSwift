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
        enum Command: UInt8, Equatable {
            case handshake = 0
            case configuration = 1
            case sensors = 2
            case singleActuator = 3
            case allActuators = 4
            case display = 5
        }

        let command: Command
        let data: [UInt8]
    }
}
