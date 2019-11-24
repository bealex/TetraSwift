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
        AnalogSensor(kind: .light, port: .analog0),
        AnalogSensor(kind: .potentiometer, port: .analog1),
        AnalogSensor(kind: .magnetic, port: .analog2),
        AnalogSensor(kind: .temperature, port: .analog3, sampleTimes: 32) { rawValue in
            // https://github.com/amperka/TroykaThermometer/blob/master/src/TroykaThermometer.cpp ¯\_(ツ)_/¯
            let adcBits: Double = 10
            let adcMaxValue: Double = pow(2.0, adcBits)
            let operatingVoltage: Double = 5.0
            let sensorVoltage = Double(rawValue) * (operatingVoltage / adcMaxValue)
            let temperatureCelsius = (sensorVoltage - 0.5) * 100
            return temperatureCelsius
        },
    ],
    digital: [
        DigitalSensor(kind: .infrared, port: .analog4),
        DigitalSensor(kind: .button, port: .digital2),
        DigitalSensor(kind: .button, port: .digital3),
    ]
)
tetra.installActuators(
    analog: [
//        AnalogActuator(kind: .motor, port: .motor4, maxValue: 180), // Motor pins are replaced by QuadDisplay
        AnalogActuator(kind: .buzzer, port: .analog9, maxValue: 200),
        AnalogActuator(kind: .analogLED(.green), port: .analog5, maxValue: 200),
        AnalogActuator(kind: .analogLED(.red), port: .analog6, maxValue: 200),
    ],
    digital: [
        DigitalActuator(kind: .digitalLED(.green), port: .digital10),
        DigitalActuator(kind: .digitalLED(.yellow), port: .digital11),
        DigitalActuator(kind: .digitalLED(.yellow), port: .digital12),
        DigitalActuator(kind: .digitalLED(.red), port: .digital13),
    ],
    displays: [
        QuadNumericDisplayActuator(kind: .quadDisplay, port: .digital14),
    ]
)

tetra.run {
    tetra.on(tetra.temperatureSensor) {
        tetra.quadDisplay.value = "\(Int(tetra.temperatureSensor.value))˙"
    }
    tetra.on(tetra.potentiometer) {
        if tetra.potentiometer.value < 0.5 {
            tetra.analogLEDs[.analog5].value = 0
            tetra.analogLEDs[.analog6].value = (0.5 - tetra.potentiometer.value) * 2
        } else {
            tetra.analogLEDs[.analog5].value = (tetra.potentiometer.value - 0.5) * 2
            tetra.analogLEDs[.analog6].value = 0
        }

//        var toDisplay = "\(Int(tetra.potentiometer.value * 100))"
//        if toDisplay == "0" {
//            toDisplay = "OOPS"
//        } else if toDisplay == "100" {
//            toDisplay = "FULL"
//        }
//        tetra.quadDisplay.value = toDisplay
    }
    tetra.whenOn(tetra.buttons[.digital2]) {
        tetra.digitalLEDs[.digital13].on()
        tetra.digitalLEDs[.digital12].on()
        tetra.digitalLEDs[.digital11].on()
        tetra.digitalLEDs[.digital10].on()
    }
    tetra.whenOn(tetra.buttons[.digital3]) {
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
