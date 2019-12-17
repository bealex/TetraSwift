//
// Digital10bitDecoder
// TetraSwift
//
// Created by Alex Babaev on 17 December 2019.
//

import Foundation

public class Digital10bitDecoder: RawValueDecoder {
    public func decode(value: Any) throws -> Bool {
        guard let value = value as? UInt else { throw SensorError.wrongRawType }

        return value <= 512
    }
}
