//
// BooleanDigitalActuator
// TetraSwift
//
// Created by Alex Babaev on 13 December 2019.
//

import Foundation

public class BooleanDigitalActuator: DigitalActuator {
    public private(set) var rawValue: UInt
    private let onValue: UInt
    private let offValue: UInt
    public var changedListener: () -> Void = {}
    public var value: Bool = false {
        didSet {
            let newRawValue: UInt = value ? onValue : offValue
            if newRawValue != rawValue {
                rawValue = newRawValue
                changedListener()
            }
        }
    }

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
