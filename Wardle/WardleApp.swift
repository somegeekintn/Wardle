//
//  WardleApp.swift
//  Wardle
//
//  Created by Casey Fleser on 8/30/22.
//


// See: https://github.com/seanpatlan/wordle-words & https://github.com/tabatkins/wordle-list

// what about saint? or saine?
// https://hackernoon.com/saine-is-mathematically-one-of-the-best-wordle-starting-words-heres-why

// saine
// saint
// stare

import SwiftUI

@main
struct WardleApp: App {
    @StateObject var gameData   = GameData()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(gameData)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

