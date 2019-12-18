//
// SerialPort
// TetraCode
//
// Created by Alex Babaev on 21 November 2019.
// Copyright (c) 2019 LonelyBytes. All rights reserved.
//

import Foundation

public enum SerialPortError: Error {
    case failedToOpen
    case invalidPath
    case mustBeOpen
    case deviceNotConnected
}

// TODO: Generify this more, it must not be only Serial Port
public protocol SerialPort {
    var isOpened: Bool { get }

    func open() throws
    func close()
    func readBytes(into buffer: UnsafeMutablePointer<UInt8>, size: Int) throws -> Int
    func writeBytes(from buffer: UnsafePointer<UInt8>, size: Int) throws -> Int
}
