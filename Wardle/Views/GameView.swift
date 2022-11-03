//
//  GameView.swift
//  Wardle
//
//  Created by Casey Fleser on 9/15/22.
//

import SwiftUI

struct GameView: View {
    @EnvironmentObject var gameData : GameData
    @State var answer   = ""
    
    var body: some View {
        VStack {
            HStack(alignment: .center) {
                TextField("Answer", text: $answer)
                    .font(.system(size: 16))
                    .padding(.horizontal)
                    .frame(maxWidth: 200)
                Button("Solve") { gameData.solve(answer, strategy: .probability) }
                    .buttonStyle(BigButton())
                    .disabled(answer.count != 5)
            }
            .padding(EdgeInsets(top: 0, leading: 0, bottom: 16, trailing: 72))
            
            VStack {
                ForEach(gameData.letterRows) { row in
                    TileRowView(row)
                }
            }
            .padding(.bottom)
            
            Spacer()
            Keyboard()
            Spacer()

            HStack(spacing: 64) {
                Button("RESET") { gameData.reset() }
                    .buttonStyle(BigButton())
                    .padding(.top, 16)
                Button("TEST") { gameData.toggleTesting() }
                    .buttonStyle(BigButton())
                    .padding(.top, 16)
            }
                
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
            .previewLayout(.sizeThatFits)
            .environmentObject(gameData)
    }
}
