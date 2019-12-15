//
// TetraSensorValue
// TetraCode
//
// Created by Alex Babaev on 22 November 2019.
// Copyright (c) 2019 LonelyBytes. All rights reserved.
//

import Foundation

public protocol UpdatableSensor {
    var hasListeners: Bool { get }

    func update(rawValue: UInt)
}

public protocol Sensor: IdentifiableDevice, UpdatableSensor {
    associatedtype ValueType

    var rawValue: UInt { get }
    var value: ValueType { get }
}

public protocol AnalogSensor: Sensor {
    var value: Double { get }
}

public protocol DigitalSensor: Sensor {
    var value: Bool { get }
}
