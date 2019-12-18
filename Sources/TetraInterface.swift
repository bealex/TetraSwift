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

    public init(serialPort: SerialPort, useTetraProtocol: Bool, eventQueue: DispatchQueue = DispatchQueue.global()) {
        self.eventQueue = eventQueue
        self.serialPort = serialPort

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
            do {
                try sensor.update(rawValue: $0)
            } catch {
                self.log(message: "Error updating sensor value on port \(port): \(error)")
            }
        }
    }

    public func add<ActuatorType: Actuator>(actuator: ActuatorType, on port: IOPort) {
        actuator.changedListener = { value in
            do {
                try self.arduinoBoard.send(value: value, to: port)
            } catch {
                self.log(message: "Error sending actuator value to port \(port): \(error)")
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
            try serialPort.open()
            opened = true
            log(message: "Port opened")
        } catch {
            log(message: "Error opening: \(error)")
        }
    }

    private func closeSerialPort() {
        serialPort.close()
        opened = false
    }

    // MARK: - Utility methods

    private func log(message: String) {
        if self.debug {
            print(message)
        }
    }
}
