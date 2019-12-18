//
// Actuator
// TetraCode
//
// Created by Alex Babaev on 22 November 2019.
// Copyright (c) 2019 LonelyBytes. All rights reserved.
//

import Foundation

public protocol Actuator: class {
    associatedtype ValueType

    var value: ValueType { get set }
    var changedListener: (ValueType) -> Void { get set }
}
