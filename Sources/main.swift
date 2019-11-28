//
//  main.swift
//  TetraCode
//
//  Created by Alex Babaev on 21.11.2019.
//  Copyright © 2019 LonelyBytes. All rights reserved.
//

import Foundation

let arduinoSerialPort = "/dev/tty.usbmodem14801"

let tetra = Tetra(pathToSerialPort: arduinoSerialPort, useTetraProtocol: true, eventQueue: DispatchQueue.global())

tetra.installSensors(
    analog: [
        AnalogSensor(kind: .light, port: .analog0, sampleTimes: 8),
        AnalogSensor(kind: .potentiometer, port: .analog1, sampleTimes: 4, tolerance: 0.7),
        AnalogSensor(kind: .magnetic, port: .analog2, sampleTimes: 8, tolerance: 0.01),
        AnalogSensor(kind: .temperature, port: .analog3, sampleTimes: 32, tolerance: 0.05, calculate: SensorCalculator.celsiusTemperature),
    ],
    digital: [
        DigitalSensor(kind: .infrared, port: .analog4),
        DigitalSensor(kind: .button, port: .digital6),
        DigitalSensor(kind: .button, port: .digital7),
    ]
)
tetra.installActuators(
    analog: [
        AnalogActuator(kind: .motor, port: .digital4, maxValue: 180),
        AnalogActuator(kind: .buzzer, port: .digital9, maxValue: 200),
        AnalogActuator(kind: .analogLED(.green), port: .digital5, maxValue: 200),
        AnalogActuator(kind: .analogLED(.red), port: .digital6, maxValue: 200),
    ],
    digital: [
        DigitalActuator(kind: .digitalLED(.green), port: .digital10),
        DigitalActuator(kind: .digitalLED(.yellow), port: .digital11),
        DigitalActuator(kind: .digitalLED(.yellow), port: .digital12),
        DigitalActuator(kind: .digitalLED(.red), port: .digital13),
    ],
    quadDisplays: [
        QuadNumericDisplayActuator(kind: .quadDisplay, port: .digital8),
    ],
    ledMatrices: [
        LEDMatrixActuator(kind: .ledMatrix(.monochrome), port: .digital7),
    ]
)

tetra.run {
    tetra.on(tetra.potentiometer) {
        if tetra.potentiometer.value < 0.5 {
            tetra.analogLEDs[.digital5].value = 0
            tetra.analogLEDs[.digital6].value = (0.5 - tetra.potentiometer.value) * 2
        } else {
            tetra.analogLEDs[.digital5].value = (tetra.potentiometer.value - 0.5) * 2
            tetra.analogLEDs[.digital6].value = 0
        }

//        var toDisplay = "\(Int(tetra.potentiometer.value * 100))"
//        if toDisplay == "0" {
//            toDisplay = "OOPS"
//        } else if toDisplay == "100" {
//            toDisplay = "FULL"
//        }
//        tetra.quadDisplay.value = toDisplay
    }
    tetra.whenOn(tetra.buttons[.digital6]) {
        tetra.digitalLEDs[.digital13].on()
        tetra.digitalLEDs[.digital12].on()
        tetra.digitalLEDs[.digital11].on()
        tetra.digitalLEDs[.digital10].on()
    }
    tetra.whenOn(tetra.buttons[.digital7]) {
        tetra.digitalLEDs[.digital13].off()
        tetra.digitalLEDs[.digital12].off()
        tetra.digitalLEDs[.digital11].off()
        tetra.digitalLEDs[.digital10].off()
    }

//    tetra.when(tetra.potentiometer, isLessThan: 0.4) {
//        tetra.buzzer.value = 0.01
//    }
//    tetra.when(tetra.potentiometer, isGreaterThan: 0.6) {
//        tetra.buzzer.value = 0
//    }

    tetra.on(tetra.temperatureSensor) {
        print("Temperature: \(tetra.temperatureSensor.value)")
        tetra.quadDisplay.value = String(format: "%.1f˚", tetra.temperatureSensor.value)
    }
//    tetra.quadDisplay.value = "HoHo"
    tetra.ledMatrix.value = "@"
}
