//
// BooleanDigitalActuator
// TetraSwift
//
// Created by Alex Babaev on 13 December 2019.
//

import Foundation

public class BooleanDigitalActuator: Actuator {
    public private(set) var rawValue: UInt
    public var value: Bool = false {
        didSet {
            let newRawValue: UInt = value ? onValue : offValue
            if newRawValue != rawValue {
                rawValue = newRawValue
                changedListener(value)
            }
        }
    }
    public var changedListener: (Bool) -> Void = { _ in }

    private let onValue: UInt
    private let offValue: UInt

    public func on() {
        value = true
    }

    public func off() {
        value = false
    }

    public init(onValue: UInt, offValue: UInt = 0) {
        self.onValue = onValue
        self.offValue = offValue
        rawValue = offValue
    }
}
