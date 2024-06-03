//
//  ButtonViewModel.swift
//  Concertina
//
//  Created by John Forester on 6/2/24.
//

import Foundation
import AudioKit

enum BellowsDirection {
    case stable
    case pushIn
    case pullOut
}

struct ButtonViewModel: Equatable {
    static func == (lhs: ButtonViewModel, rhs: ButtonViewModel) -> Bool {
        lhs.inNote == rhs.inNote && lhs.outNote == rhs.outNote
    }
    
    var inNote: MIDINoteNumber
    var outNote: MIDINoteNumber
}

@Observable
class ConcertinaViewModel: Identifiable, Hashable, Equatable {
    static func == (lhs: ConcertinaViewModel, rhs: ConcertinaViewModel) -> Bool {
        lhs.buttonViewModels == rhs.buttonViewModels
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    var buttonViewModels: [ButtonViewModel]
    var bellowsDirection: BellowsDirection = .stable
    var activeButtons = [ButtonViewModel]()
    var id = UUID()
    
    init(buttonViewModels: [ButtonViewModel],
         bellowsDirection: BellowsDirection = .stable,
         activeButtons: [ButtonViewModel] = [ButtonViewModel]()) {
        self.buttonViewModels = buttonViewModels
        self.bellowsDirection = bellowsDirection
        self.activeButtons = activeButtons
    }
}
