//
// ArduinoProtocol
// TetraCode
//
// Created by Alex Babaev on 25 November 2019.
// Copyright (c) 2019 LonelyBytes. All rights reserved.
//

import Foundation

enum ArduinoProtocolError: Error {
    case notSupported
    case communication
    case decoding
}

protocol ArduinoProtocol: class {
    init(
        serialPort: SerialPort,
        errorHandler: @escaping (String) -> Void,
        sensorDataHandler: @escaping (_ portId: IOPort, _ parameter: Int32, _ value: Any) -> Void
    )

    func start(completion: @escaping () -> Void)
    func stop()

    func send<ValueType>(parameter: Int32, value: ValueType, to port: IOPort) throws
}
