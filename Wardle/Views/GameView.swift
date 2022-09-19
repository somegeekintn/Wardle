//
//  GameView.swift
//  Wardle
//
//  Created by Casey Fleser on 9/15/22.
//

import SwiftUI

struct GameView: View {
    @EnvironmentObject var gameData : GameData

    var body: some View {
        VStack {
            VStack {
                ForEach(gameData.letterRows) { row in
                    TileRowView(row)
                }
            }
            .padding(.bottom)
            Spacer()
            Keyboard()
            Spacer()
            Button("Reset") { gameData.reset() }
            Spacer()
        }
        .padding()
        .background(Color("background"))
    }
}

struct GameView_Previews: PreviewProvider {
    @StateObject static var gameData   = GameData()
    
    static var previews: some View {
        GameView()
            .environmentObject(gameData)
    }
}
