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

    init(pathToSerialPort: String, eventQueue: DispatchQueue) {
        self.eventQueue = eventQueue
        serialPort = SerialPort(path: "/dev/tty.usbmodem14801")
    }

    func run(execute: @escaping () -> Void) {
        start()
        execute()
        workQueue.async(execute: runLoop)

        while started {
            Thread.sleep(forTimeInterval: 0.1)
        }
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
        if valueWaiters.isEmpty {
            stop()
        } else {
            workQueue.async(execute: runLoop)
        }
    }

    private let picoBoard = PicoBoardProtocol()

    func write(actuator: TetraActuatorValue) {
        workQueue.async {
            do {
                let toSend = actuator.data
                var bytes = self.picoBoard.bytes(sensorId: toSend.sensorId, value: toSend.value)
                while !bytes.isEmpty {
                    let sent = try self.serialPort.writeBytes(from: bytes, size: bytes.count)
                    bytes = Array(bytes.dropFirst(sent))
                }
                self.log(message: " <- \(actuator)")
            } catch {
                self.processError("Error writing: \(error)")
            }
        }
    }

    private var buffer: [UInt8] = [ 0, 0 ]
    private var bytes: [UInt8] = []
    private var lastSensorValues: [Tetra.Sensor.Kind: Tetra.Sensor.Value] = [:]

    func rawValue(for sensorKind: Sensor.Kind) -> UInt {
        lastSensorValues[sensorKind]?.rawValue ?? 0
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

                if let sensor = Tetra.sensorsById[id] {
                    let value = Tetra.Sensor.Value(sensor: sensor, rawValue: value)
                    let oldValue = lastSensorValues[value.sensor.kind]
                    if oldValue != value {
                        lastSensorValues[value.sensor.kind] = value
                        self.eventQueue.async { self.sendEvent(.sensor(value)) }
                        self.pingWaiters(with: value)
                    }
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
        valueWaiters = []
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

    private struct Waiter {
        var id: UUID = UUID()

        var sensor: Sensor
        var condition: (Sensor.Value) -> Bool
        var action: () -> Void
        var isRepeated: Bool

        var semaphore: DispatchSemaphore?
    }

    private var valueWaiters: [Waiter] = []

    private func addCondition(
        _ sensorKind: Sensor.Kind, condition: @escaping (Sensor.Value) -> Bool, action: @escaping () -> Void,
        asynchronous: Bool, isRepeated: Bool
    ) {
        guard let sensor = Tetra.sensorsByKind[sensorKind] else {
            processError("Error adding waitFor, can't find sensor \(sensorKind)")
            return
        }

        var waiter = Waiter(sensor: sensor, condition: condition, action: action, isRepeated: isRepeated)
        valueWaiters.append(waiter)

        if !asynchronous {
            waiter.semaphore = DispatchSemaphore(value: 0)
            waiter.semaphore?.wait()
        }
        log(message: " + Condition for \(sensorKind)")
    }

    private func pingWaiters(with value: Sensor.Value) {
        var waiterIdsToRemove: [UUID] = []
        valueWaiters.forEach { waiter in
            if waiter.sensor == value.sensor, waiter.condition(value) {
                eventQueue.async {
                    self.log(message: " ! Condition for \(waiter.sensor.kind) executed")
                    waiter.action()
                    waiter.semaphore?.signal()
                }
                if !waiter.isRepeated {
                    self.log(message: " - Condition for \(waiter.sensor.kind)")
                    waiterIdsToRemove.append(waiter.id)
                }
            }
        }

        valueWaiters = valueWaiters.filter { !waiterIdsToRemove.contains($0.id) }
    }
}

extension Tetra {
    func waitFor(_ sensorKind: Sensor.Kind, condition: @escaping (Sensor.Value) -> Bool, action: @escaping () -> Void) {
        addCondition(sensorKind, condition: condition, action: action, asynchronous: false, isRepeated: false)
    }

    func waitFor(_ sensorKind: Sensor.Kind, is value: Bool, action: @escaping () -> Void) {
        waitFor(sensorKind, condition: { $0.digitalValue == value }, action: action)
    }

    func waitFor(_ sensorKind: Sensor.Kind, is value: UInt, action: @escaping () -> Void) {
        waitFor(sensorKind, condition: { $0.rawValue == value }, action: action)
    }

    func waitFor(_ sensorKind: Sensor.Kind, isLessThan value: UInt, action: @escaping () -> Void) {
        waitFor(sensorKind, condition: { $0.rawValue < value }, action: action)
    }

    func waitFor(_ sensorKind: Sensor.Kind, isGreaterThan value: UInt, action: @escaping () -> Void) {
        waitFor(sensorKind, condition: { $0.rawValue < value }, action: action)
    }
}

extension Tetra {
    func when(_ sensorKind: Sensor.Kind, condition: @escaping (Sensor.Value) -> Bool, action: @escaping () -> Void) {
        addCondition(sensorKind, condition: condition, action: action, asynchronous: true, isRepeated: true)
    }

    func when(_ sensorKind: Sensor.Kind, is value: Bool, action: @escaping () -> Void) {
        when(sensorKind, condition: { $0.digitalValue == value }, action: action)
    }

    func when(_ sensorKind: Sensor.Kind, is value: UInt, action: @escaping () -> Void) {
        when(sensorKind, condition: { $0.rawValue == value }, action: action)
    }

    func when(_ sensorKind: Sensor.Kind, isLessThan value: UInt, action: @escaping () -> Void) {
        when(sensorKind, condition: { $0.rawValue < value }, action: action)
    }

    func when(_ sensorKind: Sensor.Kind, isGreaterThan value: UInt, action: @escaping () -> Void) {
        when(sensorKind, condition: { $0.rawValue < value }, action: action)
    }
}

extension Tetra {
    func on(_ sensorKind: Sensor.Kind, action: @escaping () -> Void) {
        addCondition(sensorKind, condition: { _ in true }, action: action, asynchronous: true, isRepeated: true)
    }
}
