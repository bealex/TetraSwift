//
// LEDMatrixActuator
// TetraSwift
//
// Created by Alex Babaev on 13 December 2019.
//

import Foundation

public class LEDMatrixActuator: Actuator {
    public private(set) var rawValue: UInt = 0
    public var value: Character = " " { // Make this custom matrix
        didSet {
            changedListener(value)
        }
    }
    public var changedListener: (Character) -> Void = { _ in }

    public init() {}
}
