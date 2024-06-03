//
//  ConcertinaButtonsView.swift
//  Concertina
//
//  Created by Thomas Corcos on 31/03/2024.
//

import SwiftUI
import Foundation

struct ConcertinaButtonsView: View {
    @Bindable var viewModel: ConcertinaViewModel
    
    fileprivate func buttonView(_ inText: String, _ outText: String, _ inOn: Bool, _ outOn: Bool) -> some View {
        return VStack {
            Text(inText)
                .foregroundColor(.black)
            Divider()
            Text(outText)
                .foregroundColor(.black)
        } .frame(width: 50, height: 60)
            .background(
                ZStack {
                    Capsule(style: .circular)
                        .trim(from: 0, to: 1)
                        .fill(.gray)
                        .frame(width: 60, height: 80)
                    Capsule(style: .circular)
                        .trim(from: inOn ? 0.5 : 0, to: inOn ? 1.0 : 0.0)
                        .fill(.green)
                        .frame(width: 60, height: 80)
                    Capsule(style: .circular)
                        .trim(from: outOn ? 0 : 0, to: outOn ? 0.5 : 0.0)
                        .fill(.green)
                        .frame(width: 60, height: 80)
                }
            )
            .padding(.vertical)
    }
    
    fileprivate func buttonView(_ index: Int) -> some View {
        return buttonView(midiNoteToString(midiNote: Int(viewModel.buttonViewModels[index].inNote)) ?? "none",
                          midiNoteToString(midiNote: Int(viewModel.buttonViewModels[index].outNote)) ?? "none",
                          viewModel.activeButtons.contains(viewModel.buttonViewModels[index]) && viewModel.bellowsDirection == .pushIn,
                          viewModel.activeButtons.contains(viewModel.buttonViewModels[index]) && viewModel.bellowsDirection == .pullOut)
    }
    
    let numberOfButtonsPerSide = 5
    
    var body: some View {
        HStack(spacing: 50) {
            Spacer()
            VStack {
                Spacer()
                buttonView("In", "Out", viewModel.bellowsDirection == .pushIn, viewModel.bellowsDirection == .pullOut)
                    .padding(.vertical)
            }
            
            // Left hand buttons
            HStack {
                VStack {
                    ForEach(0..<numberOfButtonsPerSide, id: \.self) { index in
                        buttonView(index)
                    }
                }
                .padding(.horizontal)
                VStack {
                    ForEach(numberOfButtonsPerSide..<numberOfButtonsPerSide*2, id: \.self) { index in
                        buttonView(index)
                    }
                }
            }
            
            Spacer()
            
            // Right hand buttons
            HStack {
                VStack {
                    ForEach(numberOfButtonsPerSide*2..<numberOfButtonsPerSide*3, id: \.self) { index in
                        buttonView(index)
                    }
                }
                .padding(.horizontal)
                VStack {
                    ForEach(numberOfButtonsPerSide*3..<numberOfButtonsPerSide*4, id: \.self) { index in
                        buttonView(index)
                    }
                }
            }
            Spacer()
        }
        .frame(width: 600, height: 600)
        .glassBackgroundEffect()
        .cornerRadius(12)
        .shadow(radius: 5)
    }
    
    func midiNoteToString(midiNote: Int) -> String? {
        guard midiNote >= 0 && midiNote <= 127 else { return nil }
        
        let noteLetters = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]
        let note = midiNote % 12
        let octave = (midiNote / 12) - 1
        
        return "\(noteLetters[note])\(octave)"
    }
}
