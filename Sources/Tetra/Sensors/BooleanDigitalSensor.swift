//
// BooleanDigitalSensor
// TetraSwift
//
// Created by Alex Babaev on 13 December 2019.
//

import Foundation

public class BooleanDigitalSensor: DigitalSensor {
    public let id: UUID = UUID()
    public let kind: DeviceKind
    public private(set) var rawValue: UInt = 0

    @SensorValue
    public private(set) var value: Bool = false
    public var hasListeners: Bool { _value.hasListeners }

    public init(kind: DeviceKind) {
        self.kind = kind
    }

    /// Returns whether the value was changed.
    public func update(rawValue: UInt) {
        guard self.rawValue != rawValue else { return }

        self.rawValue = rawValue
        value = rawValue <= 512
    }

    public func whenValueChanged(listener: @escaping (_ value: Bool) -> Void) {
        _value.whenValueChanged(do: listener)
    }

    public func whenOn(listener: @escaping () -> Void) {
        _value.whenOn { _ in listener() }
    }

    public func whenOff(listener: @escaping () -> Void) {
        _value.whenOff { _ in listener() }
    }
}
