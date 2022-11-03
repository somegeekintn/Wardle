//
//  Letter.swift
//  Wardle
//
//  Created by Casey Fleser on 9/5/22.
//

import SwiftUI

struct Letter: Identifiable {
    enum State {
        case absent
        case present
        case correct
        case unknown
    }
    
    let value   : String?
    var state   : State
    
    var id      : String
    var isEmpty : Bool { value == nil }
    
    var color   : Color {
        switch state {
            case .absent:   return Color("absent")
            case .present:  return Color("present")
            case .correct:  return Color("correct")
            case .unknown:  return Color("unknown")
        }
    }
    
    init(id: String) {
        self.value = nil
        self.state = .unknown
        self.id = id
    }
    
    init(_ value: String, state: Letter.State, id: String? = nil) {
        self.value = value
        self.state = state
        self.id = id ?? value
    }
    
    mutating func cycleState() {
        switch state {
            case .absent:   state = .present
            case .present:  state = .correct
            case .correct:  state = .absent
            case .unknown:  break
        }
    }
}
