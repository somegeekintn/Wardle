//
//  ContentView.swift
//  Wardle
//
//  Created by Casey Fleser on 8/30/22.
//

import SwiftUI

struct ContentView: View {

    var body: some View {
        HStack(spacing: 0) {
            GameView()
            Color.gray
                .frame(maxWidth: 1)
            SolutionView()
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
            .frame(width: 800.0)
            .environmentObject(gameData)
    }
}
