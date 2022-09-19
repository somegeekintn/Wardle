//
//  CharWeightView.swift
//  Wardle
//
//  Created by Casey Fleser on 9/15/22.
//

import SwiftUI

struct CharWeightView: View {
    static let weightFormatter   = {
        let formatter = NumberFormatter()
        
        formatter.minimumFractionDigits = 1
        
        return formatter
    }()

    let charWeight      : CharWeight
    
    var formattedWeight : String {
        CharWeightView.weightFormatter.string(from: NSNumber(value: charWeight.weight)) ?? "\(charWeight.weight)"
    }
    var saturation      : Double {
        min(1.0, (charWeight.weight / 60))
    }

    init(_ charWeight: CharWeight) {
        self.charWeight = charWeight
    }
    
    var body: some View {
        VStack(spacing: 0) {
            Text(charWeight.char)
                .font(.system(size: 24, weight: .heavy))
                .frame(maxHeight: .infinity)
                
            Color.white.opacity(0.4).frame(height: 1)
                .padding(.vertical, 1)

            Text("\(formattedWeight)%")
                .font(.system(size: 12, weight: .light))
                .frame(maxHeight: .infinity)
        }
        .padding(4)
        .frame(width: 50, height: 50)
        .background(Color(NSColor(calibratedHue: 120 / 360, saturation: saturation, brightness: 0.5, alpha: 1.0)))
        .border(Color.white.opacity(0.1))
    }
}

struct CharWeightView_Previews: PreviewProvider {
    static var previews: some View {
        CharWeightView(CharWeight("A", freq: 200, total: 1000))
    }
}
