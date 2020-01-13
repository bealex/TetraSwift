//
// MockDevicePort
// TetraSwift
//
// Created by Alex Babaev on 17 December 2019.
//

import Foundation

class MockDevicePort: DevicePort {
    private(set) var isOpened: Bool = false

    private var protocolImplementation: ArduinoProtocolImplementation!

    init() {
        protocolImplementation = TetraArduinoProtocolImplementation { bytes in
            self.bufferQueue.async(flags: .barrier) {
                self.buffer.append(contentsOf: bytes)
            }
        }
    }

    func open() throws {
        isOpened = true
    }

    func close() {
        isOpened = false
    }

    private var buffer: [UInt8] = []
    private var bufferQueue: DispatchQueue = DispatchQueue.global()

    func readBytes(exact count: Int) throws -> [UInt8] {
        guard isOpened else { throw DevicePortError.read(nil) }
        guard count > 0 else { return [] }

        var bufferCount: Int = 0
        bufferQueue.sync { bufferCount = buffer.count }

        while bufferCount < count {
            bufferQueue.sync { bufferCount = buffer.count }
        }

        let result = Array(buffer.prefix(count))
        bufferQueue.async(flags: .barrier) {
            self.buffer = Array(self.buffer.dropFirst(count))
        }

        return result
    }

    func readBytes(upTo count: Int) throws -> [UInt8] {
        guard isOpened else { throw DevicePortError.write(nil) }
        guard count > 0 else { return [] }

        let randomCount = Int.random(in: 0 ... count)
        let result = Array(buffer.prefix(randomCount))
        bufferQueue.async(flags: .barrier) {
            self.buffer = Array(self.buffer.dropFirst(randomCount))
        }

        return result
    }

    func writeBytes(_ data: [UInt8]) throws {
        guard isOpened else { throw DevicePortError.write(nil) }

        protocolImplementation.write(bytes: data)
    }
}
