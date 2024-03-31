//
//  ImmersiveView.swift
//  Concertina
//
//  Created by John Forester on 3/29/24.
//

import SwiftUI
import RealityKit
import RealityKitContent
import Tonic


// TODO maybe delete this

struct ImmersiveView: View {
    @Environment(\.dismissWindow) private var dismissWindow

    @StateObject var concertina = ConcertinaSynth()

    var body: some View {
        RealityView { content in
            // Add the initial RealityKit content
            if let immersiveContentEntity = try? await Entity(named: "Immersive", in: realityKitContentBundle) {
                content.add(immersiveContentEntity)              

                concertina.noteOn(pitch: 60)
                
                
            }
        }
        .onAppear() {
            dismissWindow(id: "ContentView")
        }
    }
}

#Preview(immersionStyle: .full) {
    ImmersiveView()
}
