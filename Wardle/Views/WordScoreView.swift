//
//  WordScoreView.swift
//  Wardle
//
//  Created by Casey Fleser on 9/17/22.
//

import SwiftUI

struct WordScoreView: View {
    static let scoreFormatter   = {
        let formatter = NumberFormatter()
        
        formatter.minimumFractionDigits = 3
        
        return formatter
    }()
    
    let wordScore           : WordScore
    
    var formattedprobability   : String {
        WordScoreView.scoreFormatter.string(from: NSNumber(value: wordScore.probability)) ?? "\(wordScore.probability)"
    }
    
    var formattedweighted   : String {
        WordScoreView.scoreFormatter.string(from: NSNumber(value: wordScore.weighted)) ?? "\(wordScore.weighted)"
    }
    
    init(_ wordScore: WordScore) {
        self.wordScore = wordScore
    }
    
    var body: some View {
        HStack {
            Text(wordScore.word)
                .font(.system(size: 18, weight: .semibold, design: .monospaced))
                .padding(.trailing, 8)
            Text("\(wordScore.commonality) | \(formattedweighted) | \(formattedprobability)")
                .font(.system(size: 14, weight: .light, design: .monospaced))
        }
    }
}

struct WordScoreView_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            WordScoreView(WordScore(word: "STARE", probability: (3 + 1/3), masterProb: 0.5, weighted: 1234, commonality: 127))
            WordScoreView(WordScore(word: "SAINT", probability: 0.001, masterProb: 0.5, weighted: 999, commonality: 321))
        }
    }
}
