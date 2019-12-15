//
// ArduinoProtocol
// TetraCode
//
// Created by Alex Babaev on 25 November 2019.
// Copyright (c) 2019 LonelyBytes. All rights reserved.
//

import Foundation

protocol ArduinoBoard: class {
    init(
        serialPort: SerialPort,
        errorHandler: @escaping (String) -> Void,
        sensorDataHandler: @escaping ([(portId: UInt8, value: UInt)]) -> Void
    )

    func start()
    func stop()

    func showOnQuadDisplay(portId: UInt8, value: String)
    func showOnLEDMatrix(portId: UInt8, brightness: Double, character: Character)

    func sendRawActuatorValue(portId: UInt8, rawValue: UInt)
}
