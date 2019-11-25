//
// ArduinoProtocol
// TetraCode
//
// Created by Alex Babaev on 25 November 2019.
// Copyright (c) 2019 LonelyBytes. All rights reserved.
//

import Foundation

protocol ArduinoProtocol {
    func decode(from bytes: [UInt8]) -> (id: UInt8, value: Int)
    func encode(id: UInt8, value: Int) -> [UInt8]
}
