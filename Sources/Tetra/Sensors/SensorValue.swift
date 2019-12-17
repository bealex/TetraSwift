//
// SensorValue
// TetraSwift
//
// Created by Alex Babaev on 15 December 2019.
//

public class SensorValue<T> {
    private var listeners: [(condition: (_ value: T) -> Bool, action: (_ value: T) -> Void)] = []

    public internal(set) var value: T {
        didSet {
            listeners
                .filter { $0.condition(value) }
                .forEach { $0.action(value) }
        }
    }

    init(value: T) {
        self.value = value
    }

    public func when(condition: @escaping (_ value: T) -> Bool, do action: @escaping (_ value: T) -> Void) {
        listeners.append((condition, action))
    }
}
