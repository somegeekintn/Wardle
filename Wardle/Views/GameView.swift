//
//  GameView.swift
//  Wardle
//
//  Created by Casey Fleser on 9/15/22.
//

import SwiftUI

struct GameView: View {
    @EnvironmentObject var gameData : GameData
    @State var startingWord = ""
    @State var answer       = ""
    
    var body: some View {
        VStack(spacing: 16) {
            HStack(alignment: .center) {
                TextField("Answer", text: $answer)
                    .font(.system(size: 16))
                    .frame(maxWidth: 128)
                    .onSubmit(solveForAnswer)
                
                Button("Solve", action: solveForAnswer)
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
            
            Keyboard()

            HStack(spacing: 64) {
                HStack {
                    TextField("Starting word", text: $startingWord)
                        .font(.system(size: 16))
                        .frame(maxWidth: 128)
                        .onSubmit(updateStartingWord)
                        
                    Button("Update", action: updateStartingWord)
                        .buttonStyle(BigButton())
                        .disabled(startingWord.count != 5)
                        
                    Button("Test") { gameData.toggleTesting() }
                        .buttonStyle(BigButton())
                }
                
                Button("Reset") { gameData.reset() }
                    .buttonStyle(BigButton())
            }
            .padding(.top)

            Spacer()
        }
        .padding()
        .background(Color("background"))
        .onAppear { startingWord = gameData.startingWord }
    }
    
    func solveForAnswer() {
        answer = answer.uppercased()
        gameData.solve(answer, strategy: .blend)
    }
    
    func updateStartingWord() {
        let adjWord = startingWord.uppercased()
        
        gameData.startingWord = adjWord
        startingWord = adjWord
    }
}

struct GameView_Previews: PreviewProvider {
    @StateObject static var gameData   = GameData()
    
    static var previews: some View {
        GameView()
            .environmentObject(gameData)
    }
}
