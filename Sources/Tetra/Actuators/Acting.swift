//
// Acting
// TetraCode
//
// Created by Alex Babaev on 22 November 2019.
// Copyright (c) 2019 LonelyBytes. All rights reserved.
//

import Foundation

public protocol Acting: class {
    var kind: DeviceKind { get }
    var rawValue: UInt { get }

    var changedListener: () -> Void { get set }
}

public protocol AnalogActing: Acting {
    var value: Double { get set }
}

public protocol DigitalActing: Acting {
    var value: Bool { get set }
}

public protocol CharacterActing: Acting {
    var value: Character { get set }
}

public protocol StringActing: Acting {
    var value: String { get set }
}
