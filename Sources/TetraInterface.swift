//
// Tetra
// TetraCode
//
// Created by Alex Babaev on 22 November 2019.
// Copyright (c) 2019 LonelyBytes. All rights reserved.
//

import Foundation

open class TetraInterface {
    private var debug: Bool = true

    private let devicePort: DevicePort
    private var opened = false

    private var arduinoProtocol: ArduinoProtocol!
    private var sensorHandlers: [IOPort: (_ value: Any) -> Void] = [:]

    public init(devicePort: DevicePort, useTetraProtocol: Bool) {
        self.devicePort = devicePort

        let sensorDataHandler: (IOPort, Int32, Any) -> Void = { port, parameter, value in
            self.sensorHandlers[port]?(value)
        }
        arduinoProtocol = useTetraProtocol
            ? TetraProtocol(serialPort: devicePort, errorHandler: log, sensorDataHandler: sensorDataHandler)
            : PicoBoardProtocol(serialPort: devicePort, errorHandler: log, sensorDataHandler: sensorDataHandler)
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
                try self.arduinoProtocol.send(parameter: 0, value: value, to: port)
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
            self.arduinoProtocol.start {
                self.log(message: "Started")
                started = true
            }
        }

        while !started {
            guard devicePort.isOpened else { break }

            Thread.sleep(forTimeInterval: 0.1)
        }

        guard devicePort.isOpened else { return stop() }

        execute(self)

        while true {
            guard self.devicePort.isOpened else { break }

            Thread.sleep(forTimeInterval: 0.1)
        }
        stop()
    }

    public func sleep(_ time: TimeInterval) {
        log(message: " Sleep for \(time) sec")
        Thread.sleep(forTimeInterval: time)
    }

    // MARK: - Lifecycle methods

    private func openSerialPort() {
        do {
            try devicePort.open()
            opened = true
            log(message: "Port opened")
        } catch {
            log(message: "Error opening: \(error)")
        }
    }

    private func closeSerialPort() {
        devicePort.close()
        opened = false
    }

    private func stop() {
        arduinoProtocol.stop()
        closeSerialPort()
        log(message: "Stopped")
    }

    // MARK: - Utility methods

    private func log(message: String) {
        if self.debug {
            print(message)
        }
    }
}
