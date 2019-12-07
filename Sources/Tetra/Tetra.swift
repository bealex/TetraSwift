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

    public private(set) var analogSensors: Devices<AnalogSensor> = Devices(type: "Analog Sensor")
    public private(set) var digitalSensors: Devices<DigitalSensor> = Devices(type: "Digital Sensor")

    public private(set) var analogActuators: Devices<AnalogActuator> = Devices(type: "Analog Actuator")
    public private(set) var digitalActuators: Devices<DigitalActuator> = Devices(type: "Digital Actuator")
    public private(set) var quadDisplayActuators: Devices<QuadNumericDisplayActuator> = Devices(type: "Quad Numeric Display Actuator")
    public private(set) var ledMatrixActuators: Devices<LEDMatrixActuator> = Devices(type: "LED Matrix Actuator")

    // MARK: - Typed accessors

    public private(set) var lightSensors: Devices<AnalogSensor> = Devices(type: "Light Sensor")
    public private(set) var magneticSensors: Devices<AnalogSensor> = Devices(type: "Magnetic Sensor")
    public private(set) var temperatureSensors: Devices<AnalogSensor> = Devices(type: "Temperature Sensor")
    public private(set) var motorSensors: Devices<AnalogSensor> = Devices(type: "Motor Sensor")
    public private(set) var infraredSensors: Devices<DigitalSensor> = Devices(type: "Infrared Sensor")
    public private(set) var potentiometers: Devices<AnalogSensor> = Devices(type: "Potentiometer")
    public private(set) var buttons: Devices<DigitalSensor> = Devices(type: "Button")

    public private(set) var motors: Devices<AnalogActuator> = Devices(type: "Motor")
    public private(set) var buzzers: Devices<AnalogActuator> = Devices(type: "Buzzer")
    public private(set) var analogLEDs: Devices<AnalogActuator> = Devices(type: "Analog LED")
    public private(set) var digitalLEDs: Devices<DigitalActuator> = Devices(type: "Digital LED")

    // MARK: - Single device accessors

    public var lightSensor: AnalogSensor { lightSensors.single }
    public var magneticSensor: AnalogSensor { magneticSensors.single }
    public var temperatureSensor: AnalogSensor { temperatureSensors.single }
    public var infraredSensor: DigitalSensor { infraredSensors.single }
    public var potentiometer: AnalogSensor { potentiometers.single }

    public var button: DigitalSensor { buttons.single }
    public var motor: AnalogActuator { motors.single }
    public var buzzer: AnalogActuator { buzzers.single }
    public var analogLED: AnalogActuator { analogLEDs.single }
    public var digitalLED: DigitalActuator { digitalLEDs.single }
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

    private var sensors: [IOPort: Sensor] = [:]
    private var actuators: [IOPort: Actuator] = [:]

    public func install(sensors: [IOPort: Sensor]) {
        for (port, sensor) in sensors {
            self.sensors[port] = sensor

            if let sensor = sensor as? AnalogSensor {
                analogSensors[port] = sensor
                switch sensor.kind {
                    case .light: lightSensors[port] = sensor
                    case .potentiometer: potentiometers[port] = sensor
                    case .magnetic: magneticSensors[port] = sensor
                    case .temperature: temperatureSensors[port] = sensor
                    case .infrared, .button: break
                }
            } else if let sensor = sensor as? DigitalSensor {
                digitalSensors[port] = sensor
                switch sensor.kind {
                    case .infrared: infraredSensors[port] = sensor
                    case .button: buttons[port] = sensor
                    case .light, .potentiometer, .magnetic, .temperature: break
                }
            }
        }
    }

    public func install(actuators: [IOPort: Actuator]) {
        for (port, actuator) in actuators {
            self.actuators[port] = actuator
            if let actuator = actuator as? AnalogActuator {
                analogActuators[port] = actuator
                actuator.changedListener = { self.arduinoBoard.sendActuator(portId: port.tetraId, rawValue: actuator.rawValue) }
                switch actuator.kind {
                    case .buzzer: buzzers[port] = actuator
                    case .motor: motors[port] = actuator
                    case .analogLED: analogLEDs[port] = actuator
                    case .digitalLED, .quadDisplay, .ledMatrix: break
                }
            } else if let actuator = actuator as? DigitalActuator {
                digitalActuators[port] = actuator
                actuator.changedListener = {
                    self.arduinoBoard.sendActuator(portId: port.tetraId, rawValue: actuator.rawValue)
                }
                switch actuator.kind {
                    case .digitalLED: digitalLEDs[port] = actuator
                    case .buzzer, .motor, .analogLED, .quadDisplay, .ledMatrix: break
                }
            } else if let actuator = actuator as? QuadNumericDisplayActuator {
                quadDisplayActuators[port] = actuator
                actuator.changedListener = { self.arduinoBoard.showOnQuadDisplay(portId: port.tetraId, value: actuator.value) }
                switch actuator.kind {
                    case .quadDisplay: quadDisplayActuators[port] = actuator
                    case .buzzer, .motor, .analogLED, .digitalLED, .ledMatrix: break
                }
            } else if let actuator = actuator as? LEDMatrixActuator {
                ledMatrixActuators[port] = actuator
                actuator.changedListener = {
                    self.arduinoBoard.showOnLEDMatrix(portId: port.tetraId, brightness: 0.01, character: actuator.value)
                }
                switch actuator.kind {
                    case .ledMatrix: ledMatrixActuators[port] = actuator
                    case .buzzer, .motor, .analogLED, .digitalLED, .quadDisplay: break
                }
            }
        }
    }

    public func run(execute: @escaping () -> Void) {
        start()
        guard opened else { return stop() }

        execute()

        while !sensorListeners.isEmpty {
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
        sensorListeners = []
        serialPort.closePort()
        opened = false
    }

    // MARK: - Input and output

    private func process(sensorData: [(portId: UInt8, value: UInt)]) {
        sensorData.forEach { data in
            guard let port = IOPort(sensorTetraId: data.portId), let sensor = sensors[port] else { return }

            if sensor.update(rawValue: data.value) {
                notifySensorListenersAboutUpdate(of: sensor, on: port)
            }
        }
    }

    // MARK: - Utility methods

    private func log(message: String) {
        if self.debug {
            print(message)
        }
    }

    // MARK: - Commands and conditions

    private struct SensorListener {
        var id: UUID = UUID()

        var sensor: Sensor
        var port: IOPort
        var condition: (Sensor) -> Bool
        var action: () -> Void
        var executeOnlyOnce: Bool

        var semaphore: DispatchSemaphore?
    }

    private var sensorListeners: [SensorListener] = []

    private func listen(
        for sensor: Sensor, on port: IOPort, condition: @escaping (Sensor) -> Bool, action: @escaping () -> Void,
        waitUntilDone: Bool, executedOnlyOnce: Bool
    ) {
        var listener = SensorListener(sensor: sensor, port: port, condition: condition, action: action, executeOnlyOnce: executedOnlyOnce)
        sensorListeners.append(listener)

        log(message: " + Condition for \(sensor) added")
        if waitUntilDone {
            listener.semaphore = DispatchSemaphore(value: 0)
            log(message: " . Waiting for \(sensor) event")
            listener.semaphore?.wait()
        }
    }

    private func notifySensorListenersAboutUpdate(of sensor: Sensor, on port: IOPort) {
        var listenerIdsToRemove: [UUID] = []
        sensorListeners.forEach { listener in
            if listener.port == port, listener.condition(sensor) {
                eventQueue.async {
                    self.log(message: " ! Condition for \(sensor) executed")
                    listener.action()
                    listener.semaphore?.signal()
                }
                if listener.executeOnlyOnce {
                    self.log(message: " - Condition for \(sensor) removed")
                    listenerIdsToRemove.append(listener.id)
                }
            }
        }

        sensorListeners = sensorListeners.filter { !listenerIdsToRemove.contains($0.id) }
    }
}

