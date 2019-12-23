//
// ProTetraBoard
// TetraSwift
//
// Created by Alex Babaev on 19 December 2019.
//

import SwiftProtobuf
import Foundation

class ProTetraProtocol: ArduinoProtocol {
    private enum State: Equatable {
        case initial
        case awaitingConfiguration
        case receivingMessages
    }

    static let version: Int32 = 1

    private let debug: Bool = true

    private let serialPort: SerialPort
    private let errorHandler: (String) -> Void
    private let sensorDataHandler: (_ portId: IOPort, _ parameter: Int32, _ value: Any) -> Void

    required init(
        serialPort: SerialPort,
        errorHandler: @escaping (String) -> Void,
        sensorDataHandler: @escaping (IOPort, Int32, Any) -> Void
    ) {
        self.serialPort = serialPort
        self.errorHandler = errorHandler
        self.sensorDataHandler = sensorDataHandler
    }

    private var state: State = .initial

    private let workQueue: DispatchQueue = DispatchQueue(label: "tetra.protocol", qos: .default)

    private var startedHandler: (() -> Void)?

    func start(completion: @escaping () -> Void) {
        guard state == .initial else { fatalError("Can't start protocol from non-initial state") }

        startedHandler = completion
        do {
            try handshake()
            loop()
            log(message: "Started")
            log(message: "Sent handshake")
        } catch {
            log(message: "Error during handshake: \(error)")
        }
    }

    private func handshake() throws {
        let command = ClientCommand.with {
            $0.handshake = ClientCommand.Handshake.with {
                $0.version = ProTetraProtocol.version
            }
        }
        try send(data: try command.serializedData())
    }

    private func loop() {
        workQueue.async {
            guard self.state != .initial else { return }

            do {
                try self.receive()
            } catch {
                self.log(message: "Error receiving packet: \(error)")
            }
            self.loop()
        }
    }

    func stop() {
        state = .initial
        log(message: "Stopped")
    }

    func send<ValueType>(parameter: Int32, value: ValueType, to port: IOPort) throws {
        let command = ClientCommand.with {
            $0.actuator = ClientCommand.Actuator.with {
                if let value = value as? UInt {
                    $0.integer = IntegerData.with {
                        $0.parameter = parameter
                        $0.value = Int32(value)
                    }
                } else if let value = value as? String {
                    $0.string = StringData.with {
                        $0.parameter = parameter
                        $0.value = value
                    }
                } else if let value = value as? Character {
                    $0.character = CharacterData.with {
                        $0.parameter = parameter
                        $0.value = Int32(value.asciiValue ?? 0)
                    }
                }
            }
        }
        try send(data: try command.serializedData())
    }

    // Packet is made out of not-more-than-255-byte parts.
    // Each part is "length (1 byte) - data - checksum".
    // There is 0 after all the parts.
    private func send(data: Data) throws {
        var data = data
        while !data.isEmpty {
            let prefix = data.prefix(255)
            let part = [ UInt8 ](prefix.prefix(255))
            try serialPort.writeBytes([ UInt8(prefix.count) ])
            try serialPort.writeBytes(part)
            try serialPort.writeBytes([ UInt8(checksum(part)) ])
            data = data.dropFirst(prefix.count)
        }
        try serialPort.writeBytes([ 0 ])
    }

    private func receive() throws {
        var packet: Data = Data()
        var checksumCorrect = true
        var count = Int(try serialPort.readBytes(exact: 1)[0])
        while count > 0 {
            let part = try serialPort.readBytes(exact: count)
            packet.append(contentsOf: part)
            let checksum = try serialPort.readBytes(exact: 1)[0]
            checksumCorrect = checksumCorrect && self.checksum(part) == checksum
            count = Int(try serialPort.readBytes(exact: 1)[0])
        }

        if !checksumCorrect {
            throw ArduinoProtocolError.communication
        } else {
            try process(packet: packet)
        }
    }

    // MARK: - Utilities

    private func process(packet: Data) throws {
        let command = try ArduinoCommand(serializedData: packet)
        guard let data = command.data else { throw ArduinoProtocolError.communication }

        switch data {
            case .configuration:
                // TODO:
                break
            case .sensors(let sensors):
                try sensors.data
                    .compactMap { sensorData in
                        sensorData.data.map { (sensorData.port, $0) }
                    }
                    .forEach { port, sensorData in
                        guard let port = UInt8(exactly: port).map(IOPort.init(sensorTetraId:)) else {
                            throw ArduinoProtocolError.decoding
                        }

                        switch sensorData {
                            case .integer(let data):
                                sensorDataHandler(port, data.parameter, data.value)
                            case .string(let data):
                                sensorDataHandler(port, data.parameter, data.value)
                            case .character(let data):
                                sensorDataHandler(port, data.parameter, data.value)
                        }
                    }
        }
    }

    private func checksum(_ data: [UInt8]) -> UInt8 {
        var crc: UInt8 = 0xff
        for value in data {
            crc ^= value
        }
        return crc
    }

    private func log(message: String) {
        if debug {
            print("Board | \(message)")
        }
    }
}
