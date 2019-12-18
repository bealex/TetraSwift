//
// List
// TetraCode
//
// Created by Alex Babaev on 24 November 2019.
// Copyright (c) 2019 LonelyBytes. All rights reserved.
//

import Foundation

public class List<T> {
    private let type: String
    private var holder: [IOPort: T] = [:]

    init(type: String) {
        self.type = type
    }

    public subscript(port: IOPort) -> T {
        get {
            if let result = holder[port] {
                return result
            } else {
                fatalError("Can't find \(type) with id \(port)")
            }
        }
        set {
            holder[port] = newValue
        }
    }

    public var any: T {
        if let result = holder.values.first {
            return result
        } else {
            fatalError("No devices of \"\(type)\" present")
        }
    }

    public var single: T {
        if holder.count == 1, let result = holder.values.first {
            return result
        } else {
            if holder.count > 1 {
                fatalError("More than one \(type) present")
            } else {
                fatalError("No devices with type \"\(type)\" present")
            }
        }
    }

    func set(_ value: T?, for port: IOPort) {
        holder[port] = value
    }
}
