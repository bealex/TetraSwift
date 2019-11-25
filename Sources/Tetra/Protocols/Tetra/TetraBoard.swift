//
// Tetra
// TetraBoard
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
class TetraBoard: ArduinoBoard {
    private struct Configuration {
        var analogInputs: [IOPort]
        var analogOutputs: [IOPort]
        var digitalInputs: [IOPort]
        var digitalOutputs: [IOPort]

        var sensorsPacketByteSize: Int {
            analogOutputs.count * 2 + digitalOutputs.count
        }

        init(ports: [IOPort]) {
            analogInputs = ports.filter { $0.kind == .analogInput }
            analogOutputs = ports.filter { $0.kind == .analogOutput }
            digitalInputs = ports.filter { $0.kind == .digitalInput }
            digitalOutputs = ports.filter { $0.kind == .digitalOutput }
        }

        func areConfigured(kind: IOPort.Kind, ids: [UInt8]) -> Bool {
            ids.allSatisfy { id in
                switch kind {
                    case .analogInput: return analogInputs.contains { $0.id == id }
                    case .analogOutput: return analogOutputs.contains { $0.id == id }
                    case .digitalInput: return digitalInputs.contains { $0.id == id }
                    case .digitalOutput: return digitalOutputs.contains { $0.id == id }
                }
            }
        }
    }

    private enum State: Equatable {
        case initial // need to send handshake
        case awaitingConfiguration // need to receive configuration
        case receivingData // receive sensors, send actuators
    }

    static let version: UInt8 = 1

    private let debug: Bool = true

    private let serialPort: SerialPort
    private let handleSensorData: ([(portId: UInt8, value: UInt)]) -> Void
    private let handleError: (String) -> Void

    required init(
        serialPort: SerialPort,
        errorHandler: @escaping (String) -> Void,
        sensorDataHandler: @escaping ([(portId: UInt8, value: UInt)]) -> Void
    ) {
        self.serialPort = serialPort
        self.handleSensorData = sensorDataHandler
        self.handleError = errorHandler
    }

    // MARK: - Lifecycle

    private var state: State = .initial

    private var configuration: Configuration = Configuration(ports: [])
    private let workQueue: DispatchQueue = DispatchQueue(label: "tetra.protocol", qos: .default)

    func start() {
        guard state == .initial else { fatalError("Can't start protocol from non-initial state") }

        buffer = []

        state = .awaitingConfiguration
        workQueue.async(execute: loop)
        log(message: "Started")
        send(data: [ Packet.Command.handshake.code, TetraBoard.version ])
        log(message: "Sent handshake")
    }

    private func loop() {
        guard state != .initial else { return }

        receive()
        workQueue.async(execute: loop)
    }

    func stop() {
        state = .initial
        buffer = []
        log(message: "Stopped")
    }

    // MARK: - Sending

    func sendActuator(portId: UInt8, rawValue: UInt) {
        let data: [UInt8] =
            [ Packet.Command.singleActuator.code ] +
            [ portId, UInt8(rawValue & 0b11111111) ]
        self.send(data: data)
        log(message: "Sent actuator \(portId)")
    }

    func sendAllActuators(analog: [(portId: UInt8, value: UInt)], digital: [(portId: UInt8, value: UInt)]) {
        guard
            configuration.areConfigured(kind: .analogInput, ids: analog.map { $0.portId }),
            configuration.areConfigured(kind: .digitalInput, ids: digital.map { $0.portId })
        else {
            fatalError("Can't send actuator data, because it does not correspond to port configuration")
        }

        let data: [UInt8] =
            [ Packet.Command.allActuators.code ] +
            analog.flatMap { [ UInt8($0.value & 0b11111111) ] } +
            digital.flatMap { [ $0.value == 0 ? 0 : 1 ] }
        workQueue.async { self.send(data: data) }
        log(message: "Sent all actuators")
    }

    private func send(data: [UInt8]) {
        guard state != .initial else { return }

        workQueue.async {
            do {
                var bytes = data
                while !bytes.isEmpty {
                    let sent = try self.serialPort.writeBytes(from: bytes, size: bytes.count)
                    if sent > 0 {
                        bytes = Array(bytes.dropFirst(sent))
                    } else if sent < 0 {
                        self.handleError("Error writing: writeBytes returned -1")
                        break
                    }
                }
            } catch {
                self.handleError("Error writing: \(error)")
            }
        }
    }

    // MARK: - Receiving

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
                guard command == .configuration else { fatalError("Got wrong command (\(command)) in awaitingConfiguration state") }

                processConfigurationPayload()
            case .receivingData:
                guard command == .sensors else { fatalError("Got wrong command (\(command)) in receivingData state") }

                processSensorDataPayload()
            case .initial:
                break
        }
    }

    /**
        Code: 1 byte (0b00000001), Version: 1 byte, Ports count: 1 byte, Ports configuration: (count * 2) bytes
     */
    private func processConfigurationPayload() {
        guard buffer.count >= 3 /* code, version, count */ else { return }
        guard buffer[1] == TetraBoard.version else { fatalError("Got wrong version (\(buffer[1])), need: \(TetraBoard.version)") }

        let portsCount = Int(buffer[2])
        if portsCount != 0 {
            let fullPayloadSize = 3 + portsCount * 2
            if buffer.count >= fullPayloadSize {
                let ports: [IOPort] = (0 ..< portsCount).compactMap { IOPort(id: buffer[3 + $0 * 2], kindCode: buffer[3 + $0 * 2 + 1]) }
                guard ports.count == portsCount else { fatalError("Got \(portsCount) ports, but could process only \(ports.count)") }

                configuration = Configuration(ports: ports)
                buffer = Array(buffer.dropFirst(fullPayloadSize))
                state = .receivingData
            }
        } else {
            handleError("Protocol is OK, but we've got no ports as configuration.")
            state = .receivingData
        }

        log(message: "Got configuration")
    }

    private func processSensorDataPayload() {
        let fullPayloadSize = 1 + configuration.sensorsPacketByteSize
        guard buffer.count >= fullPayloadSize else { return }

        let digitalFirstIndex = 1 + configuration.analogOutputs.count * 2

        let analogValues = configuration.analogOutputs
            .enumerated()
            .map { index, port in
                (portId: port.id, value: (UInt(buffer[1 + index * 2]) << 8) | UInt(buffer[1 + index * 2 + 1]))
            }
        let digitalValues = configuration.digitalOutputs
            .enumerated()
            .map { index, port in
                (portId: port.id, value: UInt(buffer[digitalFirstIndex + index]))
            }

        handleSensorData(analogValues + digitalValues)
        buffer = Array(buffer.dropFirst(fullPayloadSize))
    }

    // MARK: - Utilities

    private func log(message: String) {
        if debug {
            print("Board | \(message)")
        }
    }
}
