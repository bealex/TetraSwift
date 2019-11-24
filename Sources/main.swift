//
//  main.swift
//  TetraCode
//
//  Created by Alex Babaev on 21.11.2019.
//  Copyright © 2019 LonelyBytes. All rights reserved.
//

import Foundation

let tetra = Tetra(pathToSerialPort: "/dev/tty.usbmodem14801", eventQueue: DispatchQueue.global())

tetra.run {
    tetra.on(.potentiometer) {
        tetra.analogLED6.value = tetra.potentiometer.value
        tetra.analogLED5.value = 1 - tetra.potentiometer.value
    }

    tetra.digitalLED13.on()
    tetra.sleep(0.3)
    tetra.digitalLED13.off()
    tetra.digitalLED12.on()
    tetra.sleep(0.3)
    tetra.digitalLED12.off()
    tetra.digitalLED10.on()
    tetra.sleep(0.3)
    tetra.digitalLED10.off()

//    tetra.whenOn(.button2) {
//        tetra.digitalLED13.on()
//        tetra.digitalLED12.on()
//        tetra.digitalLED10.on()
//        tetra.digitalLED11.on()
//    }
//    tetra.whenOn(.button3) {
//        tetra.digitalLED13.off()
//        tetra.digitalLED12.off()
//        tetra.digitalLED10.off()
//        tetra.digitalLED11.off()
//    }
}
