//
//  SolutionView.swift
//  Wardle
//
//  Created by Casey Fleser on 9/15/22.
//

import SwiftUI

struct SolutionView: View {
    @EnvironmentObject var gameData : GameData

    var body: some View {
        ScrollView {
            Text("\(gameData.matchingWords.count) of \(gameData.wordList.count) possible matches")
            
            HStack(alignment: .top) {
                VStack {
                    ForEach(gameData.allWeights) { charWeight in
                        CharWeightView(charWeight)
                    }
                }
                
                Divider()
                    .padding(.horizontal, 8)
                
                ForEach(0..<5) { idx in
                    VStack {
                        ForEach(gameData.posWeights[idx]) { charWeight in
                            CharWeightView(charWeight)
                        }
                    }
                }

                Divider()
                    .padding(.horizontal, 12)

                LazyVStack(alignment: .leading) {
                    ForEach(gameData.scores) { score in
                        WordScoreView(score)
                    }
                }

            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding()
    }
}

struct SolutionView_Previews: PreviewProvider {
    @StateObject static var gameData   = GameData()
    
    static var previews: some View {
        SolutionView()
            .environmentObject(gameData)
    }
}
