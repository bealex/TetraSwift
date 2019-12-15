//
// LEDMatrixActuator
// TetraSwift
//
// Created by Alex Babaev on 13 December 2019.
//

import Foundation

public class LEDMatrixActuator: CharacterActuator {
    public private(set) var rawValue: UInt = 0
    public var changedListener: () -> Void = {}
    public var value: Character = " " { // Make this custom matrix
        didSet {
            changedListener()
        }
    }

    public init() {}
}