extension Tetra {
    private func eraseType<SensorType: Sensor>(on condition: @escaping (SensorType) -> Bool) -> (Sensor) -> Bool {
        // Comment to silence SwiftLint
        { sensor in
            if let typedSensor = sensor as? SensorType {
                return condition(typedSensor)
            } else {
                return false
            }
        }
    }

    private func sleep<SensorType: Sensor>(
        until sensor: SensorType, on port: IOPort? = nil,
        matches condition: @escaping (SensorType) -> Bool,
        then: @escaping () -> Void
    ) {
        guard let port = port ?? findPort(for: sensor) else { fatalError("Can't find port for \(sensor)") }

        listen(for: sensor, on: port, condition: eraseType(on: condition), action: then, waitUntilDone: true, executedOnlyOnce: true)
    }

    private func when<SensorType: Sensor>(
        _ sensor: SensorType, on port: IOPort? = nil,
        matches condition: @escaping (SensorType) -> Bool,
        do action: @escaping () -> Void
    ) {
        guard let port = port ?? findPort(for: sensor) else { fatalError("Can't find port for \(sensor)") }

        listen(for: sensor, on: port, condition: eraseType(on: condition), action: action, waitUntilDone: false, executedOnlyOnce: false)
    }

    private func findPort(for sensor: Sensor) -> IOPort? {
        sensors.first { $1.id == sensor.id }?.key
    }
}

