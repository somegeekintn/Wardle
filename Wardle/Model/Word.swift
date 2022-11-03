//
//  Word.swift
//  Wardle
//
//  Created by Casey Fleser on 11/2/22.
//

import Foundation

struct Word {
    let word        : String
    let chars       : [Character]
    let bitChars    : BitChar
    
    init(_ word: String) {
        let uWord   = word.uppercased()
        let chars   = uWord.map({ $0 })
        
        self.word = uWord
        self.chars = chars
        self.bitChars = BitChar(word: uWord)
    }
}
