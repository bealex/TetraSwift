//
// Tetra
// TetraCode
//
// Created by Alex Babaev on 22 November 2019.
// Copyright (c) 2019 LonelyBytes. All rights reserved.
//

import Foundation

class Tetra {
    private let serialPort: SerialPort
    private var opened = false

    private let workQueue: DispatchQueue = DispatchQueue(label: "tetra", qos: .default)
    private let eventQueue: DispatchQueue

    private var debug: Bool = true // TODO: Expose somehow

    // MARK: - Common accessors

    private(set) var analogSensors: Devices<AnalogSensor> = Devices(type: "Analog Sensor")
    private(set) var digitalSensors: Devices<DigitalSensor> = Devices(type: "Digital Sensor")

    private(set) var analogActuators: Devices<AnalogActuator> = Devices(type: "Analog Actuator")
    private(set) var digitalActuators: Devices<DigitalActuator> = Devices(type: "Digital Actuator")
    private(set) var displayActuators: Devices<QuadNumericDisplayActuator> = Devices(type: "Quad Numeric Display Actuator")

    // MARK: - Typed accessors

    private(set) var lightSensors: Devices<AnalogSensor> = Devices(type: "Light Sensor")
    private(set) var magneticSensors: Devices<AnalogSensor> = Devices(type: "Magnetic Sensor")
    private(set) var temperatureSensors: Devices<AnalogSensor> = Devices(type: "Temperature Sensor")
    private(set) var motorSensors: Devices<AnalogSensor> = Devices(type: "Motor Sensor")
    private(set) var infraredSensors: Devices<DigitalSensor> = Devices(type: "Infrared Sensor")
    private(set) var potentiometers: Devices<AnalogSensor> = Devices(type: "Potentiometer")
    private(set) var buttons: Devices<DigitalSensor> = Devices(type: "Button")

    private(set) var motors: Devices<AnalogActuator> = Devices(type: "Motor")
    private(set) var buzzers: Devices<AnalogActuator> = Devices(type: "Buzzer")
    private(set) var analogLEDs: Devices<AnalogActuator> = Devices(type: "Analog LED")
    private(set) var digitalLEDs: Devices<DigitalActuator> = Devices(type: "Digital LED")
    private(set) var quadDisplays: Devices<QuadNumericDisplayActuator> = Devices(type: "Quad Display")

    // MARK: - Single device accessors

    var lightSensor: AnalogSensor { lightSensors.single }
    var magneticSensor: AnalogSensor { magneticSensors.single }
    var temperatureSensor: AnalogSensor { temperatureSensors.single }
    var infraredSensor: DigitalSensor { infraredSensors.single }
    var potentiometer: AnalogSensor { potentiometers.single }

    var button: DigitalSensor { buttons.single }
    var motor: AnalogActuator { motors.single }
    var buzzer: AnalogActuator { buzzers.single }
    var analogLED: AnalogActuator { analogLEDs.single }
    var digitalLED: DigitalActuator { digitalLEDs.single }
    var quadDisplay: QuadNumericDisplayActuator { quadDisplays.single }

    private var arduinoBoard: ArduinoBoard!

    init(pathToSerialPort: String, useTetraProtocol: Bool, eventQueue: DispatchQueue) {
        self.eventQueue = eventQueue
        serialPort = HardwareSerialPort(path: pathToSerialPort)

        arduinoBoard = useTetraProtocol
            ? TetraBoard(serialPort: serialPort, errorHandler: log, sensorDataHandler: process(sensorData:))
            : PicoBoard(serialPort: serialPort, errorHandler: log, sensorDataHandler: process(sensorData:))
    }

    private var sensors: [IOPort: Sensor] = [:]
    private var actuators: [IOPort: Actuator] = [:]

    func installSensors(analog: [AnalogSensor], digital: [DigitalSensor]) {
        analog.forEach { sensor in
            analogSensors[sensor.port] = sensor
            sensors[sensor.port] = sensor
            switch sensor.kind {
                case .light: lightSensors[sensor.port] = sensor
                case .potentiometer: potentiometers[sensor.port] = sensor
                case .magnetic: magneticSensors[sensor.port] = sensor
                case .temperature: temperatureSensors[sensor.port] = sensor
                case .infrared, .button: break
            }
        }
        digital.forEach { sensor in
            digitalSensors[sensor.port] = sensor
            sensors[sensor.port] = sensor
            switch sensor.kind {
                case .infrared: infraredSensors[sensor.port] = sensor
                case .button: buttons[sensor.port] = sensor
                case .light, .potentiometer, .magnetic, .temperature: break
            }
        }
    }

