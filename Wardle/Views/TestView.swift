//
//  TestView.swift
//  Wardle
//
//  Created by Casey Fleser on 11/1/22.
//

import SwiftUI

struct TestView: View {
    @EnvironmentObject var gameData : GameData

    var body: some View {
        let total       = Double(gameData.solutionFreq.reduce(0, { $0 + $1 }))
        let max         = Double(gameData.solutionFreq.max() ?? 0)
        let guessTotal  = Double(gameData.solutionFreq.enumerated().reduce(0, { $0 + ($1.offset + 1) * $1.element }))
        
        VStack(spacing: 32) {
            HStack {
                Text(GameData.firstGuess)
                    .font(.system(size: 24))
                Text(total == 0 ? "0.000" : (guessTotal / total).formatted(.number.precision(.fractionLength(3))))
                    .font(.system(size: 24))
            }
                
            HStack {
                let items = gameData.solutionFreq.enumerated().map({ (offset: $0.offset, element: $0.element) })
                
                ForEach(items, id: \.self.offset) { item in
                    VStack {
                        Text("\(item.element)")

                        ZStack(alignment: .bottom) {
                            Color("weight_bkg").frame(width: 48, height: 240)
                            Color("correct").frame(width: 48, height: max > 0 ? Double(item.element) / max * 240 : 0)
                        }
                        .cornerRadius(8)
                        
                        Text("\(item.offset + 1)")
                            .font(.system(size: 24))
                    }
                }
            }
            
            ZStack(alignment: .leading) {
                Color("weight_bkg").frame(width: 400, height: 24)
                Color("correct").frame(width: total > 0 ? total / Double(gameData.wordList.count) * 400 : 0, height: 24)
            }
            .cornerRadius(8)
            
            Button("END") { gameData.toggleTesting() }
                .buttonStyle(BigButton())
                .padding(.top, 16)
        }
    }
}

struct TestView_Previews: PreviewProvider {
    @StateObject static var gameData   = GameData()

    static var previews: some View {
        TestView()
            .previewLayout(.sizeThatFits)
            .environmentObject(gameData)
    }
}
