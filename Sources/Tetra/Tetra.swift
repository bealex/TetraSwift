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

    private var sensors: [IOPort: Sensing] = [:]
    private var actuators: [IOPort: Acting] = [:]

    public func install(sensors: [IOPort: Sensing]) {
        for (port, sensor) in sensors {
            self.sensors[port] = sensor

            lightSensors.set(sensor as? LightSensor, for: port)
            potentiometers.set(sensor as? Potentiometer, for: port)
            magneticSensors.set(sensor as? MagneticSensor, for: port)
            temperatureSensors.set(sensor as? TemperatureSensor, for: port)
            infraredSensors.set(sensor as? InfraredSensor, for: port)
            buttons.set(sensor as? Button, for: port)
        }
    }

    public func install(actuators: [IOPort: Acting]) {
        for (port, actuator) in actuators {
            self.actuators[port] = actuator

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

        var sensor: Sensing
        var port: IOPort
        var condition: (Sensing) -> Bool
        var action: () -> Void
        var executeOnlyOnce: Bool

        var semaphore: DispatchSemaphore?
    }

    private var sensorListeners: [SensorListener] = []

    private func listen(
        for sensor: Sensing, on port: IOPort, condition: @escaping (Sensing) -> Bool, action: @escaping () -> Void,
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

    private func notifySensorListenersAboutUpdate(of sensor: Sensing, on port: IOPort) {
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
    private func sleep(
        until sensor: AnalogSensing, on port: IOPort? = nil,
        matches condition: @escaping (AnalogSensing) -> Bool,
        then: @escaping () -> Void
    ) {
        guard let port = port ?? findPort(for: sensor) else { fatalError("Can't find port for \(sensor)") }

        let condition: (Sensing) -> Bool = { ($0 as? AnalogSensing).map(condition) ?? false }
        listen(for: sensor, on: port, condition: condition, action: then, waitUntilDone: true, executedOnlyOnce: true)
    }

    private func sleep(
        until sensor: DigitalSensing, on port: IOPort? = nil,
        matches condition: @escaping (DigitalSensing) -> Bool,
        then: @escaping () -> Void
    ) {
        guard let port = port ?? findPort(for: sensor) else { fatalError("Can't find port for \(sensor)") }

        let condition: (Sensing) -> Bool = { ($0 as? DigitalSensing).map(condition) ?? false }
        listen(for: sensor, on: port, condition: condition, action: then, waitUntilDone: true, executedOnlyOnce: true)
    }

    private func when(
        _ sensor: AnalogSensing, on port: IOPort? = nil,
        matches condition: @escaping (AnalogSensing) -> Bool,
        do action: @escaping () -> Void
    ) {
        guard let port = port ?? findPort(for: sensor) else { fatalError("Can't find port for \(sensor)") }

        let condition: (Sensing) -> Bool = { ($0 as? AnalogSensing).map(condition) ?? false }
        listen(for: sensor, on: port, condition: condition, action: action, waitUntilDone: false, executedOnlyOnce: false)
    }

    private func when(
        _ sensor: DigitalSensing, on port: IOPort? = nil,
        matches condition: @escaping (DigitalSensing) -> Bool,
        do action: @escaping () -> Void
    ) {
        guard let port = port ?? findPort(for: sensor) else { fatalError("Can't find port for \(sensor)") }

        let condition: (Sensing) -> Bool = { ($0 as? DigitalSensing).map(condition) ?? false }
        listen(for: sensor, on: port, condition: condition, action: action, waitUntilDone: false, executedOnlyOnce: false)
    }

    private func findPort(for sensor: Sensing) -> IOPort? {
        sensors.first { $1.id == sensor.id }?.key
    }
}

public extension Tetra {
    func sleep(untilIsOn sensor: DigitalSensing, on port: IOPort? = nil, then action: @escaping () -> Void) {
        sleep(until: sensor, on: port, matches: { _ in sensor.value }, then: action)
    }

    func sleep(untilIsOff sensor: DigitalSensing, on port: IOPort? = nil, then action: @escaping () -> Void) {
        sleep(until: sensor, on: port, matches: { _ in !sensor.value }, then: action)
    }

    func sleep(until sensor: AnalogSensing, on port: IOPort? = nil, is value: Double, delta: Double, then action: @escaping () -> Void) {
        sleep(until: sensor, on: port, matches: { abs($0.value - value) < delta }, then: action)
    }

    func sleep(until sensor: AnalogSensing, on port: IOPort? = nil, isLessThan value: Double, then action: @escaping () -> Void) {
        sleep(until: sensor, on: port, matches: { $0.value < value }, then: action)
    }

    func sleep(until sensor: AnalogSensing, on port: IOPort? = nil, isGreaterThan value: Double, then action: @escaping () -> Void) {
        sleep(until: sensor, on: port, matches: { $0.value > value }, then: action)
    }

    func whenOn(_ sensor: BooleanDigitalSensor, on port: IOPort? = nil, action: @escaping () -> Void) {
        when(sensor, on: port, matches: { _ in sensor.value }, do: action)
    }

    func whenSensorIsOff(_ sensor: BooleanDigitalSensor, on port: IOPort? = nil, action: @escaping () -> Void) {
        when(sensor, on: port, matches: { _ in !sensor.value }, do: action)
    }

    func when(_ sensor: AnalogSensing, on port: IOPort? = nil, is value: Double, delta: Double, action: @escaping () -> Void) {
        when(sensor, on: port, matches: { abs($0.value - value) < delta }, do: action)
    }

    func when(_ sensor: AnalogSensing, on port: IOPort? = nil, isLessThan value: Double, action: @escaping () -> Void) {
        when(sensor, on: port, matches: { $0.value < value }, do: action)
    }

    func when(_ sensor: AnalogSensing, on port: IOPort? = nil, isGreaterThan value: Double, action: @escaping () -> Void) {
        when(sensor, on: port, matches: { $0.value > value }, do: action)
    }

    func on(_ sensor: Sensing, on port: IOPort? = nil, action: @escaping () -> Void) {
        guard let port = port ?? findPort(for: sensor) else { fatalError("Can't find port for \(sensor)") }

        listen(for: sensor, on: port, condition: { _ in true }, action: action, waitUntilDone: false, executedOnlyOnce: false)
    }
}
