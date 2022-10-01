//
//  WeightView.swift
//  Wardle
//
//  Created by Casey Fleser on 9/27/22.
//

import SwiftUI

struct WeightView: View {
    @EnvironmentObject var gameData : GameData

    var body: some View {
        ScrollView {
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
            }
        }
        .padding()
    }
}

struct WeightView_Previews: PreviewProvider {
    @StateObject static var gameData   = GameData()
    
    static var previews: some View {
        WeightView()
            .environmentObject(gameData)
    }
}
