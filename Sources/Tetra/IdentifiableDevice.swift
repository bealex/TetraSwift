//
// IdentifiableDevice
// TetraSwift
//
// Created by Alex Babaev on 01 December 2019.
// Copyright (c) 2019 LonelyBytes. All rights reserved.
//

import Foundation

public protocol IdentifiableDevice {
    var id: UUID { get }
}
