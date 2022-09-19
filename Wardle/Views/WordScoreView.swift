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
    
    var formattedPosScore   : String {
        WordScoreView.scoreFormatter.string(from: NSNumber(value: wordScore.posScore)) ?? "\(wordScore.posScore)"
    }
    
    var formattedFreqScore   : String {
        WordScoreView.scoreFormatter.string(from: NSNumber(value: wordScore.freqScore)) ?? "\(wordScore.freqScore)"
    }
    
    init(_ wordScore: WordScore) {
        self.wordScore = wordScore
    }
    
    var body: some View {
        HStack {
            Text(wordScore.word)
                .font(.system(size: 18, weight: .semibold, design: .monospaced))
                .padding(.trailing, 8)
            Text("\(wordScore.commonScore) | \(formattedFreqScore) | \(formattedPosScore)")
                .font(.system(size: 14, weight: .light, design: .monospaced))
        }
    }
}

struct WordScoreView_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            WordScoreView(WordScore(word: "STARE", posScore: (3 + 1/3), freqScore: 1234, commonScore: 127))
            WordScoreView(WordScore(word: "SAINT", posScore: 0.001, freqScore: 999, commonScore: 321))
        }
    }
}
