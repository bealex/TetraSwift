//
// Analog10bitDecoder
// TetraSwift
//
// Created by Alex Babaev on 17 December 2019.
//

import Foundation

public class Analog10bitDecoder: RawValueDecoder {
    private let samplesCount: Int

    private var samples: [UInt] = []
    private var average: Double = 0

    init(samplesCount: Int = 1) {
        self.samplesCount = samplesCount
    }

    public func decode(value: Any) throws -> Double {
        guard let value = value as? UInt else { throw SensorError.wrongRawType }

        samples.append(value)
        samples = samples.suffix(samplesCount)

        return samples.reduce(Double(0)) { $0 + Double($1) } / Double(samples.count)
    }
}
