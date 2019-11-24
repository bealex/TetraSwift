//
//  main.swift
//  TetraCode
//
//  Created by Alex Babaev on 21.11.2019.
//  Copyright © 2019 LonelyBytes. All rights reserved.
//

import Foundation

let tetra = Tetra(pathToSerialPort: "/dev/tty.usbmodem14801", eventQueue: DispatchQueue.global())
tetra.installSensors(
    analog: [
        AnalogSensor(kind: .light, port: .analog0, sampleTimes: 8),
        AnalogSensor(kind: .potentiometer, port: .analog1, sampleTimes: 4),
        AnalogSensor(kind: .magnetic, port: .analog2, sampleTimes: 8, tolerance: 0.01),
        AnalogSensor(kind: .temperature, port: .analog3, sampleTimes: 32, tolerance: 0.03) { rawAverage in
            // https://github.com/amperka/TroykaThermometer/blob/master/src/TroykaThermometer.cpp ¯\_(ツ)_/¯
            let sensorVoltage = rawAverage * (5.0 / 1023.0) // 5 — voltage, 1024 — maxValue
            let temperatureCelsius = (sensorVoltage - 0.5) * 100.0
            return temperatureCelsius
        },
    ],
    digital: [
        DigitalSensor(kind: .infrared, port: .analog4),
        DigitalSensor(kind: .button, port: .digital6),
        DigitalSensor(kind: .button, port: .digital7),
    ]
)
tetra.installActuators(
    analog: [
//        AnalogActuator(kind: .motor, port: .motor4, maxValue: 180), // Motor pins are replaced by QuadDisplay
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
    displays: [
        QuadNumericDisplayActuator(kind: .quadDisplay, port: .fake14),
    ]
)

tetra.run {
    tetra.on(tetra.temperatureSensor) {
        tetra.quadDisplay.value = String(format: "%.1f˚", tetra.temperatureSensor.value)
    }
//    tetra.on(tetra.lightSensor) {
//        print("Light: \(tetra.lightSensor.value)")
//    }
//    tetra.on(tetra.magneticSensor) {
//        print("Magnetic: \(tetra.magneticSensor.value)")
//    }
//    tetra.on(tetra.temperatureSensor) {
//        print("Temperature: \(tetra.temperatureSensor.value)")
//    }
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

    tetra.quadDisplay.value = "HoHo"
}
