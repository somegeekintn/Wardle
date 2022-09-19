//
//  Keyboard.swift
//  Wardle
//
//  Created by Casey Fleser on 9/4/22.
//

import SwiftUI

struct Keyboard: View {
    struct Key: ExpressibleByStringLiteral, Identifiable {
        enum Role {
            case letter(_ char: String)
            case enter
            case del
        }
        
        let key     : Role
        var id      : String { title }
        
        var title   : String {
            switch key {
                case .letter(let char): return char
                case .enter:            return "Enter"
                case .del:              return "Del"
            }
        }
        
        var width   : CGFloat {
            switch key {
                case .letter:   return 44
                case .enter:    return 66
                case .del:      return 66
            }
        }
        
        init(stringLiteral value: String) {
            switch value {
                case "Enter":   self.key = .enter
                case "Del":     self.key = .del
                default:        self.key = .letter(value)
            }
        }
    }
    
    struct KeyRow: Identifiable {
        let keys    : [Key]
        var id      : String { keys.map({ $0.id }).joined() }
    }
    
    @EnvironmentObject var gameData : GameData
    
    let keys     : [KeyRow] = [
                                .init(keys: ["Q", "W", "E", "R", "T", "Y", "U", "I", "O", "P"]),
                                .init(keys: ["A", "S", "D", "F", "G", "H", "J", "K", "L"]),
                                .init(keys: ["Enter", "Z", "X", "C", "V", "B", "N", "M", "Del"])
                            ]
    
    var body: some View {
        VStack {
            ForEach(keys) { row in
                HStack {
                    ForEach(row.keys) { ch in
                        Button(ch.title) {
                            switch ch.key {
                                case .del:
                                    gameData.removeLastLetter()
                                    
                                case .enter:
                                    print("Enter")

                                case .letter(let ch):
                                    gameData.addNextLetter(Letter(ch, state: .absent))
                            }
                        }
                        .buttonStyle(KeyStyle(ch))
                    }
                }
            }
        }
    }
}

struct KeyStyle: ButtonStyle {
    let key     : Keyboard.Key
    
    init(_ key: Keyboard.Key) {
        self.key = key
    }
    
    func makeBody(configuration: Configuration) -> some View {
        ZStack {
            Color("unknown")
                .frame(width: key.width, height: 58)
                .cornerRadius(4)
            configuration.label
                .foregroundColor(.white)
                .font(.system(size: 14, weight: .semibold))
        }
        .opacity(configuration.isPressed ? 0.8 : 1.0)
    }
}

struct Keyboard_Previews: PreviewProvider {
    static var previews: some View {
        Keyboard()
    }
}
