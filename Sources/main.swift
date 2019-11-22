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
    tetra.when(.button2, is: true) {
        tetra.write(actuator: .ledDigital13(true))
        tetra.write(actuator: .ledDigital12(true))
        tetra.write(actuator: .ledDigital11(true))
        tetra.write(actuator: .ledDigital10(true))
        tetra.write(actuator: .buzzer(2))
        Thread.sleep(forTimeInterval: 1)
        tetra.write(actuator: .ledDigital13(false))
        tetra.write(actuator: .ledDigital12(false))
        tetra.write(actuator: .ledDigital11(false))
        tetra.write(actuator: .ledDigital10(false))
        tetra.write(actuator: .buzzer(0))
    }
    tetra.when(.button3, is: true) {
//        for value: UInt in 0 ..< 180 {
//            tetra.write(actuator: .motor4(value))
//            Thread.sleep(forTimeInterval: 0.02)
//        }
//        tetra.write(actuator: .motor4(0))

        tetra.write(actuator: .buzzer(64))

        tetra.write(actuator: .ledAnalog6(64))
        tetra.write(actuator: .ledAnalog5(64))

//        for _ in 0 ..< 10 {
//            tetra.write(actuator: .ledAnalog5(128))
//            Thread.sleep(forTimeInterval: 0.1)
//            tetra.write(actuator: .ledAnalog5(255))
//            Thread.sleep(forTimeInterval: 0.1)
//        }

        Thread.sleep(forTimeInterval: 1)
        tetra.write(actuator: .buzzer(0))
        tetra.write(actuator: .ledAnalog6(0))
        tetra.write(actuator: .ledAnalog5(0))
    }

    tetra.on(.light) {
        let value = UInt(max((Int(tetra.rawValue(for: .light)) - 300), 0)) / 5
//        tetra.write(actuator: .buzzer(value))
        tetra.write(actuator: .ledAnalog6(value))
//        tetra.write(actuator: .ledAnalog5(value))
    }
}