public extension Tetra {
    func sleep(untilIsOn sensor: DigitalSensor, on port: IOPort? = nil, then action: @escaping () -> Void) {
        sleep(until: sensor, on: port, matches: { _ in sensor.value }, then: action)
    }

    func sleep(untilIsOff sensor: DigitalSensor, on port: IOPort? = nil, then action: @escaping () -> Void) {
        sleep(until: sensor, on: port, matches: { _ in !sensor.value }, then: action)
    }

    func sleep(until sensor: AnalogSensor, on port: IOPort? = nil, is value: Double, plusMinus: Double, then action: @escaping () -> Void) {
        sleep(until: sensor, on: port, matches: { abs($0.value - value) < plusMinus }, then: action)
    }

    func sleep(until sensor: AnalogSensor, on port: IOPort? = nil, isLessThan value: Double, then action: @escaping () -> Void) {
        sleep(until: sensor, on: port, matches: { $0.value < value }, then: action)
    }

    func sleep(until sensor: AnalogSensor, on port: IOPort? = nil, isGreaterThan value: Double, then action: @escaping () -> Void) {
        sleep(until: sensor, on: port, matches: { $0.value > value }, then: action)
    }

    func whenOn(_ sensor: DigitalSensor, on port: IOPort? = nil, action: @escaping () -> Void) {
        when(sensor, on: port, matches: { _ in sensor.value }, do: action)
    }

    func whenSensorIsOff(_ sensor: DigitalSensor, on port: IOPort? = nil, action: @escaping () -> Void) {
        when(sensor, on: port, matches: { _ in !sensor.value }, do: action)
    }

    func when(_ sensor: AnalogSensor, on port: IOPort? = nil, is value: Double, plusMinus: Double, action: @escaping () -> Void) {
        when(sensor, on: port, matches: { abs($0.value - value) < plusMinus }, do: action)
    }

    func when(_ sensor: AnalogSensor, on port: IOPort? = nil, isLessThan value: Double, action: @escaping () -> Void) {
        when(sensor, on: port, matches: { $0.value < value }, do: action)
    }

    func when(_ sensor: AnalogSensor, on port: IOPort? = nil, isGreaterThan value: Double, action: @escaping () -> Void) {
        when(sensor, on: port, matches: { $0.value > value }, do: action)
    }

    func on(_ sensor: Sensor, on port: IOPort? = nil, action: @escaping () -> Void) {
        guard let port = port ?? findPort(for: sensor) else { fatalError("Can't find port for \(sensor)") }

        listen(for: sensor, on: port, condition: { _ in true }, action: action, waitUntilDone: false, executedOnlyOnce: false)
    }
}
