//
//  LetterRow.swift
//  Wardle
//
//  Created by Casey Fleser on 9/7/22.
//

import SwiftUI

class LetterRow: Identifiable, ObservableObject {
    @Published var letters     : [Letter]
    @Published var locked      : Bool
    
    var id              : String
    var string          : String? { locked ? letters.map({ $0.value ?? "" }).joined() : nil }
    var firstEmptyIndex : Int? { letters.firstIndex(where: { $0.isEmpty }) }
    var deleteIndex     : Int? { let count = letters.filter({ !$0.isEmpty }).count; return count > 0 ? count - 1 : nil }
    var canLock         : Bool { !letters.contains(where: { $0.isEmpty }) }
    var boundLetters    : [Binding<Letter>] {
        (0..<letters.count).map { idx in
            Binding<Letter>(
                get: { self.letters[idx] },
                set: { letter in self.letters[idx] = letter }
            )
        }
    }

    init(id: String) {
        self.letters = (0..<5).map({ Letter(id: "\(id)_\($0)") })
        self.locked = false
        self.id = id
    }
    
    init(_ letters: [Letter], locked: Bool, id: String) {
        self.letters = letters
        self.locked = locked
        self.id = id
    }

    func addNextLetter(_ letter: Letter) {
        guard let index = firstEmptyIndex else { return }
        var idLetter    = letter
        
        idLetter.id = "\(id)_\(index)"
        letters[index] = idLetter
    }

    func removeLastLetter() {
        guard let index = deleteIndex else { return }
        
        letters[index] = Letter(id: "\(id)_\(index)")
    }
}
