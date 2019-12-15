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

    private var startedHandler: (() -> Void)?

    func start(completion: @escaping () -> Void) {
        guard state == .initial else { fatalError("Can't start protocol from non-initial state") }

        startedHandler = completion
        buffer = []
        handshake()
        loop()
        log(message: "Started")
        log(message: "Sent handshake")
    }

    private func handshake() {
        send(data: [ Packet.Command.handshake.rawValue, TetraBoard.version ]) {
            self.state = .awaitingConfiguration
        }
    }

    private func loop() {
        workQueue.async {
            guard self.state != .initial else { return }

            self.receive()
            self.loop()
        }
    }

    func stop() {
        state = .initial
        buffer = []
        log(message: "Stopped")
    }

    // MARK: - Sending

    func showOnQuadDisplay(portId: UInt8, value: String) {
        let isDigitalInput = configuration.digitalInputs.contains { $0.id == portId }
        let isAnalogInput = configuration.analogInputs.contains { $0.id == portId }
        guard isDigitalInput || isAnalogInput else { return handleError("Can't send value to other than input") }

        var value = value
        while value.replacingOccurrences(of: ".", with: "").count < 4 {
            value = " \(value)"
        }

        var bytes: [UInt8] = [ Packet.Command.quadDisplay.rawValue, portId ]
        value.forEach { character in
            if character == "." {
                if bytes.count > 2 {
                    bytes[bytes.count - 1] &= QuadDisplayHelper.digit_dot
                } else {
                    bytes.append(QuadDisplayHelper.digit_dot)
                }
            } else {
                if let encoded = QuadDisplayHelper.encode(character: character) {
                    bytes.append(encoded)
                }
            }
        }
        self.send(data: Array(bytes.prefix(6)))
        log(message: "Sent to quad display \(portId): \(value)")
    }

    // Brightness can be from 0 to 1, character — ASCII from 0 to 0x7f
    func showOnLEDMatrix(portId: UInt8, brightness: Double, character: Character) {
        let isDigitalInput = configuration.digitalInputs.contains { $0.id == portId }
        let isAnalogInput = configuration.analogInputs.contains { $0.id == portId }
        guard isDigitalInput || isAnalogInput else { return handleError("Can't send value to other than input") }

        let bytes: [UInt8] = [ Packet.Command.ledMatrix.rawValue, portId, LEDMatrixHelper.brightness(value: brightness) ] +
            LEDMatrixHelper.data(for: character)
        self.send(data: bytes)
        log(message: "Sent data to LED Matrix \(portId)")
    }

    func sendRawActuatorValue(portId: UInt8, rawValue: UInt) {
        let isDigitalInput = configuration.digitalInputs.contains { $0.id == portId }
        let isAnalogInput = configuration.analogInputs.contains { $0.id == portId }
        guard isDigitalInput || isAnalogInput else { return handleError("Can't send value to other than input") }

        let rawValue = min(255, rawValue)
        let data: [UInt8] =
            [ Packet.Command.singleActuator.rawValue ] +
            [ portId, UInt8(rawValue & 0b11111111) ]
        self.send(data: data)
        log(message: "Sent actuator \(portId)")
    }

    private func send(data: [UInt8], completion: @escaping () -> Void = {}) {
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
                completion()
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
                processBuffer()
            }
        } catch {
            handleError("Error reading: \(error)")
        }
    }

    private func processBuffer() {
        guard !buffer.isEmpty, let command = Packet.Command(rawValue: buffer[0]) else { return }

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

                log(message: "Got configuration")
            }
        } else {
            handleError("Protocol is OK, but we've got no ports as configuration.")
            state = .receivingData

            log(message: "Got configuration")
        }

        if state == .receivingData {
            startedHandler?()
            startedHandler = nil
        }
    }

    private func processSensorDataPayload() {
        let fullPayloadSize = 1 + configuration.sensorsPacketByteSize
        guard buffer.count >= fullPayloadSize else { return }

        let digitalFirstIndex = 1 + configuration.analogOutputs.count * 2

        let analogValues = configuration.analogOutputs
            .enumerated()
            .filter { _, port in
                configuration.analogOutputs.contains { $0.id == port.id }
            }
            .map { index, port in
                (portId: port.id, value: (UInt(buffer[1 + index * 2]) << 8) | UInt(buffer[1 + index * 2 + 1]))
            }
        let digitalValues = configuration.digitalOutputs
            .enumerated()
            .filter { _, port in
                configuration.digitalOutputs.contains { $0.id == port.id }
            }
            .map { index, port in
                (portId: port.id, value: UInt(buffer[digitalFirstIndex + index] > 0 ? 1023 : 0))
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
