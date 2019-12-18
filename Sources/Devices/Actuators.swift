//
// Actuators
// TetraSwift
//
// Created by Alex Babaev on 13 December 2019.
//

import Foundation

public class Motor: LimitedAnalogActuator {
    public init() {
        super.init(maxValue: 180)
    }
}

public class Buzzer: BooleanDigitalActuator {
    public init() {
        super.init(onValue: 10, offValue: 0)
    }
}

public class DigitalLED: BooleanDigitalActuator {
    public init() {
        super.init(onValue: 1023, offValue: 0)
    }
}

public class AnalogLED: LimitedAnalogActuator {
    public init() {
        super.init(maxValue: 200)
    }

    public func on() {
        value = 1
    }

    public func off() {
        value = 0
    }
}
