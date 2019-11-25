//
// TetraProtocol
// TetraCode
//
// Created by Alex Babaev on 25 November 2019.
// Copyright (c) 2019 LonelyBytes. All rights reserved.
//

import Foundation

/**
    Format:
     - code: ???
     — data (fixed size)

    Protocol:
        — Handshake
        — Configuration
        — Asynchronous send/receive data packets

    — Tetra receives handshake (16 bits)
        — Code: 00000000
        — Data:
            — Protocol version (00000001)
    — Tetra sends configuration (this is handshake. Until Tetra sends this message, ports are not configured)
        — Code: 00000001
        — Data consists of version, ports count and port configuration:
            — Version (00000001)
            — Ports count: 8 bits
            — For each port:
                — index (8 bits)
                — io type (8 bits), types are:
                    — analog input: 0b00000000
                    — analog output: 0b00000001
                    — digital input: 0b00000010
                    — digital output: 0b00000011
    — Tetra sends all sensors
        — Code: 00000010
        — Data:
            — all analog values (10 bits per value, 2 bytes per value)
            — all digital values (1 bit, 1 byte per value)
    — Tetra receives all actuator values
        — Code: 00000011
        — Data:
            — analog values (8 bits per value)
            — digital values (1 bit per value)
    byte1: 101
 */
class TetraProtocol {
    private struct Packet {
        enum Command: Equatable {
            case handshake
            case configuration
            case sensors
            case actuators

            init?(from code: UInt8) {
                switch code {
                    case 0b00000000: self = .handshake
                    case 0b00000001: self = .configuration
                    case 0b00000010: self = .sensors
                    case 0b00000011: self = .actuators
                    default: return nil
                }
            }

            var code: UInt8 {
                switch self {
                    case .handshake: return 0b00000000
                    case .configuration: return 0b00000001
                    case .sensors: return 0b00000010
                    case .actuators: return 0b00000011
                }
            }
        }

        let command: Command
        let data: [UInt8]
    }

    private enum State: Equatable {
        case initial // need to send handshake
        case awaitingConfiguration // need to receive configuration
        case receivingSensorData // receive sensors, send actuators
    }

    private struct PortInfo {
        enum Port {
            case analogInput
            case analogOutput
            case digitalInput
            case digitalOutput

            init?(from code: UInt8) {
                switch code {
                    case 0b00000000: self = .analogInput
                    case 0b00000001: self = .analogOutput
                    case 0b00000010: self = .digitalInput
                    case 0b00000011: self = .digitalOutput
                    default: return nil
                }
            }

            var code: UInt8 {
                switch self {
                    case .analogInput: return 0b00000000
                    case .analogOutput: return 0b00000001
                    case .digitalInput: return 0b00000010
                    case .digitalOutput: return 0b00000011
                }
            }
        }

        var index: UInt8
        var port: Port
    }

    private struct Configuration {
        var analogInputs: [PortInfo]
        var analogOutputs: [PortInfo]
        var digitalInputs: [PortInfo]
        var digitalOutputs: [PortInfo]

        init(ports: [PortInfo]) {
            analogInputs = ports.filter { $0.port == .analogInput }
            analogOutputs = ports.filter { $0.port == .analogOutput }
            digitalInputs = ports.filter { $0.port == .digitalInput }
            digitalOutputs = ports.filter { $0.port == .digitalOutput }
        }
    }

    static let version: UInt8 = 1

    var handleSensorData: ([(portIndex: UInt8, value: UInt)]) -> Void = { _ in }
    var handleError: (String) -> Void = { _ in }

    init(serialPort: SerialPort) {
        self.serialPort = serialPort
    }

    // MARK: - Lifecycle

    private var configuration: Configuration = Configuration(ports: [])
    private var state: State = .initial
    private let workQueue: DispatchQueue = DispatchQueue(label: "tetra.protocol", qos: .default)

    func start() {
        guard state == .initial else { fatalError("Can't start protocol from non-initial state") }

        sensorsPacketSize = 0
        buffer = []

        send(data: [ Packet.Command.handshake.code, TetraProtocol.version ])
        state = .awaitingConfiguration
        workQueue.async(execute: loop)
    }

    private func loop() {
        guard state != .initial else { return }

        receive()
        workQueue.async(execute: loop)
    }

