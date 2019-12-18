//
// MockSerialPort
// TetraSwift
//
// Created by Alex Babaev on 17 December 2019.
//

import Foundation

class MockSerialPort: SerialPort {
    private(set) var isOpened: Bool = true

    func open() throws {}

    func close() {}

    private let mockDataBuffer: [UInt8] = [
        // TODO: ...
    ]

    func readBytes(into buffer: UnsafeMutablePointer<UInt8>, size: Int) throws -> Int {
        // TODO: get random bytes up to size from cyclic buffer
        0
    }

    func writeBytes(from buffer: UnsafePointer<UInt8>, size: Int) throws -> Int {
        // Do nothing, I guess
        0
    }
}
