//
//  main.swift
//  TetraCode
//
//  Created by Alex Babaev on 21.11.2019.
//  Copyright © 2019 LonelyBytes. All rights reserved.
//

import TetraSwift
import Foundation

guard let serialPort = CommandLine.arguments.dropFirst().first else {
    print("Please specify path to the Tetra serial port as a parameter")
    exit(1)
}

let tetra = Tetra(pathToSerialPort: serialPort, useTetraProtocol: true)
tetra.install(sensors: [
    .analog0: LightSensor(),
    .analog1: Potentiometer(),
    .analog2: MagneticSensor(),
    .analog3: TemperatureSensor(),
    .analog4: InfraredSensor(),
    .digital6: Button(),
    .digital7: Button(),
])
tetra.install(actuators: [
    .digital4: LimitedAnalogActuator(kind: .motor, maxValue: 180),
    .digital9: LimitedAnalogActuator(kind: .buzzer, maxValue: 200),
    .digital5: LimitedAnalogActuator(kind: .analogLED(.green), maxValue: 200),
    .digital6: LimitedAnalogActuator(kind: .analogLED(.red), maxValue: 200),
    .digital10: BooleanDigitalActuator(kind: .digitalLED(.green)),
    .digital11: BooleanDigitalActuator(kind: .digitalLED(.yellow)),
    .digital12: BooleanDigitalActuator(kind: .digitalLED(.yellow)),
    .digital13: BooleanDigitalActuator(kind: .digitalLED(.red)),
    .digital7: LEDMatrixActuator(kind: .ledMatrix(.monochrome)),
    .digital8: QuadNumericDisplayActuator(kind: .quadDisplay),
])

tetra.run {
    tetra.on(tetra.potentiometer) {
        let potentiometerValue = tetra.potentiometer.value
        if potentiometerValue < 0.5 {
            tetra.analogLEDs[.digital5].value = 0
            tetra.analogLEDs[.digital6].value = (0.5 - potentiometerValue) * 2
        } else {
            tetra.analogLEDs[.digital5].value = (potentiometerValue - 0.5) * 2
            tetra.analogLEDs[.digital6].value = 0
        }
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

    tetra.when(tetra.potentiometer, isLessThan: 0.4) {
        tetra.buzzer.value = true
    }
    tetra.when(tetra.potentiometer, isGreaterThan: 0.6) {
        tetra.buzzer.value = false
    }

    tetra.on(tetra.temperatureSensor) {
        let temperature = tetra.temperatureSensor.value
        print("Temperature: \(temperature)")
        tetra.quadDisplay.value = String(format: "%.1f˚", temperature)
    }
    tetra.ledMatrix.value = "@"
}
