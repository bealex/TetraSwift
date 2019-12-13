//
// BooleanDigitalActuator
// TetraSwift
//
// Created by Alex Babaev on 13 December 2019.
//

import Foundation

public class BooleanDigitalActuator: DigitalActing, CustomDebugStringConvertible {
    public let kind: DeviceKind
    public private(set) var rawValue: UInt = 0
    public var changedListener: () -> Void = {}
    public var value: Bool = false {
        didSet {
            let newRawValue: UInt = value ? 1023 : 0
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

    public init(kind: DeviceKind) {
        self.kind = kind
    }

    public var debugDescription: String { "\(kind) ~> \(value) (\(rawValue))" }
}