    func installActuators(analog: [AnalogActuator], digital: [DigitalActuator], displays: [QuadNumericDisplayActuator]) {
        analog.forEach { actuator in
            actuators[actuator.port] = actuator
            analogActuators[actuator.port] = actuator
            actuator.changedListener = {
                self.arduinoBoard.sendActuator(portId: actuator.port.tetraId, rawValue: actuator.rawValue)
            }
            switch actuator.kind {
                case .buzzer: buzzers[actuator.port] = actuator
                case .motor: motors[actuator.port] = actuator
                case .analogLED: analogLEDs[actuator.port] = actuator
                case .digitalLED, .quadDisplay: break
            }
        }
        digital.forEach { actuator in
            actuators[actuator.port] = actuator
            digitalActuators[actuator.port] = actuator
            actuator.changedListener = {
                self.arduinoBoard.sendActuator(portId: actuator.port.tetraId, rawValue: actuator.rawValue)
            }
            switch actuator.kind {
                case .digitalLED: digitalLEDs[actuator.port] = actuator
                case .buzzer, .motor, .analogLED, .quadDisplay: break
            }
        }
        displays.forEach { actuator in
            actuators[actuator.port] = actuator
            displayActuators[actuator.port] = actuator
            // TODO: Restore
//            actuator.changedListener = { self.writeToQuadDisplay(id: actuator.port, string: actuator.value, silent: false) }
            switch actuator.kind {
                case .quadDisplay: quadDisplays[actuator.port] = actuator
                case .buzzer, .motor, .analogLED, .digitalLED: break
            }
        }
    }

    func run(execute: @escaping () -> Void) {
        start()
        guard opened else { return stop() }

        execute()

        while !sensorListeners.isEmpty {
            Thread.sleep(forTimeInterval: 0.1)
        }
        stop()
    }

    func sleep(_ time: TimeInterval) {
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
                notifySensorListenersAboutUpdate(of: sensor)
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
        var condition: (Sensor) -> Bool
        var action: () -> Void
        var executeOnlyOnce: Bool

        var semaphore: DispatchSemaphore?
    }

    private var sensorListeners: [SensorListener] = []

    private func addSensorListener(
        _ sensor: Sensor, condition: @escaping (Sensor) -> Bool, action: @escaping () -> Void,
        waitUntilDone: Bool, executedOnlyOnce: Bool
    ) {
        var listener = SensorListener(sensor: sensor, condition: condition, action: action, executeOnlyOnce: executedOnlyOnce)
        sensorListeners.append(listener)

        log(message: " + Condition for \(sensor) added")
        if waitUntilDone {
            listener.semaphore = DispatchSemaphore(value: 0)
            log(message: " . Waiting for \(sensor) event")
            listener.semaphore?.wait()
        }
    }

    private func notifySensorListenersAboutUpdate(of sensor: Sensor) {
        var listenerIdsToRemove: [UUID] = []
        sensorListeners.forEach { listener in
            if listener.sensor.port == sensor.port, listener.condition(sensor) {
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
        until sensor: SensorType,
        matches condition: @escaping (SensorType) -> Bool,
        andDo: @escaping () -> Void
    ) {
        addSensorListener(sensor, condition: eraseType(on: condition), action: andDo, waitUntilDone: true, executedOnlyOnce: true)
    }

    func when<SensorType: Sensor>(
        _ sensor: SensorType,
        matches condition: @escaping (SensorType) -> Bool,
        do action: @escaping () -> Void
    ) {
        addSensorListener(sensor, condition: eraseType(on: condition), action: action, waitUntilDone: false, executedOnlyOnce: false)
    }
}

extension Tetra {
    func sleep(untilIsOn sensor: DigitalSensor, andDo action: @escaping () -> Void) {
        sleep(until: sensor, matches: { _ in sensor.value }, andDo: action)
    }

    func sleep(untilIsOff sensor: DigitalSensor, andDo action: @escaping () -> Void) {
        sleep(until: sensor, matches: { _ in !sensor.value }, andDo: action)
    }

    func sleep(until sensor: AnalogSensor, is value: Double, plusMinus: Double, andDo action: @escaping () -> Void) {
        sleep(until: sensor, matches: { abs($0.value - value) < plusMinus }, andDo: action)
    }

    func sleep(until sensor: AnalogSensor, isLessThan value: Double, andDo action: @escaping () -> Void) {
        sleep(until: sensor, matches: { $0.value < value }, andDo: action)
    }

    func sleep(until sensor: AnalogSensor, isGreaterThan value: Double, andDo action: @escaping () -> Void) {
        sleep(until: sensor, matches: { $0.value > value }, andDo: action)
    }

    func whenOn(_ sensor: DigitalSensor, action: @escaping () -> Void) {
        when(sensor, matches: { _ in sensor.value }, do: action)
    }

    func whenSensorIsOff(_ sensor: DigitalSensor, action: @escaping () -> Void) {
        when(sensor, matches: { _ in !sensor.value }, do: action)
    }

    func when(_ sensor: AnalogSensor, is value: Double, plusMinus: Double, action: @escaping () -> Void) {
        when(sensor, matches: { abs($0.value - value) < plusMinus }, do: action)
    }

    func when(_ sensor: AnalogSensor, isLessThan value: Double, action: @escaping () -> Void) {
        when(sensor, matches: { $0.value < value }, do: action)
    }

    func when(_ sensor: AnalogSensor, isGreaterThan value: Double, action: @escaping () -> Void) {
        when(sensor, matches: { $0.value > value }, do: action)
    }
}

extension Tetra {
    func on(_ sensor: Sensor, action: @escaping () -> Void) {
        addSensorListener(sensor, condition: { _ in true }, action: action, waitUntilDone: false, executedOnlyOnce: false)
    }
}
