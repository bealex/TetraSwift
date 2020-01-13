//
// TetraArduinoProtocolImplementation
// TetraSwift
//
// Created by Alex Babaev on 18 December 2019.
//

import Foundation

class TetraArduinoProtocolImplementation: ArduinoProtocolImplementation {
    enum DeviceKind {
        case digitalInput
        case analogInput
        case digitalOutput
        case analogOutput

        case anyActuator
    }

    private let sendBytesHandler: ([UInt8]) -> Void

    private var portToDeviceKind: [UInt8: DeviceKind] = [:]

    init(sendBytesHandler: @escaping ([UInt8]) -> Void) {
        self.sendBytesHandler = sendBytesHandler
    }

    func write(bytes: [UInt8]) {

    }
}
