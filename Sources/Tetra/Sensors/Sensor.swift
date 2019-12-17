//
// TetraSensorValue
// TetraCode
//
// Created by Alex Babaev on 22 November 2019.
// Copyright (c) 2019 LonelyBytes. All rights reserved.
//

import Foundation

enum SensorError: Error {
    case wrongRawType
}

public protocol Sensor {
    associatedtype ValueType

    var sensorValue: SensorValue<ValueType> { get }

    func update(rawValue: Any) throws
}

public extension Sensor {
    var value: ValueType { sensorValue.value }
}

public extension Sensor {
    func whenValueChanged(do action: @escaping (_ value: ValueType) -> Void) {
        sensorValue.when(condition: { _ in true }, do: action)
    }

    func whenValueChanged(action: @escaping () -> Void) {
        whenValueChanged(do: { _ in action() })
    }
}

public extension Sensor where ValueType == Double {
    func when(lessThan compareValue: Double, action: @escaping (_ value: Double) -> Void) {
        sensorValue.when(condition: { $0 < compareValue }, do: action)
    }

    func when(greaterThan compareValue: Double, action: @escaping (_ value: Double) -> Void) {
        sensorValue.when(condition: { $0 > compareValue }, do: action)
    }

    func when(lessThan compareValue: Double, action: @escaping () -> Void) {
        sensorValue.when(condition: { $0 < compareValue }, do: { _ in action() })
    }

    func when(greaterThan compareValue: Double, action: @escaping () -> Void) {
        sensorValue.when(condition: { $0 > compareValue }, do: { _ in action() })
    }
}

public extension Sensor where ValueType == Bool {
    func whenOn(action: @escaping () -> Void) {
        sensorValue.when(condition: { $0 }, do: { _ in action() })
    }

    func whenOff(action: @escaping () -> Void) {
        sensorValue.when(condition: { !$0 }, do: { _ in action() })
    }
}
