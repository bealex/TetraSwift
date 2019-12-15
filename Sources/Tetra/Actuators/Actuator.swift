//
// Actuator
// TetraCode
//
// Created by Alex Babaev on 22 November 2019.
// Copyright (c) 2019 LonelyBytes. All rights reserved.
//

import Foundation

public protocol Actuator: class {
    var kind: DeviceKind { get }
    var rawValue: UInt { get }

    var changedListener: () -> Void { get set }
}

public protocol AnalogActuator: Actuator {
    var value: Double { get set }
}

public protocol DigitalActuator: Actuator {
    var value: Bool { get set }
}

public protocol CharacterActuator: Actuator {
    var value: Character { get set }
}

public protocol StringActuator: Actuator {
    var value: String { get set }
}
