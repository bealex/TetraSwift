//
// LimitedAnalogActuator
// TetraSwift
//
// Created by Alex Babaev on 13 December 2019.
//

import Foundation

public class LimitedAnalogActuator: Actuator {
    public internal(set) var rawValue: UInt = 0
    public var value: Double = 0 {
        didSet {
            let newRawValue = UInt(Double(maxValue) * value)
            if newRawValue != rawValue {
                rawValue = newRawValue
                changedListener(value)
            }
        }
    }
    public var changedListener: (Double) -> Void = { _ in }

    let maxValue: UInt

    public init(maxValue: UInt) {
        self.maxValue = maxValue
    }
}
