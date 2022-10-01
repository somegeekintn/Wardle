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
            LazyVStack(alignment: .leading) {
                ForEach(gameData.scores) { score in
                    WordScoreView(score)
                }
            }
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
