//
// QuadDisplayDigits
// TetraCode
//
// Created by Alex Babaev on 24 November 2019.
// Copyright (c) 2019 LonelyBytes. All rights reserved.
//

// swiftlint:disable identifier_name
struct QuadDisplayDigits {
    private static let digit_0: UInt8 = 0b00000011
    private static let digit_1: UInt8 = 0b10011111
    private static let digit_2: UInt8 = 0b00100101
    private static let digit_3: UInt8 = 0b00001101
    private static let digit_4: UInt8 = 0b10011001
    private static let digit_5: UInt8 = 0b01001001
    private static let digit_6: UInt8 = 0b01000001
    private static let digit_7: UInt8 = 0b00011111
    private static let digit_8: UInt8 = 0b00000001
    private static let digit_9: UInt8 = 0b00001001

    private static let digit_A: UInt8 = 0b00010001
    private static let digit_a: UInt8 = 0b00000101
    private static let digit_B: UInt8 = 0b11000001
    private static let digit_b: UInt8 = 0b11000001
    private static let digit_C: UInt8 = 0b01100011
    private static let digit_c: UInt8 = 0b11100101
    private static let digit_D: UInt8 = 0b10000101
    private static let digit_d: UInt8 = 0b10000101
    private static let digit_E: UInt8 = 0b01100001
    private static let digit_e: UInt8 = 0b01100001
    private static let digit_F: UInt8 = 0b01110001
    private static let digit_f: UInt8 = 0b01110001
    private static let digit_H: UInt8 = 0b10010001
    private static let digit_h: UInt8 = 0b11010001
    private static let digit_I: UInt8 = 0b10011111
    private static let digit_i: UInt8 = 0b10011111
    private static let digit_J: UInt8 = 0b10001111
    private static let digit_j: UInt8 = 0b10001111
    private static let digit_K: UInt8 = 0b10010001
    private static let digit_k: UInt8 = 0b10010001
    private static let digit_L: UInt8 = 0b11100011
    private static let digit_l: UInt8 = 0b11100011
    private static let digit_N: UInt8 = 0b11010101
    private static let digit_n: UInt8 = 0b11010101
    private static let digit_O: UInt8 = 0b00000011
    private static let digit_o: UInt8 = 0b11000101
    private static let digit_P: UInt8 = 0b00110001
    private static let digit_p: UInt8 = 0b00110001
    private static let digit_R: UInt8 = 0b11110101
    private static let digit_r: UInt8 = 0b11110101
    private static let digit_S: UInt8 = 0b01001001
    private static let digit_s: UInt8 = 0b01001001
    private static let digit_T: UInt8 = 0b11100001
    private static let digit_t: UInt8 = 0b11100001
    private static let digit_U: UInt8 = 0b10000011
    private static let digit_u: UInt8 = 0b11000111
    private static let digit_Y: UInt8 = 0b10001001
    private static let digit_y: UInt8 = 0b10001001

    private static let digit_minus: UInt8 = 0b11111101
    private static let digit_underscore: UInt8 = 0b11101111
    private static let digit_degree: UInt8 = 0b00111001
    private static let digit_under_degree: UInt8 = 0b11000101

    static let digit_space: UInt8 = 0b11111111
    static let digit_dot: UInt8 = 0b11111110

    // swiftlint:disable cyclomatic_complexity
    static func encode(character: Character) -> UInt8? {
        switch character {
            case "0": return QuadDisplayDigits.digit_0
            case "1": return QuadDisplayDigits.digit_1
            case "2": return QuadDisplayDigits.digit_2
            case "3": return QuadDisplayDigits.digit_3
            case "4": return QuadDisplayDigits.digit_4
            case "5": return QuadDisplayDigits.digit_5
            case "6": return QuadDisplayDigits.digit_6
            case "7": return QuadDisplayDigits.digit_7
            case "8": return QuadDisplayDigits.digit_8
            case "9": return QuadDisplayDigits.digit_9
            case "A": return QuadDisplayDigits.digit_A
            case "a": return QuadDisplayDigits.digit_a
            case "B": return QuadDisplayDigits.digit_B
            case "b": return QuadDisplayDigits.digit_b
            case "C": return QuadDisplayDigits.digit_C
            case "c": return QuadDisplayDigits.digit_c
            case "D": return QuadDisplayDigits.digit_D
            case "d": return QuadDisplayDigits.digit_d
            case "E": return QuadDisplayDigits.digit_E
            case "e": return QuadDisplayDigits.digit_e
            case "F": return QuadDisplayDigits.digit_F
            case "f": return QuadDisplayDigits.digit_f
            case "H": return QuadDisplayDigits.digit_H
            case "h": return QuadDisplayDigits.digit_h
            case "I": return QuadDisplayDigits.digit_I
            case "i": return QuadDisplayDigits.digit_i
            case "J": return QuadDisplayDigits.digit_J
            case "j": return QuadDisplayDigits.digit_j
            case "K": return QuadDisplayDigits.digit_K
            case "k": return QuadDisplayDigits.digit_k
            case "L": return QuadDisplayDigits.digit_L
            case "l": return QuadDisplayDigits.digit_l
            case "N": return QuadDisplayDigits.digit_N
            case "n": return QuadDisplayDigits.digit_n
            case "O": return QuadDisplayDigits.digit_O
            case "o": return QuadDisplayDigits.digit_o
            case "P": return QuadDisplayDigits.digit_P
            case "p": return QuadDisplayDigits.digit_p
            case "R": return QuadDisplayDigits.digit_R
            case "r": return QuadDisplayDigits.digit_r
            case "S": return QuadDisplayDigits.digit_S
            case "s": return QuadDisplayDigits.digit_s
            case "T": return QuadDisplayDigits.digit_T
            case "t": return QuadDisplayDigits.digit_t
            case "U": return QuadDisplayDigits.digit_U
            case "u": return QuadDisplayDigits.digit_u
            case "Y": return QuadDisplayDigits.digit_Y
            case "y": return QuadDisplayDigits.digit_y

            case "˚": return QuadDisplayDigits.digit_degree
            case "-": return QuadDisplayDigits.digit_minus
            case "_": return QuadDisplayDigits.digit_underscore
            case " ": return QuadDisplayDigits.digit_space

            default: return QuadDisplayDigits.digit_underscore
        }
    }
}
