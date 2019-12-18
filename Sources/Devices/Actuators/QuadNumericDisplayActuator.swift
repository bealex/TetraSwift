//
// QuadNumericDisplayActuator
// TetraSwift
//
// Created by Alex Babaev on 13 December 2019.
//

import Foundation

public class QuadNumericDisplayActuator: Actuator {
    public private(set) var rawValue: UInt = 0
    public var value: String = "" {
        didSet {
            changedListener(value)
        }
    }
    public var changedListener: (String) -> Void = { _ in }

    public init() {}
}
