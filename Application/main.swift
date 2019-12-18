//
//  main.swift
//  TetraCode
//
//  Created by Alex Babaev on 21.11.2019.
//  Copyright © 2019 LonelyBytes. All rights reserved.
//

import Foundation
import TetraSwift

guard let serialPort = CommandLine.arguments.dropFirst().first else {
    print("Please specify path to the Tetra serial port as a parameter")
    exit(1)
}

Tetra(serialPort: serialPort).run {
    guard let tetra = $0 as? Tetra else { return }

    tetra.potentiometer.whenValueChanged { value in
        if value < 0.5 {
            tetra.greenAnalogLED.value = 0
            tetra.redAnalogLED.value = (0.5 - value) * 2
        } else {
            tetra.greenAnalogLED.value = (value - 0.5) * 2
            tetra.redAnalogLED.value = 0
        }
    }

    tetra.button2.whenOn {
        tetra.greenDigitalLED.on()
        tetra.yellowDigitalLED.on()
        tetra.yellowDigitalOtherLED.on()
        tetra.redDigitalLED.on()
    }
    tetra.button2.whenOff {
        tetra.greenDigitalLED.off()
        tetra.yellowDigitalLED.off()
        tetra.yellowDigitalOtherLED.off()
        tetra.redDigitalLED.off()
    }

    tetra.potentiometer.when(lessThan: 0.4) {
        tetra.buzzer.value = true
    }
    tetra.potentiometer.when(greaterThan: 0.6) {
        tetra.buzzer.value = false
    }

    tetra.temperatureSensor.whenValueChanged { value in
        tetra.quadDisplay.value = String(format: "%.1f˚", value)
    }
    tetra.ledMatrix.value = "."
}
