//
//  SolutionView.swift
//  Wardle
//
//  Created by Casey Fleser on 9/15/22.
//

import SwiftUI

struct SolutionView: View {
    @EnvironmentObject var gameData : GameData
    @State var sortOrder = [KeyPathComparator(\WordScore.commonality, order: .reverse), KeyPathComparator(\WordScore.masterProb, order: .reverse)]

    var weightStyle     : FloatingPointFormatStyle<Double> { FloatingPointFormatStyle<Double>().precision(.fractionLength(3)) }
    var probStyle       : FloatingPointFormatStyle<Double> { FloatingPointFormatStyle<Double>().precision(.fractionLength(4)) }

    var body: some View {
        Table(gameData.scores.sorted(using: sortOrder), sortOrder: $sortOrder) {
            TableColumn("Word", value: \.word) { item in
                Text(item.word)
                    .font(.system(size: 14, weight: .semibold, design: .monospaced))
            }
            TableColumn("Common", value: \.commonality) { item in
                Text("\(item.commonality)")
                    .font(.system(size: 14, weight: .light, design: .monospaced))
            }
            TableColumn("Weight", value: \.weighted) { item in
                Text("\(item.weighted.formatted(weightStyle))")
                    .font(.system(size: 14, weight: .light, design: .monospaced))
            }
            TableColumn("Prob", value: \.probability) { item in
                Text("\(item.probability.formatted(probStyle))")
                    .font(.system(size: 14, weight: .light, design: .monospaced))
            }
            TableColumn("Master", value: \.masterProb) { item in
                Text("\(item.masterProb.formatted(probStyle))")
                    .font(.system(size: 14, weight: .light, design: .monospaced))
            }
        }
    }
}

struct SolutionView_Previews: PreviewProvider {
    @StateObject static var gameData   = GameData()
    
    static var previews: some View {
        SolutionView()
            .environmentObject(gameData)
    }
}
