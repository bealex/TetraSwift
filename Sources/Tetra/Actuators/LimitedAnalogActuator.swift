//
// LimitedAnalogActuator
// TetraSwift
//
// Created by Alex Babaev on 13 December 2019.
//

import Foundation

public class LimitedAnalogActuator: AnalogActing, CustomDebugStringConvertible {
    public let kind: DeviceKind
    public var changedListener: () -> Void = {}
    public internal(set) var rawValue: UInt = 0

    let maxValue: UInt

    public var value: Double = 0 {
        didSet {
            let newRawValue = UInt(Double(maxValue) * value)
            if newRawValue != rawValue {
                rawValue = newRawValue
                changedListener()
            }
        }
    }

    public init(kind: DeviceKind, maxValue: UInt) {
        self.kind = kind
        self.maxValue = maxValue
    }

    public var debugDescription: String { "\(kind) ~> \(value) (\(rawValue))" }
}
