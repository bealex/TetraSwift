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
    .analog0: AnalogSensor(kind: .light, sampleTimes: 8),
    .analog1: AnalogSensor(kind: .potentiometer, sampleTimes: 4, tolerance: 0.7),
    .analog2: AnalogSensor(kind: .magnetic, sampleTimes: 8, tolerance: 0.01),
    .analog3: AnalogSensor(kind: .temperature, sampleTimes: 32, tolerance: 0.05, calculate: Calculators.celsiusTemperature),
    .analog4: DigitalSensor(kind: .infrared),
    .digital6: DigitalSensor(kind: .button),
    .digital7: DigitalSensor(kind: .button),
])
tetra.install(actuators: [
    .digital4: AnalogActuator(kind: .motor, maxValue: 180),
    .digital9: AnalogActuator(kind: .buzzer, maxValue: 200),
    .digital5: AnalogActuator(kind: .analogLED(.green), maxValue: 200),
    .digital6: AnalogActuator(kind: .analogLED(.red), maxValue: 200),
    .digital10: DigitalActuator(kind: .digitalLED(.green)),
    .digital11: DigitalActuator(kind: .digitalLED(.yellow)),
    .digital12: DigitalActuator(kind: .digitalLED(.yellow)),
    .digital13: DigitalActuator(kind: .digitalLED(.red)),
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
        tetra.buzzer.value = 0.01
    }
    tetra.when(tetra.potentiometer, isGreaterThan: 0.6) {
        tetra.buzzer.value = 0
    }

    tetra.on(tetra.temperatureSensor) {
        let temperature = tetra.temperatureSensor.value
        print("Temperature: \(temperature)")
        tetra.quadDisplay.value = String(format: "%.1f˚", temperature)
    }
    tetra.ledMatrix.value = "@"
}
