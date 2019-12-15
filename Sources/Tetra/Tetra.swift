//
// Tetra
// TetraCode
//
// Created by Alex Babaev on 22 November 2019.
// Copyright (c) 2019 LonelyBytes. All rights reserved.
//

import Foundation

public class Tetra {
    private let serialPort: SerialPort
    private var opened = false

    private let workQueue: DispatchQueue = DispatchQueue(label: "tetra", qos: .default)
    private let eventQueue: DispatchQueue

    private var debug: Bool = true // TODO: Expose somehow

    // MARK: - Common accessors

    public private(set) var quadDisplayActuators: List<QuadNumericDisplayActuator> = List(type: "Quad Numeric Display Actuator")
    public private(set) var ledMatrixActuators: List<LEDMatrixActuator> = List(type: "LED Matrix Actuator")

    // MARK: - Typed accessors

    public private(set) var lightSensors: List<LightSensor> = List(type: "Light Sensor")
    public private(set) var magneticSensors: List<MagneticSensor> = List(type: "Magnetic Sensor")
    public private(set) var temperatureSensors: List<TemperatureSensor> = List(type: "Temperature Sensor")
    public private(set) var infraredSensors: List<InfraredSensor> = List(type: "Infrared Sensor")
    public private(set) var potentiometers: List<Potentiometer> = List(type: "Potentiometer")
    public private(set) var buttons: List<Button> = List(type: "Button")

    public private(set) var motors: List<Motor> = List(type: "Motor")
    public private(set) var buzzers: List<Buzzer> = List(type: "Buzzer")
    public private(set) var analogLEDs: List<AnalogLED> = List(type: "Analog LED")
    public private(set) var digitalLEDs: List<DigitalLED> = List(type: "Digital LED")

    // MARK: - Single device accessors

    public var lightSensor: LightSensor { lightSensors.single }
    public var magneticSensor: MagneticSensor { magneticSensors.single }
    public var temperatureSensor: TemperatureSensor { temperatureSensors.single }
    public var infraredSensor: InfraredSensor { infraredSensors.single }
    public var potentiometer: Potentiometer { potentiometers.single }

    public var button: Button { buttons.single }
    public var motor: Motor { motors.single }
    public var buzzer: Buzzer { buzzers.single }
    public var analogLED: AnalogLED { analogLEDs.single }
    public var digitalLED: DigitalLED { digitalLEDs.single }
    public var quadDisplay: QuadNumericDisplayActuator { quadDisplayActuators.single }
    public var ledMatrix: LEDMatrixActuator { ledMatrixActuators.single }

    private var arduinoBoard: ArduinoBoard!

    public init(pathToSerialPort: String, useTetraProtocol: Bool, eventQueue: DispatchQueue = DispatchQueue.global()) {
        self.eventQueue = eventQueue
        serialPort = HardwareSerialPort(path: pathToSerialPort)

        arduinoBoard = useTetraProtocol
            ? TetraBoard(serialPort: serialPort, errorHandler: log, sensorDataHandler: process(sensorData:))
            : PicoBoard(serialPort: serialPort, errorHandler: log, sensorDataHandler: process(sensorData:))
    }

    private var portToIdentifiable: [IOPort: IdentifiableDevice] = [:]
    private var portToUpdatableSensor: [IOPort: UpdatableSensor] = [:]

    public func install(sensors: [IOPort: IdentifiableDevice & UpdatableSensor]) {
        for (port, sensor) in sensors {
            self.portToIdentifiable[port] = sensor
            self.portToUpdatableSensor[port] = sensor

            lightSensors.set(sensor as? LightSensor, for: port)
            potentiometers.set(sensor as? Potentiometer, for: port)
            magneticSensors.set(sensor as? MagneticSensor, for: port)
            temperatureSensors.set(sensor as? TemperatureSensor, for: port)
            infraredSensors.set(sensor as? InfraredSensor, for: port)
            buttons.set(sensor as? Button, for: port)
        }
    }

    public func install(actuators: [IOPort: Actuator]) {
        for (port, actuator) in actuators {
            buzzers.set(actuator as? Buzzer, for: port)
            motors.set(actuator as? Motor, for: port)
            digitalLEDs.set(actuator as? DigitalLED, for: port)
            analogLEDs.set(actuator as? AnalogLED, for: port)
            quadDisplayActuators.set(actuator as? QuadNumericDisplayActuator, for: port)
            ledMatrixActuators.set(actuator as? LEDMatrixActuator, for: port)

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

    public func run(execute: @escaping () -> Void) {
        start()
        guard opened else { return stop() }

        execute()

        while portToUpdatableSensor.values.contains(where: { $0.hasListeners }) {
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

    private func port(for sensor: IdentifiableDevice) -> IOPort? {
        portToIdentifiable.first { $1.id == sensor.id }?.key
    }

    private func process(sensorData: [(portId: UInt8, value: UInt)]) {
        sensorData.forEach { data in
            guard
                let port = IOPort(sensorTetraId: data.portId),
                let updatable = portToUpdatableSensor[port]
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
