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

    var sendEvent: (TetraEvent) -> Void = { _ in }
    private let eventQueue: DispatchQueue

    var debug: Bool = true

    init(pathToSerialPort: String, eventQueue: DispatchQueue) {
        self.eventQueue = eventQueue
        serialPort = SerialPort(path: "/dev/tty.usbmodem14801")
    }

    func run(program: @escaping () -> Void) {
        start()
        program()
        stop()

        while started {
            Thread.sleep(forTimeInterval: 0.1)
        }
    }

    func start() {
        open()
        started = true
        sendEvent(.started)
        readLoop()
    }

    func stop() {
        started = false
        close()
        sendEvent(.stopped)
    }

    private let picoBoard = PicoBoardProtocol()

    func write(actuator: TetraActuatorValue) {
        DispatchQueue.global().sync {
            do {
                let toSend = actuator.data
                var bytes = picoBoard.bytes(sensorId: toSend.sensorId, value: toSend.value)
                while !bytes.isEmpty {
                    let sent = try serialPort.writeBytes(from: bytes, size: bytes.count)
                    bytes = Array(bytes.dropFirst(sent))
                }
            } catch {
                processError("Error writing: \(error)")
            }
        }
    }

    private func readLoop() {
        if opened {
            DispatchQueue.global().async {
                var lastSensorValues: [Tetra.Sensor.Kind: Tetra.Sensor.Value] = [:]

                var buffer: [UInt8] = [ 0, 0 ]
                var bytes: [UInt8] = []
                while self.started && self.opened {
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
                                if lastSensorValues[value.sensor.kind] != value {
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
            }
        }
    }

    private func open() {
        do {
            try serialPort.openPort()
            opened = true
            serialPort.setSettings(receiveRate: .baud38400, transmitRate: .baud38400, minimumBytesToRead: 0)
            print("Port opened")
        } catch {
            processError("Error opening: \(error)")
        }
    }

    private func close() {
        serialPort.closePort()
        opened = false
    }

    private func processError(_ message: String) {
        self.sendEvent(.error(message))
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
        _ sensorKind: Sensor.Kind, condition: @escaping (Sensor.Value) -> Bool, action: @escaping () -> Void, isRepeated: Bool
    ) {
        guard let sensor = Tetra.sensorsByKind[sensorKind] else {
            processError("Error adding waitFor, can't find sensor \(sensorKind)")
            return
        }

        var waiter = Waiter(sensor: sensor, condition: condition, action: action, isRepeated: isRepeated)
        waiter.semaphore = DispatchSemaphore(value: 0)
        valueWaiters.append(waiter)
        waiter.semaphore?.wait()
    }

    private func pingWaiters(with value: Sensor.Value) {
        var waiterIdsToRemove: [UUID] = []
        valueWaiters.forEach { waiter in
            if waiter.sensor == value.sensor, waiter.condition(value) {
                if !waiter.isRepeated {
                    waiterIdsToRemove.append(waiter.id)
                }
                eventQueue.async {
                    waiter.action()
                    waiter.semaphore?.signal()
                }
            }
        }

        valueWaiters = valueWaiters.filter { !waiterIdsToRemove.contains($0.id) }
    }
}

extension Tetra {
    func waitFor(_ sensorKind: Sensor.Kind, condition: @escaping (Sensor.Value) -> Bool, action: @escaping () -> Void) {
        addCondition(sensorKind, condition: condition, action: action, isRepeated: false)
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
        addCondition(sensorKind, condition: condition, action: action, isRepeated: true)
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
