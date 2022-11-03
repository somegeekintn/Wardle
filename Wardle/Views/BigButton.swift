//
//  BigButton.swift
//  Wardle
//
//  Created by Casey Fleser on 11/2/22.
//

import SwiftUI

struct BigButton: ButtonStyle {
    @Environment(\.isEnabled) var isEnabled
    
    func makeBody(configuration: Configuration) -> some View {
            configuration.label
                .foregroundColor(.white)
                .font(.system(size: 16))
                .padding(EdgeInsets(top: 6, leading: 10, bottom: 6, trailing: 10))
                .background(.gray)
                .cornerRadius(6)
                .opacity(isEnabled ? 1.0 : 0.5)
    }
}
