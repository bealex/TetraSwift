//
//  main.swift
//  TetraCode
//
//  Created by Alex Babaev on 21.11.2019.
//  Copyright © 2019 LonelyBytes. All rights reserved.
//

import Foundation

guard let serialPort = CommandLine.arguments.dropFirst().first else {
    print("Please specify path to the Tetra serial port as a parameter")
    exit(1)
}

let tetra = MyTetra(serialPort: serialPort)
tetra.run { æ in
    guard let æ = æ as? MyTetra else { return }

    æ.potentiometer.whenValueChanged { value in
        if value < 0.5 {
            æ.greenAnalogLED.value = 0
            æ.redAnalogLED.value = (0.5 - value) * 2
        } else {
            æ.greenAnalogLED.value = (value - 0.5) * 2
            æ.redAnalogLED.value = 0
        }
    }

    æ.button2.whenOn {
        æ.greenDigitalLED.on()
        æ.yellowDigitalLED.on()
        æ.yellowDigitalOtherLED.on()
        æ.redDigitalLED.on()
    }
    æ.button2.whenOff {
        æ.greenDigitalLED.off()
        æ.yellowDigitalLED.off()
        æ.yellowDigitalOtherLED.off()
        æ.redDigitalLED.off()
    }

    æ.potentiometer.when(lessThan: 0.4) { _ in
        æ.buzzer.value = true
    }
    æ.potentiometer.when(greaterThan: 0.6) { _ in
        æ.buzzer.value = false
    }

    æ.temperatureSensor.whenValueChanged { value in
        æ.quadDisplay.value = String(format: "%.1f˚", value)
    }
    æ.ledMatrix.value = "@"
}
