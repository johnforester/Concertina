//
//  ConcertinaApp.swift
//  Concertina
//
//  Created by John Forester on 3/29/24.
//

import SwiftUI

@main
struct ConcertinaApp: App {
    @State var viewModel = ConcertinaViewModel(buttonViewModels:
                                            [ButtonViewModel(inNote: 80, outNote: 82), // G# | Bb
                                             ButtonViewModel(inNote: 81, outNote: 79), // A | G
                                             ButtonViewModel(inNote: 73, outNote: 75), // C# | Eb
                                             ButtonViewModel(inNote: 57, outNote: 58), // A | Bb
                                             ButtonViewModel(inNote: 64, outNote: 65), // E | F
                                             
                                             ButtonViewModel(inNote: 79, outNote: 81), // G | A
                                             ButtonViewModel(inNote: 76, outNote: 77), // E | F
                                             ButtonViewModel(inNote: 61, outNote: 63), // C | D
                                             ButtonViewModel(inNote: 55, outNote: 59), // G | B
                                             ButtonViewModel(inNote: 60, outNote: 55), // C | G
                                             
                                             ButtonViewModel(inNote: 72, outNote: 71), // C | B
                                             ButtonViewModel(inNote: 64, outNote: 62), // E | D
                                             ButtonViewModel(inNote: 67, outNote: 65), // G | F
                                             ButtonViewModel(inNote: 60, outNote: 58), // C | A
                                             ButtonViewModel(inNote: 64, outNote: 59), // E || B
                                             
                                             ButtonViewModel(inNote: 73, outNote: 75), // C# | Eb
                                             ButtonViewModel(inNote: 69, outNote: 67), // A | G
                                             ButtonViewModel(inNote: 68, outNote: 70), // G# | Bb
                                             ButtonViewModel(inNote: 61, outNote: 63), // C# | Eb
                                             ButtonViewModel(inNote: 57, outNote: 53)]) // A | F)
    
    var body: some Scene {
        WindowGroup(id: "ContentView") {
            ContentView()
        }

        ImmersiveSpace(id: "ImmersiveSpace") {
            HandTrackingView(viewModel: viewModel)
        }
        
        WindowGroup(id: "ButtonView") {
            ConcertinaButtonsView(viewModel: viewModel)
        }
    }
}
