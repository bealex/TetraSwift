//
// TetraEvent
// TetraCode
//
// Created by Alex Babaev on 22 November 2019.
// Copyright (c) 2019 LonelyBytes. All rights reserved.
//

import Foundation

enum TetraEvent: CustomDebugStringConvertible {
    case started
    case stopped

    case error(String?)

    case sensor(Tetra.Sensor.Value)

    var debugDescription: String {
        switch self {
            case .started:
                return "Started"
            case .stopped:
                return "Stopped"
            case .sensor(let value):
                return value.debugDescription
            case .error(let message):
                return "Error: \(message ?? "nil")"
        }
    }
}
