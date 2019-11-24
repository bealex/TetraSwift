//
// PicoBoardProtocol
// TetraCode
//
// Created by Alex Babaev on 22 November 2019.
// Copyright (c) 2019 LonelyBytes. All rights reserved.
//

import Foundation

// This is PicoBoard protocol, essentially all of it :-)
class PicoBoardProtocol {
    func data(from bytes: [UInt8]) -> (id: UInt8, value: UInt) {
        let id = (bytes[0] >> 3) & 0b1111
        let value = (UInt((bytes[0] & 0b111)) << 7) | (UInt(bytes[1]) & 0b1111111)
        return (id, value)
    }

    func bytes(id: UInt8, value: UInt) -> [UInt8] {
        [
            UInt8(truncatingIfNeeded: 0b10000000 | (UInt(id & 0b1111) << 3) | (UInt(value >> 7) & 0b111)),
            UInt8(truncatingIfNeeded: value & 0b1111111)
        ]
    }
}
