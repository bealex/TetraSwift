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
let sensors: [IOPort: IdentifiableDevice & UpdatableSensor] = [
    .analog0: LightSensor(),
    .analog1: Potentiometer(),
    .analog2: MagneticSensor(),
    .analog3: TemperatureSensor(),
    .analog4: InfraredSensor(),
    .digital6: Button(),
    .digital7: Button(),
]
tetra.install(sensors: sensors)

let actuators: [IOPort: Actuator] = [
    .digital4: Motor(),
    .digital9: Buzzer(),
    .digital5: AnalogLED(color: .green),
    .digital6: AnalogLED(color: .red),
    .digital10: DigitalLED(color: .green),
    .digital11: DigitalLED(color: .yellow),
    .digital12: DigitalLED(color: .yellow),
    .digital13: DigitalLED(color: .red),
    .digital7: LEDMatrixActuator(),
    .digital8: QuadNumericDisplayActuator(),
]
tetra.install(actuators: actuators)

tetra.run {
    tetra.potentiometer.whenValueChanged { value in
        if value < 0.5 {
            tetra.analogLEDs[.digital5].value = 0
            tetra.analogLEDs[.digital6].value = (0.5 - value) * 2
        } else {
            tetra.analogLEDs[.digital5].value = (value - 0.5) * 2
            tetra.analogLEDs[.digital6].value = 0
        }
    }

    tetra.buttons[.digital6].whenOn {
        tetra.digitalLEDs[.digital13].on()
        tetra.digitalLEDs[.digital12].on()
        tetra.digitalLEDs[.digital11].on()
        tetra.digitalLEDs[.digital10].on()
    }
    tetra.buttons[.digital7].whenOn {
        tetra.digitalLEDs[.digital13].off()
        tetra.digitalLEDs[.digital12].off()
        tetra.digitalLEDs[.digital11].off()
        tetra.digitalLEDs[.digital10].off()
    }

    tetra.potentiometer.when(lessThan: 0.4) { _ in
        tetra.buzzer.value = true
    }
    tetra.potentiometer.when(greaterThan: 0.6) { _ in
        tetra.buzzer.value = false
    }

    tetra.temperatureSensor.whenValueChanged { value in
        print("Temperature: \(value)")
        tetra.quadDisplay.value = String(format: "%.1f˚", value)
    }
    tetra.ledMatrix.value = "@"
}
