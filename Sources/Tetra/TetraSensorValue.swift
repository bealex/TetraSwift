//
// TetraSensorValue
// TetraCode
//
// Created by Alex Babaev on 23 November 2019.
// Copyright (c) 2019 LonelyBytes. All rights reserved.
//

import Foundation

extension Tetra.Sensor {
    struct Value<T>: Equatable {
        var sensor: Tetra.Sensor
        var rawValue: UInt
        var value: () -> T? = { nil }

        init(sensor: Tetra.Sensor, rawValue: UInt) {
            self.sensor = sensor
            self.rawValue = rawValue
        }

        func digitalValue() -> Bool { rawValue <= 512 }
        func analogValue() -> Double { Double(rawValue) / 255 }

        var debugDescription: String { "\(sensor.kind): \(String(describing: value()))" }

        static func == (lhs: Value, rhs: Value) -> Bool {
            lhs.sensor == rhs.sensor && abs(Int(lhs.rawValue) - Int(rhs.rawValue)) <= lhs.sensor.tolerance
        }
    }
}
