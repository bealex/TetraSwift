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

    private(set) var started: Bool = false

    private let workQueue: DispatchQueue = DispatchQueue(label: "tetra", qos: .default)
    private let eventQueue: DispatchQueue

    var debug: Bool = true

    let lightSensor = AnalogSensor(kind: .light, id: 0)
    let potentiometer = AnalogSensor(kind: .potentiometer, id: 1)
    let magneticSensor = AnalogSensor(kind: .magnetic, id: 2)
    let temperatureSensor = AnalogSensor(kind: .temperature, id: 3)
    let motorSensor = AnalogSensor(kind: .motor, id: 5)
    let infraredSensor = DigitalSensor(kind: .infrared, id: 4)
    let button2 = DigitalSensor(kind: .button2, id: 6)
    let button3 = DigitalSensor(kind: .button3, id: 7)

    private let sensorsById: [UInt8: Sensor]
    private let sensorsByKind: [SensorKind: Sensor]

    let motor4 = AnalogActuator(kind: .motor4, id: 4, maxValue: 180)
    let motor7 = AnalogActuator(kind: .motor7, id: 7, maxValue: 180)
    let motor8 = AnalogActuator(kind: .motor8, id: 8, maxValue: 180)

    let buzzer = AnalogActuator(kind: .buzzer, id: 9, maxValue: 200)

    let analogLED5 = AnalogActuator(kind: .ledAnalog5, id: 5, maxValue: 255)
    let analogLED6 = AnalogActuator(kind: .ledAnalog6, id: 6, maxValue: 255)

    let digitalLED10 = DigitalActuator(kind: .ledDigital10, id: 10)
    let digitalLED11 = DigitalActuator(kind: .ledDigital11, id: 11)
    let digitalLED12 = DigitalActuator(kind: .ledDigital12, id: 12)
    let digitalLED13 = DigitalActuator(kind: .ledDigital13, id: 13)

    init(pathToSerialPort: String, eventQueue: DispatchQueue) {
        self.eventQueue = eventQueue
        serialPort = SerialPort(path: "/dev/tty.usbmodem14801")

        let sensors: [Sensor] = [
            lightSensor, potentiometer, magneticSensor, temperatureSensor, infraredSensor,
            motorSensor, button2, button3
        ]
        var sensorsById: [UInt8: Sensor] = [:]
        var sensorsByKind: [SensorKind: Sensor] = [:]
        sensors.forEach { sensor in
            sensorsById[sensor.id] = sensor
            sensorsByKind[sensor.kind] = sensor
        }

        self.sensorsById = sensorsById
        self.sensorsByKind = sensorsByKind

        let actuators: [Actuator] = [
            motor4, motor7, motor8,
            buzzer,
            analogLED5, analogLED6,
            digitalLED10, digitalLED11, digitalLED12, digitalLED13
        ]
        actuators.forEach { $0.changedListener = { id, rawValue in self.write(id: id, rawValue: rawValue) } }
    }

    func run(execute: @escaping () -> Void) {
        start()
        execute()
        workQueue.async(execute: runLoop)

        while started {
            Thread.sleep(forTimeInterval: 0.1)
        }
    }

    func sleep(_ time: TimeInterval) {
        Thread.sleep(forTimeInterval: time)
    }

    private func start() {
        open()
        guard opened else { return }

        started = true
        log(message: "Started")
    }

    private func stop() {
        started = false
        close()
        log(message: "Stopped")
    }

    private func runLoop() {
        guard started && opened else {
            close()
            return
        }

        read()
        updateAllActuators()
        if sensorListeners.isEmpty {
            stop()
        } else {
            workQueue.async(execute: runLoop)
        }
    }

    private var lastActuatorsUpdateTime: TimeInterval = 0

    private func updateAllActuators() {
        let currentTime = Date.timeIntervalSinceReferenceDate
        if currentTime - lastActuatorsUpdateTime > 0.5 {
            lastActuatorsUpdateTime = currentTime
            let actuators: [Actuator] = [
                motor4, motor7, motor8,
                buzzer,
                analogLED5, analogLED6,
                digitalLED10, digitalLED11, digitalLED12, digitalLED13
            ]
            actuators.forEach { self.write(id: $0.id, rawValue: $0.rawValue) }
        }
    }

    private let picoBoard = PicoBoardProtocol()

    private func write(id: UInt8, rawValue: UInt) {
        workQueue.async {
            do {
                var bytes = self.picoBoard.bytes(sensorId: id, value: rawValue)
                while !bytes.isEmpty {
                    let sent = try self.serialPort.writeBytes(from: bytes, size: bytes.count)
                    bytes = Array(bytes.dropFirst(sent))
                }
                self.log(message: " \(id) <- \(rawValue)")
            } catch {
                self.processError("Error writing \(rawValue) to \(id): \(error)")
            }
        }
    }

    private var buffer: [UInt8] = [ 0, 0 ]
    private var bytes: [UInt8] = []

    func rawValue(for sensorKind: SensorKind) -> UInt {
        sensorsByKind[sensorKind]?.rawValue ?? 0
    }

    private func read() {
        do {
            let readCount = try self.serialPort.readBytes(into: &buffer, size: 2 - bytes.count)
            if readCount > 0 {
                bytes.append(contentsOf: buffer[0 ..< readCount])
            }

            if bytes.count == 2 {
                let (id, value) = self.picoBoard.data(from: bytes)
                bytes = []

                if let sensor = sensorsById[id], sensor.update(rawValue: value) {
                    self.notifySensorListenersAboutUpdate(sensor: sensor)
                }
            }
        } catch {
            self.processError("Error reading: \(error)")
            self.stop()
        }
    }

    private func open() {
        do {
            try serialPort.openPort()
            opened = true
            serialPort.setSettings(receiveRate: .baud38400, transmitRate: .baud38400, minimumBytesToRead: 0)
            log(message: "Port opened")
        } catch {
            processError("Error opening: \(error)")
        }
    }

    private func close() {
        sensorListeners = []
        serialPort.closePort()
        opened = false
    }

    private func processError(_ message: String) {
        log(message: message)
    }

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
        var isRepeated: Bool

        var semaphore: DispatchSemaphore?
    }

    private var sensorListeners: [SensorListener] = []

    private func addSensorListener(
        _ sensorKind: SensorKind, condition: @escaping (Sensor) -> Bool, action: @escaping () -> Void,
        asynchronous: Bool, isRepeated: Bool
    ) {
        guard let sensor = sensorsByKind[sensorKind] else {
            processError("Error adding waitFor, can't find sensor \(sensorKind)")
            return
        }

        var waiter = SensorListener(sensor: sensor, condition: condition, action: action, isRepeated: isRepeated)
        sensorListeners.append(waiter)

        if !asynchronous {
            waiter.semaphore = DispatchSemaphore(value: 0)
            waiter.semaphore?.wait()
        }
        log(message: " + Condition for \(sensorKind)")
    }

    private func notifySensorListenersAboutUpdate(sensor: Sensor) {
        var listenerIdsToRemove: [UUID] = []
        sensorListeners.forEach { listener in
            if listener.sensor.id == sensor.id, listener.condition(sensor) {
                eventQueue.async {
                    self.log(message: " ! Condition for \(sensor.kind) executed")
                    listener.action()
                    listener.semaphore?.signal()
                }
                if !listener.isRepeated {
                    self.log(message: " - Condition for \(sensor.kind) removed")
                    listenerIdsToRemove.append(listener.id)
                }
            }
        }

        sensorListeners = sensorListeners.filter { !listenerIdsToRemove.contains($0.id) }
    }
}

