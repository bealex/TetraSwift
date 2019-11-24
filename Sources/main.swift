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
        AnalogSensor(kind: .light, port: .analogSensor5),
        AnalogSensor(kind: .potentiometer, port: .analogSensor1),
        AnalogSensor(kind: .magnetic, port: .analogSensor2),
        AnalogSensor(kind: .temperature, port: .analogSensor3),
    ],
    digital: [
        DigitalSensor(kind: .infrared, port: .analogSensor4),
        DigitalSensor(kind: .button, port: .digitalSensor2),
        DigitalSensor(kind: .button, port: .digitalSensor3),
    ]
)
tetra.installActuators(
    analog: [
        AnalogActuator(kind: .motor, port: .motor4, maxValue: 180),
        AnalogActuator(kind: .buzzer, port: .analog9, maxValue: 200),
        AnalogActuator(kind: .analogLED(.green), port: .analog5, maxValue: 200),
        AnalogActuator(kind: .analogLED(.red), port: .analog6, maxValue: 200),
    ],
    digital: [
        DigitalActuator(kind: .digitalLED(.green), port: .digital10),
        DigitalActuator(kind: .digitalLED(.yellow), port: .digital12),
        DigitalActuator(kind: .digitalLED(.red), port: .digital13),
    ],
    displays: [
        QuadNumericDisplayActuator(kind: .quadDisplay, port: .digital14),
    ]
)

tetra.run {
    tetra.on(tetra.potentiometer) {
        if tetra.potentiometer.value < 0.5 {
            tetra.analogLEDs[.analog5].value = 0
            tetra.analogLEDs[.analog6].value = (0.5 - tetra.potentiometer.value) * 2
        } else {
            tetra.analogLEDs[.analog5].value = (tetra.potentiometer.value - 0.5) * 2
            tetra.analogLEDs[.analog6].value = 0
        }

        tetra.quadDisplay.value = UInt(tetra.potentiometer.value * 100)
    }
    tetra.whenOn(tetra.buttons[.digitalSensor2]) {
        tetra.digitalLEDs[.digital13].on()
        tetra.digitalLEDs[.digital12].on()
        tetra.digitalLEDs[.digital10].on()
    }
    tetra.whenOn(tetra.buttons[.digitalSensor3]) {
        tetra.digitalLEDs[.digital13].off()
        tetra.digitalLEDs[.digital12].off()
        tetra.digitalLEDs[.digital10].off()
    }

//    tetra.when(tetra.potentiometer, isLessThan: 0.4) {
//        tetra.buzzer.value = 0.01
//    }
//    tetra.when(tetra.potentiometer, isGreaterThan: 0.6) {
//        tetra.buzzer.value = 0
//    }

    tetra.quadDisplay.value = 239
}
