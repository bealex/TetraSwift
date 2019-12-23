//
// TetraProtocolCommand
// TetraCode
//
// Created by Alex Babaev on 25 November 2019.
// Copyright (c) 2019 LonelyBytes. All rights reserved.
//

import Foundation

extension TetraProtocol {
    struct Packet {
        enum Command: UInt8, Equatable {
            case handshake = 0
            case configuration = 1
            case sensors = 2
            case singleActuator = 3
            case allActuators = 4
            case quadDisplay = 5
            case ledMatrix = 6

            case uIntValue = 10
            case stringValue = 11
            case characterValue = 12
        }

        let command: Command
        let data: [UInt8]
    }
}
