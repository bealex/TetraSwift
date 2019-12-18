//
// RawValueDecoder
// TetraSwift
//
// Created by Alex Babaev on 17 December 2019.
//

public protocol RawValueDecoder {
    associatedtype ValueType

    func decode(value: Any) throws -> ValueType
}
