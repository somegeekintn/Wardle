//
//  BitChar.swift
//  Wardle
//
//  Created by Casey Fleser on 11/2/22.
//

import Foundation

struct BitChar: OptionSet {
    let rawValue    : Int
    
    init(rawValue: Int) {
        self.rawValue = rawValue
    }
    
    init(char: Character) {
        self = BitChar(rawValue: Self.bitValue(char: char))
    }
    
    init(set: Set<Character>) {
        self = BitChar(rawValue: set.reduce(0, { $0 | Self.bitValue(char: $1) }))
    }
    
    init(word: String) {
        self = BitChar(rawValue: word.reduce(0, { $0 | Self.bitValue(char: $1) }))
    }
    
    static func bitValue(char: Character) -> Int {
        switch char {
            case "A":   return 1 << 0
            case "B":   return 1 << 1
            case "C":   return 1 << 2
            case "D":   return 1 << 3
            case "E":   return 1 << 4
            case "F":   return 1 << 5
            case "G":   return 1 << 6
            case "H":   return 1 << 7
            case "I":   return 1 << 8
            case "J":   return 1 << 9
            case "K":   return 1 << 10
            case "L":   return 1 << 11
            case "M":   return 1 << 12
            case "N":   return 1 << 13
            case "O":   return 1 << 14
            case "P":   return 1 << 15
            case "Q":   return 1 << 16
            case "R":   return 1 << 17
            case "S":   return 1 << 18
            case "T":   return 1 << 19
            case "U":   return 1 << 20
            case "V":   return 1 << 21
            case "W":   return 1 << 22
            case "X":   return 1 << 23
            case "Y":   return 1 << 24
            case "Z":   return 1 << 25
            default:    return 0
        }
    }
}
