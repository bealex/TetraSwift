//
// QuadDisplayHelper
// TetraCode
//
// Created by Alex Babaev on 24 November 2019.
// Copyright (c) 2019 LonelyBytes. All rights reserved.
//

// swiftlint:disable identifier_name
struct QuadDisplayHelper {
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
            case "0": return QuadDisplayHelper.digit_0
            case "1": return QuadDisplayHelper.digit_1
            case "2": return QuadDisplayHelper.digit_2
            case "3": return QuadDisplayHelper.digit_3
            case "4": return QuadDisplayHelper.digit_4
            case "5": return QuadDisplayHelper.digit_5
            case "6": return QuadDisplayHelper.digit_6
            case "7": return QuadDisplayHelper.digit_7
            case "8": return QuadDisplayHelper.digit_8
            case "9": return QuadDisplayHelper.digit_9
            case "A": return QuadDisplayHelper.digit_A
            case "a": return QuadDisplayHelper.digit_a
            case "B": return QuadDisplayHelper.digit_B
            case "b": return QuadDisplayHelper.digit_b
            case "C": return QuadDisplayHelper.digit_C
            case "c": return QuadDisplayHelper.digit_c
            case "D": return QuadDisplayHelper.digit_D
            case "d": return QuadDisplayHelper.digit_d
            case "E": return QuadDisplayHelper.digit_E
            case "e": return QuadDisplayHelper.digit_e
            case "F": return QuadDisplayHelper.digit_F
            case "f": return QuadDisplayHelper.digit_f
            case "H": return QuadDisplayHelper.digit_H
            case "h": return QuadDisplayHelper.digit_h
            case "I": return QuadDisplayHelper.digit_I
            case "i": return QuadDisplayHelper.digit_i
            case "J": return QuadDisplayHelper.digit_J
            case "j": return QuadDisplayHelper.digit_j
            case "K": return QuadDisplayHelper.digit_K
            case "k": return QuadDisplayHelper.digit_k
            case "L": return QuadDisplayHelper.digit_L
            case "l": return QuadDisplayHelper.digit_l
            case "N": return QuadDisplayHelper.digit_N
            case "n": return QuadDisplayHelper.digit_n
            case "O": return QuadDisplayHelper.digit_O
            case "o": return QuadDisplayHelper.digit_o
            case "P": return QuadDisplayHelper.digit_P
            case "p": return QuadDisplayHelper.digit_p
            case "R": return QuadDisplayHelper.digit_R
            case "r": return QuadDisplayHelper.digit_r
            case "S": return QuadDisplayHelper.digit_S
            case "s": return QuadDisplayHelper.digit_s
            case "T": return QuadDisplayHelper.digit_T
            case "t": return QuadDisplayHelper.digit_t
            case "U": return QuadDisplayHelper.digit_U
            case "u": return QuadDisplayHelper.digit_u
            case "Y": return QuadDisplayHelper.digit_Y
            case "y": return QuadDisplayHelper.digit_y

            case "˚": return QuadDisplayHelper.digit_degree
            case "-": return QuadDisplayHelper.digit_minus
            case "_": return QuadDisplayHelper.digit_underscore
            case " ": return QuadDisplayHelper.digit_space

            default: return QuadDisplayHelper.digit_underscore
        }
    }
}
