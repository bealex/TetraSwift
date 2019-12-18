//
// MockSerialPort
// TetraSwift
//
// Created by Alex Babaev on 17 December 2019.
//

import Foundation

class MockSerialPort: SerialPort {
    private(set) var isOpened: Bool = false

    func open() throws {
        isOpened = true
    }

    func close() {
        isOpened = false
    }

    private let mockDataBuffer: [UInt8] = [
        // TODO: ...
    ]

    func readBytes(exact count: Int) throws -> [UInt8] {
        guard isOpened else { throw SerialPortError.read(nil) }

        return []
    }

    func readBytes(upTo count: Int) throws -> [UInt8] {
        // TODO: get random bytes up to size from cyclic buffer
        guard isOpened else { throw SerialPortError.write(nil) }

        return []
    }

    func writeBytes(_ data: [UInt8]) throws {
        guard isOpened else { throw SerialPortError.write(nil) }


    }
}
