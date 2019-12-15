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

    private let workQueue: DispatchQueue = DispatchQueue(label: "tetra", qos: .default)
    private let eventQueue: DispatchQueue

    private var debug: Bool = true // TODO: Expose somehow

    private var arduinoBoard: ArduinoBoard!
    private var sensors: [IOPort: UpdatableSensor] = [:]

    public init(
        pathToSerialPort: String, useTetraProtocol: Bool, eventQueue: DispatchQueue = DispatchQueue.global(),
        sensors: [IOPort: IdentifiableDevice & UpdatableSensor],
        actuators: [IOPort: Actuator]
    ) {
        self.eventQueue = eventQueue
        serialPort = HardwareSerialPort(path: pathToSerialPort)

        arduinoBoard = useTetraProtocol
            ? TetraBoard(serialPort: serialPort, errorHandler: log, sensorDataHandler: process(sensorData:))
            : PicoBoard(serialPort: serialPort, errorHandler: log, sensorDataHandler: process(sensorData:))
        install(sensors: sensors)
        install(actuators: actuators)
    }

    public func install(sensors: [IOPort: IdentifiableDevice & UpdatableSensor]) {
        for (port, sensor) in sensors {
            self.sensors[port] = sensor
        }
    }

    public func install(actuators: [IOPort: Actuator]) {
        for (port, actuator) in actuators {
            if let actuator = actuator as? LimitedAnalogActuator {
                actuator.changedListener = { self.arduinoBoard.sendActuator(portId: port.tetraId, rawValue: actuator.rawValue) }
            } else if let actuator = actuator as? BooleanDigitalActuator {
                actuator.changedListener = {
                    self.arduinoBoard.sendActuator(portId: port.tetraId, rawValue: actuator.rawValue)
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
        start()
        guard opened else { return stop() }

        execute(self)

        while sensors.values.contains(where: { $0.hasListeners }) {
            if !serialPort.isOpened {
                break
            }
            Thread.sleep(forTimeInterval: 0.1)
        }
        stop()
    }

    public func sleep(_ time: TimeInterval) {
        log(message: " Sleep for \(time) sec")
        Thread.sleep(forTimeInterval: time)
    }

    // MARK: - Lifecycle methods

    private func start() {
        openSerialPort()
        guard opened else { return }

        arduinoBoard.start()
        log(message: "Started")
    }

    private func stop() {
        arduinoBoard.stop()
        closeSerialPort()
        log(message: "Stopped")
    }

    private func openSerialPort() {
        do {
            try serialPort.openPort()
            opened = true
            serialPort.setSettings(receiveRate: .baud38400, transmitRate: .baud38400, minimumBytesToRead: 0)
            log(message: "Port opened")
        } catch {
            log(message: "Error opening: \(error)")
        }
    }

    private func closeSerialPort() {
        serialPort.closePort()
        opened = false
    }

    // MARK: - Input and output

    private func process(sensorData: [(portId: UInt8, value: UInt)]) {
        sensorData.forEach { data in
            guard
                let port = IOPort(sensorTetraId: data.portId),
                let updatable = sensors[port]
            else { return }

            updatable.update(rawValue: data.value)
        }
    }

    // MARK: - Utility methods

    private func log(message: String) {
        if self.debug {
            print(message)
        }
    }
}
