//
// ArduinoProtocol
// TetraCode
//
// Created by Alex Babaev on 25 November 2019.
// Copyright (c) 2019 LonelyBytes. All rights reserved.
//

import Foundation

enum ArduinoBoardError: Error {
    case notSupported
}

protocol ArduinoBoard: class {
    init(
        serialPort: SerialPort,
        errorHandler: @escaping (String) -> Void,
        sensorDataHandler: @escaping (_ portId: UInt8, _ value: Any) -> Void
    )

    func start(completion: @escaping () -> Void)
    func stop()

    func send<ValueType>(value: ValueType, to port: IOPort) throws
}
