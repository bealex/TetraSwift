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
    tetra.waitFor(.button2, is: true) {
        tetra.write(actuator: .ledDigital13(true))
        Thread.sleep(forTimeInterval: 1)
        tetra.write(actuator: .ledDigital13(false))
    }
}
