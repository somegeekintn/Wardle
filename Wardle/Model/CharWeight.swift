//
//  CharWeight.swift
//  Wardle
//
//  Created by Casey Fleser on 11/2/22.
//

import Foundation

struct CharWeight: Comparable, Identifiable {
    let char    : String
    var weight  : Double
    let column  : Int
    
    var id      : String { "\(column)_\(char)" }

    init(_ char: String, freq: Int, total: Int, column: Int = 999) {
        self.char = char
        self.weight = Double(freq) / Double(total) * 100
        self.column = column
    }
    
    init(_ char: Character, freq: Int, total: Int, column: Int = 999) {
        self.char = String(char)
        self.weight = Double(freq) / Double(total) * 100
        self.column = column
    }
    
    static func < (lhs: CharWeight, rhs: CharWeight) -> Bool {
        lhs.weight > rhs.weight
    }
}

