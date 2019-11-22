//
// Tetra
// TetraCode
//
// Created by Alex Babaev on 22 November 2019.
// Copyright (c) 2019 LonelyBytes. All rights reserved.
//

import Foundation

class Tetra {
    private let serialPort: SerialPort
    private var opened = false

    private let eventCallback: (TetraEvent) -> Void
    private let eventQueue: DispatchQueue

    init(pathToSerialPort: String, eventQueue: DispatchQueue, eventCallback: @escaping (TetraEvent) -> Void) {
        self.eventQueue = eventQueue
        self.eventCallback = eventCallback
        serialPort = SerialPort(path: "/dev/tty.usbmodem14801")
    }

    private var started: Bool = false

    func start() {
        started = true
        open()
        readLoop()
        eventCallback(.started)
    }

    func stop() {
        started = false
        close()
        eventCallback(.stopped)
    }

    func write(actuator: TetraActuatorValue) {
        DispatchQueue.global().sync {
            do {
                var toSend = actuator.bytes
                while !toSend.isEmpty {
                    let sent = try serialPort.writeBytes(from: toSend, size: toSend.count)
                    toSend = Array(toSend.dropFirst(sent))
                }
            } catch {
                eventCallback(.error("Error writing: \(error)"))
            }
        }
    }

    private func readLoop() {
        if opened {
            DispatchQueue.global().async {
                var buffer: [UInt8] = [ 0, 0 ]
                var bytes: [UInt8] = []
                while self.started {
                    do {
                        let readCount = try self.serialPort.readBytes(into: &buffer, size: 2 - bytes.count)
                        if readCount > 0 {
                            bytes.append(contentsOf: buffer[0 ..< readCount])
                        }

                        if bytes.count == 2 {
                            self.eventQueue.async {
                                self.eventCallback(.sensor(TetraSensorValue(bytes: buffer)))
                            }
                            bytes = []
                        }
                    } catch {
                        self.eventCallback(.error("Error writing: \(error)"))
                        self.stop()
                    }
                }
            }
        }
    }

    private func open() {
        do {
            try serialPort.openPort()
            opened = true
            serialPort.setSettings(receiveRate: .baud38400, transmitRate: .baud38400, minimumBytesToRead: 0)
            print("Port opened")
        } catch {
            eventCallback(.error("Error writing: \(error)"))
        }
    }

    private func close() {
        serialPort.closePort()
        opened = false
    }
}
