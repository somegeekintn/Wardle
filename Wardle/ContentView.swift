//
//  ContentView.swift
//  Wardle
//
//  Created by Casey Fleser on 8/30/22.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var gameData : GameData
    
    var body: some View {
        if gameData.isTesting {
            TestView()
        }
        else {
            HStack(spacing: 0) {
                GameView()
                Color.gray.frame(maxWidth: 1)
                VStack(spacing: 0) {
                    Text("\(gameData.matchingWords.count) of \(gameData.wordList.count) possible matches")
                        .font(.system(size: 16, weight: .semibold))
                        .padding(.vertical, 8)
                    Color.gray.frame(maxHeight: 1)
                    HStack {
                        WeightView()
                        Color.gray.frame(maxWidth: 1)
                        SolutionView()
                    }
                }
            }
        }
//        .padding()
//        .onAppear {
//            NSEvent.addLocalMonitorForEvents(matching: [.keyDown]) { event in
//                var returnEvent : NSEvent? = event
//
//                if !event.modifierFlags.contains([.control, .option, .command]) {
//                    if event.keyCode == 51{
//                        returnEvent = nil
//                    }
//                    else if let chars = event.characters?.first?.uppercased() {
//                        if chars.trimmingCharacters(in: .uppercaseLetters).isEmpty {
//                            returnEvent = nil
//                        }
//                    }
//                }
//
//                return returnEvent
//            }
//        }
    }
}

struct ContentView_Previews: PreviewProvider {
    @StateObject static var gameData   = GameData()
    
    static var previews: some View {
        ContentView()
            .frame(width: 1200.0)
            .environmentObject(gameData)
    }
}
