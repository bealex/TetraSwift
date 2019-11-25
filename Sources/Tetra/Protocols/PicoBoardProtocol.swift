//
// PicoBoardProtocol
// TetraCode
//
// Created by Alex Babaev on 22 November 2019.
// Copyright (c) 2019 LonelyBytes. All rights reserved.
//

import Foundation

/**
    This is PicoBoard protocol. I do not have any source for it (except S4A Arduino Sketch that shows everything
    I want to know). Basics is like this (looks like source is https://github.com/sparkfun/PicoBoard):

    1. There are two parts: Arduino port index and value (that is being read or being written).
    2. Every protocol packet is 2 bytes. Bits in these are: 1 PPPP 0 VVVVVVVVVV, where
       - 1/0 — reserved bits. Don't know why do we need them
       - PPPP — port index (4 bits, 16 ports)
       — VVVVVVVVVV — value (10 bits, values 0–1023)
    3. Port indexes mapping is below. It is defined in the Sketch, but here is default one for Tetra.
        0, 1, 2, 3 — inputs
        4, 7, 8 — motors
        5, 6, 9 — pulse width modulation pins (pwm), that can be used as kind-of-analog, but really are digital
        10, 11, 12, 13 — digital outputs
        Totally there are 14 ports by default.

    I consider this reference implementation: https://github.com/sparkfun/PicoBoard/blob/master/firmware/main.c
    ```
    void buildScratchPacket(char * packet, int channel, int value) {
        char upper_data = (char)((value & (unsigned int) 0x380) >> 7); //Get the upper 3 bits of the value
        char lower_data = (char)(value & 0x7f); //Get the lower 7 bits of the value
        *packet ++= ((1 << 7) | (channel << 3) | (upper_data));
        *packet ++= lower_data;
    }
    ```
 */

// This is PicoBoard protocol, essentially all of it :-)
class PicoBoardProtocol: ArduinoProtocol {
    func decode(from bytes: [UInt8]) -> (id: UInt8, value: Int) {
        let id = (bytes[0] >> 3) & 0b1111
        let value = (UInt((bytes[0] & 0b111)) << 7) | (UInt(bytes[1]) & 0b1111111)
        return (id, Int(value))
    }

    func encode(id: UInt8, value: Int) -> [UInt8] {
        let unsigned = UInt(value)
        return [
            UInt8(truncatingIfNeeded: 0b10000000 | (UInt(id & 0b1111) << 3) | (UInt(unsigned >> 7) & 0b111)),
            UInt8(truncatingIfNeeded: unsigned & 0b1111111)
        ]
    }
}
