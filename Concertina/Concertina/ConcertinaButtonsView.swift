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
    
    var body: some View {
        HStack(spacing: 50) {
            let numberOfButtonsPerSide = 5
            // Left hand buttons
            VStack {
                ForEach(0..<numberOfButtonsPerSide, id: \.self) { index in
                    Circle()
                        .fill(viewModel.activeButtons.contains(viewModel.buttonViewModels[index]) ? Color.red : Color.gray)
                        .frame(width: 30, height: 30)
                        .padding(4)
                }
            }
            
            // Right hand buttons
            VStack {
                ForEach(0..<numberOfButtonsPerSide, id: \.self) { index in
                    Circle()
                        .fill(viewModel.activeButtons.contains(viewModel.buttonViewModels[index]) ? Color.red : Color.gray)
                        .frame(width: 30, height: 30)
                        .padding(4)
                }
            }
        }
        .frame(width: 300, height: 400)
                .background(Color.white)
                .cornerRadius(12)
                .shadow(radius: 5)
    }
}
