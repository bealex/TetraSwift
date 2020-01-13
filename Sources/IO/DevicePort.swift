//
// DevicePort
// TetraCode
//
// Created by Alex Babaev on 21 November 2019.
// Copyright (c) 2019 LonelyBytes. All rights reserved.
//

import Foundation

public enum DevicePortError: Error {
    case open(Error?)
    case read(Error?)
    case write(Error?)
}

public protocol DevicePort {
    var isOpened: Bool { get }

    func open() throws
    func close()

    func readBytes(exact count: Int) throws -> [UInt8]
    func readBytes(upTo count: Int) throws -> [UInt8]

    func writeBytes(_ data: [UInt8]) throws
}
