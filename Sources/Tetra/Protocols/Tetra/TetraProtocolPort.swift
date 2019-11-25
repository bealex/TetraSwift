//
// TetraProtocolPort
// TetraCode
//
// Created by Alex Babaev on 25 November 2019.
// Copyright (c) 2019 LonelyBytes. All rights reserved.
//

import Foundation

extension TetraBoard {
    struct IOPort {
        enum Kind {
            case analogInput
            case analogOutput
            case digitalInput
            case digitalOutput

            init?(from code: UInt8) {
                switch code {
                    case 0b00000000: self = .analogInput
                    case 0b00000001: self = .analogOutput
                    case 0b00000010: self = .digitalInput
                    case 0b00000011: self = .digitalOutput
                    default: return nil
                }
            }

            var code: UInt8 {
                switch self {
                    case .analogInput: return 0b00000000
                    case .analogOutput: return 0b00000001
                    case .digitalInput: return 0b00000010
                    case .digitalOutput: return 0b00000011
                }
            }
        }

        var id: UInt8
        var kind: Kind

        init?(id: UInt8, kindCode: UInt8) {
            guard let kind = Kind(from: kindCode) else { return nil }

            self.id = id
            self.kind = kind
        }
    }
}
