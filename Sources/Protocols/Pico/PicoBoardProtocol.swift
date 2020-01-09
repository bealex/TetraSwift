//
// PicoBoard
// TetraCode
//
// Created by Alex Babaev on 22 November 2019.
// Copyright (c) 2019 LonelyBytes. All rights reserved.
//

import Foundation

/**
    This is PicoBoard protocol. I do not have any source for it (except S4A Arduino Sketch that shows everything
    I want to know). Basics is like this (looks like source is https://github.com/sparkfun/PicoBoard):

    1. There are two parts: Arduino port index and value (that is being read or being written).
    2. Every protocol packet is 2 bytes. Bits in these are: 1 PPPP 0 VVVVVVVVVV, where
       - 1/0 — reserved bits. Don't know why do we need them (but they can be used for error checking)
       - PPPP — port index (4 bits, 16 ports)
       — VVVVVVVVVV — value (10 bits, values 0–1023)
    3. Port indexes mapping is below. It is defined in the Sketch, but here is default one for Tetra.
        0, 1, 2, 3 — inputs
        4, 7, 8 — motors
        5, 6, 9 — pulse width modulation pins (pwm), that can be used as kind-of-analog, but really are digital
        10, 11, 12, 13 — digital outputs
        Totally there are 14 ports by default.

    I consider this reference implementation: https://github.com/sparkfun/PicoBoard/blob/master/firmware/main.c
    ```
    void buildScratchPacket(char * packet, int channel, int value) {
        char upper_data = (char)((value & (unsigned int) 0x380) >> 7); //Get the upper 3 bits of the value
        char lower_data = (char)(value & 0x7f); //Get the lower 7 bits of the value
        *packet ++= ((1 << 7) | (channel << 3) | (upper_data));
        *packet ++= lower_data;
    }
    ```
 */

// This is PicoBoard protocol, essentially all of it :-)
class PicoBoardProtocol: ArduinoProtocol {
    private let serialPort: DevicePort
    private let handleError: (String) -> Void
    private let handleSensorData: (_ portId: IOPort, _ parameter: Int32, _ value: Any) -> Void

    required init(
        serialPort: DevicePort,
        errorHandler: @escaping (String) -> Void,
        sensorDataHandler: @escaping (_ portId: IOPort, _ parameter: Int32, _ value: Any) -> Void
    ) {
        self.serialPort = serialPort
        self.handleSensorData = sensorDataHandler
        self.handleError = errorHandler
    }

    // MARK: - Lifecycle

    private let workQueue: DispatchQueue = DispatchQueue(label: "picoBoard.protocol", qos: .default)
    private var started: Bool = false

    func start(completion: @escaping () -> Void) {
        started = true
        workQueue.async(execute: loop)
        completion()
    }

    func stop() {
        started = false
    }

    private var lastActuatorsUpdateTime: TimeInterval = 0

    private func loop() {
        receive()
        updateAllActuators()
        workQueue.async(execute: loop)
    }

    private func updateAllActuators() {
        let currentTime = Date.timeIntervalSinceReferenceDate
        if currentTime - lastActuatorsUpdateTime > 0.01 {
            lastActuatorsUpdateTime = currentTime
            lastActuatorRawValues.values.forEach { sendRawActuatorValue(portId: $0.portId, rawValue: $0.value) }
        }
    }

    // MARK: - Sending

    private var lastActuatorRawValues: [UInt8: (portId: UInt8, value: UInt)] = [:]

    func send<ValueType>(parameter: Int32, value: ValueType, to port: IOPort) throws {
        guard let value = value as? UInt else { throw ArduinoProtocolError.notSupported }
        guard started else { return }

        lastActuatorRawValues[port.tetraId] = (port.tetraId, value)
        send(encode(id: port.tetraId, value: value))
    }

    private func sendStringValue(portId: UInt8, value: String) {
        handleError("Quad Display is not implemented")
    }

    private func sendCharacterValue(portId: UInt8, brightness: Double, value: Character) {
        handleError("LED Matrix is not implemented")
    }

    private func sendRawActuatorValue(portId: UInt8, rawValue: UInt) {
        guard started else { return }

        lastActuatorRawValues[portId] = (portId, rawValue)
        send(encode(id: portId, value: rawValue))
    }

    private func send(_ data: [UInt8]) {
        workQueue.async {
            do {
                try self.serialPort.writeBytes(data)
            } catch {
                self.handleError("Error writing \(error)")
            }
        }
    }

    private func encode(id: UInt8, value: UInt) -> [UInt8] {
        [
            UInt8(truncatingIfNeeded: 0b10000000 | (UInt(id & 0b1111) << 3) | (UInt(value >> 7) & 0b111)),
            UInt8(truncatingIfNeeded: value & 0b1111111)
        ]
    }

    // MARK: - Receiving

    private func receive() {
        guard started else { return }

        do {
            let bytes = try self.serialPort.readBytes(exact: 2)
            let decoded = self.decode(from: bytes)
            self.handleSensorData(IOPort(sensorTetraId: decoded.portId), 0, decoded.value)
        } catch {
            self.handleError("Error reading: \(error)")
            self.stop()
        }
    }

    func decode(from bytes: [UInt8]) -> (portId: UInt8, value: UInt) {
        let id = (bytes[0] >> 3) & 0b1111
        let value = (UInt((bytes[0] & 0b111)) << 7) | (UInt(bytes[1]) & 0b1111111)
        return (id, value)
    }
}
