//
// TetraSensorValue
// TetraCode
//
// Created by Alex Babaev on 22 November 2019.
// Copyright (c) 2019 LonelyBytes. All rights reserved.
//

import Foundation

public protocol Sensing: IdentifiableDevice {
    var kind: DeviceKind { get }
    var rawValue: UInt { get }

    func update(rawValue: UInt) -> Bool
}

public protocol AnalogSensing: Sensing {
    var value: Double { get }
}

public protocol DigitalSensing: Sensing {
    var value: Bool { get }
}
