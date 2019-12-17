//
// Tetra
// TetraCode
//
// Created by Alex Babaev on 22 November 2019.
// Copyright (c) 2019 LonelyBytes. All rights reserved.
//

import Foundation

open class TetraInterface {
    private let serialPort: SerialPort
    private var opened = false

    private let eventQueue: DispatchQueue

    private var debug: Bool = true // TODO: Expose somehow

    private var arduinoBoard: ArduinoBoard!
    private var sensorHandlers: [IOPort: (_ value: Any) -> Void] = [:]

    public init(pathToSerialPort: String, useTetraProtocol: Bool, eventQueue: DispatchQueue = DispatchQueue.global()) {
        self.eventQueue = eventQueue
        serialPort = HardwareSerialPort(
            path: pathToSerialPort,
            receiveRate: .baud38400,
            transmitRate: .baud38400,
            minimumBytesToRead: 0
        )

        let sensorDataHandler: (UInt8, Any) -> Void = { id, value in
            guard let port = IOPort(sensorTetraId: id) else { return }

            self.sensorHandlers[port]?(value)
        }
        arduinoBoard = useTetraProtocol
            ? TetraBoard(serialPort: serialPort, errorHandler: log, sensorDataHandler: sensorDataHandler)
            : PicoBoard(serialPort: serialPort, errorHandler: log, sensorDataHandler: sensorDataHandler)
    }

    public func add<SensorType: Sensor>(sensor: SensorType, on port: IOPort) {
        self.sensorHandlers[port] = {
            // TODO: Catch error
            try? sensor.update(rawValue: $0)
        }
    }

    public func install(actuators: [IOPort: Actuator]) {
        for (port, actuator) in actuators {
            if let actuator = actuator as? LimitedAnalogActuator {
                actuator.changedListener = { self.arduinoBoard.sendRawActuatorValue(portId: port.tetraId, rawValue: actuator.rawValue) }
            } else if let actuator = actuator as? BooleanDigitalActuator {
                actuator.changedListener = {
                    self.arduinoBoard.sendRawActuatorValue(portId: port.tetraId, rawValue: actuator.rawValue)
                }
            } else if let actuator = actuator as? QuadNumericDisplayActuator {
                actuator.changedListener = { self.arduinoBoard.showOnQuadDisplay(portId: port.tetraId, value: actuator.value) }
            } else if let actuator = actuator as? LEDMatrixActuator {
                actuator.changedListener = {
                    self.arduinoBoard.showOnLEDMatrix(portId: port.tetraId, brightness: 0.01, character: actuator.value)
                }
            }
        }
    }

    public func run(execute: @escaping (TetraInterface) -> Void) {
        openSerialPort()
        guard opened else { return }

        var started: Bool = false

        DispatchQueue.global().async {
            self.arduinoBoard.start {
                self.log(message: "Started")
                started = true
            }
        }

        while !started {
            if !self.serialPort.isOpened {
                break
            }
            Thread.sleep(forTimeInterval: 0.1)
        }

        execute(self)
        while true {
            guard self.serialPort.isOpened else { break }

            Thread.sleep(forTimeInterval: 0.1)
        }
        self.stop()
    }

    public func sleep(_ time: TimeInterval) {
        log(message: " Sleep for \(time) sec")
        Thread.sleep(forTimeInterval: time)
    }

    // MARK: - Lifecycle methods

    private func stop() {
        arduinoBoard.stop()
        closeSerialPort()
        log(message: "Stopped")
    }

    private func openSerialPort() {
        do {
            try serialPort.openPort()
            opened = true
            log(message: "Port opened")
        } catch {
            log(message: "Error opening: \(error)")
        }
    }

    private func closeSerialPort() {
        serialPort.closePort()
        opened = false
    }

    // MARK: - Utility methods

    private func log(message: String) {
        if self.debug {
            print(message)
        }
    }
}
