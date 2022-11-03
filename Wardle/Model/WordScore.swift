//
//  WordScore.swift
//  Wardle
//
//  Created by Casey Fleser on 11/2/22.
//

import Foundation

struct WordScore: Identifiable {
    let word        : String
    let probability : Double
    let masterProb  : Double
    let commonality : Int

    var blend       : Double { Double(commonality) * probability }
    
    var id          : String { "score_\(word)" }
}
