//
//  TileView.swift
//  Wardle
//
//  Created by Casey Fleser on 9/5/22.
//

import SwiftUI

struct TileView: View {
    @Binding var letter : Letter
    
    init(letter: Binding<Letter>) {
        self._letter = letter
    }
    
    var body: some View {
        if let ch = letter.value {
            Text(ch)
                .font(.system(size: 32, weight: .heavy))
                .frame(width: 62, height: 62)
                .background(letter.color)
                .onTapGesture {
                    letter.cycleState()
                }
        }
        else {
            Color("background")
                .frame(width: 62, height: 62)
                .border(Color("absent"), width: 2)
        }
    }
}

struct TileView_Previews: PreviewProvider {
    @State static var letter = Letter("A", state: .unknown)

    static var previews: some View {
        TileView(letter: $letter)
            .padding()
    }
}
