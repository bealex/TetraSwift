//
// TetraProtocolPort
// TetraCode
//
// Created by Alex Babaev on 25 November 2019.
// Copyright (c) 2019 LonelyBytes. All rights reserved.
//

import Foundation

extension TetraProtocol {
    struct IOPort {
        enum Kind {
            case analogInput
            case analogOutput
            case digitalInput
            case digitalOutput

            init?(from code: UInt8) {
                switch code {
                    case 0: self = .analogInput
                    case 1: self = .analogOutput
                    case 2: self = .digitalInput
                    case 3: self = .digitalOutput
                    default: return nil
                }
            }

            var code: UInt8 {
                switch self {
                    case .analogInput: return 0
                    case .analogOutput: return 1
                    case .digitalInput: return 2
                    case .digitalOutput: return 3
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
