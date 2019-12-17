//
// Serial
// TetraCode
//
// Created by Alex Babaev on 21 November 2019.
// Copyright (c) 2019 LonelyBytes. All rights reserved.
//

import Foundation

enum SerialPortError: Error {
    case failedToOpen
    case invalidPath
    case mustReceiveOrTransmit
    case mustBeOpen
    case deviceNotConnected
}

protocol SerialPort {
    var isOpened: Bool { get }

    func openPort(toReceive receive: Bool, andTransmit transmit: Bool) throws
    func closePort()
    func readBytes(into buffer: UnsafeMutablePointer<UInt8>, size: Int) throws -> Int
    func writeBytes(from buffer: UnsafePointer<UInt8>, size: Int) throws -> Int
}

extension SerialPort {
    func openPort() throws {
        try openPort(toReceive: true, andTransmit: true)
    }
}
