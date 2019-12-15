//
// Actuators
// TetraSwift
//
// Created by Alex Babaev on 13 December 2019.
//

import Foundation

public class Motor: LimitedAnalogActuator {
    public init() {
        super.init(kind: .motor, maxValue: 180)
    }
}

public class Buzzer: BooleanDigitalActuator {
    public init() {
        super.init(kind: .buzzer, onValue: 10, offValue: 0)
    }
}

public class DigitalLED: BooleanDigitalActuator {
    public init(color: DeviceKind.LEDColor) {
        super.init(kind: .digitalLED(color), onValue: 1023, offValue: 0)
    }
}

public class AnalogLED: LimitedAnalogActuator {
    public init(color: DeviceKind.LEDColor) {
        super.init(kind: .analogLED(color), maxValue: 200)
    }

    public func on() {
        value = 1
    }

    public func off() {
        value = 0
    }
}