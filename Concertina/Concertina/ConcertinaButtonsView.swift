//
//  ConcertinaButtonsView.swift
//  Concertina
//
//  Created by Thomas Corcos on 31/03/2024.
//

import SwiftUI
import Foundation

struct ConcertinaButtonsView: View {
    @State private var offset = CGSize.zero
    @Binding var fingerStatuses: [FingerStatus]
    
    var body: some View {
        HStack(spacing: 50) {
            let numberOfButtonsPerSide = 4
            // Left hand buttons
            VStack {
                ForEach(0..<numberOfButtonsPerSide, id: \.self) { index in
                    Circle()
                        .fill(fingerStatuses[index].isPlaying ? Color.red : Color.gray)
                        .frame(width: 30, height: 30)
                        .padding(4)
                }
            }
            
            // Right hand buttons
            VStack {
                ForEach(0..<numberOfButtonsPerSide, id: \.self) { index in
                    Circle()
                        .fill(fingerStatuses[index].isPlaying ? Color.red : Color.gray)
                        .frame(width: 30, height: 30)
                        .padding(4)
                }
            }
        }
        .frame(width: 300, height: 400)
                .background(Color.white)
                .cornerRadius(12)
                .shadow(radius: 5)
                .offset(offset)
                .gesture(
                    DragGesture()
                        .onChanged { gesture in
                            self.offset = gesture.translation
                        }
//                        .onEnded { _ in
//                            // Optionally, you can reset the offset here to stop the window from moving
//                            // self.offset = .zero
//                        }
                )

    }
}
