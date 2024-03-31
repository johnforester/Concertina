//
//  MessageView.swift
//  Concertina
//
//  Created by Thomas Corcos on 31/03/2024.
//

import Foundation

struct FloatingMessageView: View {
    var body: some View {
        VStack {
            Text("Welcome to the Concertina Simulator!\n Try closing one finger at a time and then move your hands towards each other.")
                .multilineTextAlignment(.center)
                .padding()
                .frame(width: 200)
            
            Button("Got It!") {
                withAnimation {
                    isShowing = false
                }
            }
            .padding()
        }
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 5)
    }
}
