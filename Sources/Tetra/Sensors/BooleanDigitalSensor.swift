//
// BooleanDigitalSensor
// TetraSwift
//
// Created by Alex Babaev on 13 December 2019.
//

import Foundation

public class BooleanDigitalSensor: DigitalSensing, CustomDebugStringConvertible {
    public let id: UUID = UUID()
    public let kind: DeviceKind
    public private(set) var rawValue: UInt = 0
    public private(set) var value: Bool = false

    public init(kind: DeviceKind) {
        self.kind = kind
    }

    /// Returns whether the value was changed.
    public func update(rawValue: UInt) -> Bool {
        let valueChanged = self.rawValue != rawValue
        self.rawValue = rawValue
        value = rawValue <= 512

        return valueChanged
    }

    public var debugDescription: String { "\(kind) ~> \(value) (\(rawValue))" }
}
