//
// QuadNumericDisplayActuator
// TetraSwift
//
// Created by Alex Babaev on 13 December 2019.
//

import Foundation

public class QuadNumericDisplayActuator: StringActuator, CustomDebugStringConvertible {
    public let kind: DeviceKind
    public private(set) var rawValue: UInt = 0
    public var changedListener: () -> Void = {}
    public var value: String = "" {
        didSet {
            changedListener()
        }
    }

    public init() {
        self.kind = .quadDisplay
    }

    public var debugDescription: String { "\(kind) ~> \(value)" }
}
