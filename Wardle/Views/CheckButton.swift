//
//  CheckButton.swift
//  Wardle
//
//  Created by Casey Fleser on 9/7/22.
//

import SwiftUI

struct CheckToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        Button(action: { configuration.isOn.toggle() }) {
            ZStack {
                Circle()
                    .foregroundColor(configuration.isOn ? Color("correct") : Color("absent"))
                    .frame(width: 48, height: 48)
                    
                Image(systemName: "checkmark")
                    .resizable()
                    .font(.system(.largeTitle).bold())
                    .frame(width: 24, height: 24)
            }
        }
        .buttonStyle(.plain)
    }
}

struct CheckButton: View {
    @State var value    = false
    
    var body: some View {
        Toggle("", isOn: $value)
            .toggleStyle(CheckToggleStyle())
    }
}

struct CheckButton_Previews: PreviewProvider {
    static var previews: some View {
        CheckButton()
    }
}