extension Tetra {
    private func digitalSensorCondition(test: Bool) -> (Sensor) -> Bool {
        // Just to silence swiftlint :-)
        { sensor in
            if let digitalSensor = sensor as? DigitalSensor {
                return digitalSensor.value == test
            } else {
                return false
            }
        }
    }
}

extension Tetra {
    func waitFor(_ sensorKind: SensorKind, condition: @escaping (Sensor) -> Bool, action: @escaping () -> Void) {
        addSensorListener(sensorKind, condition: condition, action: action, asynchronous: false, isRepeated: false)
    }

    func waitFor(_ sensorKind: SensorKind, is value: Bool, action: @escaping () -> Void) {
        waitFor(sensorKind, condition: digitalSensorCondition(test: value), action: action)
    }

    func waitFor(_ sensorKind: SensorKind, is value: UInt, action: @escaping () -> Void) {
        waitFor(sensorKind, condition: { $0.rawValue == value }, action: action)
    }

    func waitFor(_ sensorKind: SensorKind, isLessThan value: UInt, action: @escaping () -> Void) {
        waitFor(sensorKind, condition: { $0.rawValue < value }, action: action)
    }

    func waitFor(_ sensorKind: SensorKind, isGreaterThan value: UInt, action: @escaping () -> Void) {
        waitFor(sensorKind, condition: { $0.rawValue < value }, action: action)
    }
}

extension Tetra {
    func when(_ sensorKind: SensorKind, condition: @escaping (Sensor) -> Bool, action: @escaping () -> Void) {
        addSensorListener(sensorKind, condition: condition, action: action, asynchronous: true, isRepeated: true)
    }

    func whenOn(_ sensorKind: SensorKind, action: @escaping () -> Void) {
        when(sensorKind, condition: digitalSensorCondition(test: true), action: action)
    }

    func whenOff(_ sensorKind: SensorKind, action: @escaping () -> Void) {
        when(sensorKind, condition: digitalSensorCondition(test: false), action: action)
    }

    func when(_ sensorKind: SensorKind, is value: UInt, action: @escaping () -> Void) {
        when(sensorKind, condition: { $0.rawValue == value }, action: action)
    }

    func when(_ sensorKind: SensorKind, isLessThan value: UInt, action: @escaping () -> Void) {
        when(sensorKind, condition: { $0.rawValue < value }, action: action)
    }

    func when(_ sensorKind: SensorKind, isGreaterThan value: UInt, action: @escaping () -> Void) {
        when(sensorKind, condition: { $0.rawValue < value }, action: action)
    }
}

extension Tetra {
    func on(_ sensorKind: SensorKind, action: @escaping () -> Void) {
        addSensorListener(sensorKind, condition: { _ in true }, action: action, asynchronous: true, isRepeated: true)
    }
}
