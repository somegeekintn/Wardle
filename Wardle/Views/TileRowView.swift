//
//  TileRowView.swift
//  Wardle
//
//  Created by Casey Fleser on 9/5/22.
//

import SwiftUI

struct TileRowView: View {
    @EnvironmentObject var gameData : GameData
    @ObservedObject var row         : LetterRow
    
    var rowLock     : Binding<Bool> {
        Binding<Bool>(
            get: { row.locked },
            set: { newValue in
                withAnimation(.easeInOut(duration: 0.5)) {
                    row.locked = newValue
                    gameData.evaluate()
                }
            }
        )
    }
    
    init(_ row: LetterRow) {
        self.row = row
    }
    
    var body: some View {
        HStack(spacing: 5) {
            ForEach(row.boundLetters) { letter in
                TileView(letter: letter)
                    .disabled(row.locked)
            }
            
            Spacer().frame(width: 16)
                
            Toggle("", isOn: rowLock)
                .toggleStyle(CheckToggleStyle())
                .disabled(!row.canLock)
        }
    }
}

struct TileRowView_Previews: PreviewProvider {
    @StateObject static var letterRow = LetterRow([
            Letter("A", state: .unknown),
            Letter("B", state: .absent),
            Letter("C", state: .present),
            Letter("D", state: .correct),
            Letter(id: "p_4")], locked: false, id: "preview")
            
    static var previews: some View {
        TileRowView(letterRow)
    }
}
