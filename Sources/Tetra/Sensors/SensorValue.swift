//
// SensorValue
// TetraSwift
//
// Created by Alex Babaev on 15 December 2019.
//

import Foundation

@propertyWrapper
public class SensorValue<T> {
    public private(set) var value: T

    private var listeners: [(condition: (_ value: T) -> Bool, action: (_ value: T) -> Void)] = []
    var hasListeners: Bool { !listeners.isEmpty }

    public internal(set) var wrappedValue: T {
        get { value }
        set {
            self.value = newValue
            listeners
                .filter { $0.condition(value) }
                .forEach { $0.action(value) }
        }
    }

    public init(wrappedValue: T) {
        value = wrappedValue
        self.wrappedValue = wrappedValue
    }

    public func when(condition: @escaping (_ value: T) -> Bool, do action: @escaping (_ value: T) -> Void) {
        listeners.append((condition, action))
    }

    public func whenValueChanged(do action: @escaping (_ value: T) -> Void) {
        when(condition: { _ in true }, do: action)
    }
}

extension SensorValue where T == Bool {
    public func whenOn(do action: @escaping (_ value: T) -> Void) {
        when(condition: { value in value }, do: action)
    }

    public func whenOff(do action: @escaping (_ value: T) -> Void) {
        when(condition: { value in !value }, do: action)
    }
}

extension SensorValue where T == Double {
    public func when(lessThan compareValue: Double, do action: @escaping (_ value: T) -> Void) {
        when(condition: { value in value < compareValue }, do: action)
    }

    public func when(greaterThan compareValue: Double, do action: @escaping (_ value: T) -> Void) {
        when(condition: { value in value > compareValue }, do: action)
    }
}