    func stop() {
        state = .initial
        sensorsPacketSize = 0
        buffer = []
    }

    // MARK: - Sending

    func sendActuatorData(_ actuators: [(portIndex: UInt8, value: UInt)]) {
        var data: [UInt8] = [ Packet.Command.actuators.code ]
        configuration.analogInputs
            .forEach { portInfo in
                guard let actuator = actuators.first(where: { $0.portIndex == portInfo.index }) else { return }

                let actuatorData = [ portInfo.index, UInt8((actuator.value >> 8) & 0b11111111), UInt8(actuator.value & 0b11111111) ]
                data.append(contentsOf: actuatorData)
            }
        configuration.digitalInputs
            .forEach { portInfo in
                guard let actuator = actuators.first(where: { $0.portIndex == portInfo.index }) else { return }

                let actuatorData = [ portInfo.index, actuator.value == 0 ? 0 : 1 ]
                data.append(contentsOf: actuatorData)
            }

        workQueue.async { self.send(data: data) }
    }

    private func send(data: [UInt8]) {
        guard state != .initial else { return }

        do {
            var bytes = data
            while !bytes.isEmpty {
                let sent = try self.serialPort.writeBytes(from: bytes, size: bytes.count)
                bytes = Array(bytes.dropFirst(sent))
            }
        } catch {
            handleError("Error writing: \(error)")
        }
    }

    // MARK: - Receiving

    private var serialPort: SerialPort
    private var sensorsPacketSize: Int = 0
    private let bufferSize: Int = 32
    private var buffer: [UInt8] = []

    private func receive() {
        guard state != .initial else { return }

        var bytes: [UInt8] = Array(repeating: 0, count: bufferSize)
        do {
            let readCount = try serialPort.readBytes(into: &bytes, size: bufferSize)
            if readCount > 0 {
                buffer.append(contentsOf: bytes[0 ..< readCount])
            }
            processBuffer()
        } catch {
            handleError("Error reading: \(error)")
        }
    }

    private func processBuffer() {
        guard !buffer.isEmpty, let command = Packet.Command(from: buffer[0]) else { return }

        switch state {
            case .awaitingConfiguration:
                guard command == .configuration, buffer.count >= 3 /* code, version, count */ else {
                    fatalError("Got wrong command (\(command)) in awaitingConfiguration state")
                }
                guard buffer[1] == TetraProtocol.version else {
                    fatalError("Got wrong version (\(buffer[1])), need: \(TetraProtocol.version)")
                }

                let count = Int(buffer[2])
                if count != 0 {
                    if buffer.count >= 3 + count * 2 {
                        let ports = (0 ..< count)
                            .compactMap { index in
                                PortInfo.Port(from: buffer[3 + index + 1]).map { PortInfo(index: buffer[3 + index], port: $0) }
                            }
                        guard ports.count == count else {
                            fatalError("Got \(count) ports, but could process only \(ports.count)")
                        }

                        configuration = Configuration(ports: ports)
                        sensorsPacketSize = configuration.analogOutputs.count * 2 + configuration.digitalOutputs.count
                        buffer = Array(buffer.dropFirst(3 + count * 2))
                        state = .receivingSensorData
                    }
                } else {
                    handleError("Protocol is OK, but we've got no ports as configuration.")
                    state = .receivingSensorData
                }
            case .receivingSensorData:
                guard
                    command == .sensors,
                    buffer.count >= 1 + sensorsPacketSize
                else { fatalError("Got wrong command (\(command)) in receivingSensorData state") }

                let analogValues = configuration.analogOutputs
                    .enumerated()
                    .map { index, port in
                        (portIndex: port.index, value: (UInt(buffer[1 + index * 2]) << 8) | UInt(buffer[1 + index * 2 + 1]))
                    }
                let digitalValues = configuration.digitalOutputs
                    .enumerated()
                    .map { index, port in
                        (portIndex: port.index, value: (UInt(buffer[1 + index * 2]) << 8) | UInt(buffer[1 + index * 2 + 1]))
                    }

                buffer = Array(buffer.dropFirst(1 + sensorsPacketSize))
                handleSensorData(analogValues + digitalValues)
            case .initial:
                break
        }
    }
}
