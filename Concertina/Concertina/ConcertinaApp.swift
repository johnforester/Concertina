//
//  ConcertinaApp.swift
//  Concertina
//
//  Created by John Forester on 3/29/24.
//

import SwiftUI

@main
struct ConcertinaApp: App {
    var body: some Scene {
        WindowGroup(id: "ContentView") {
            ContentView()
        }

        ImmersiveSpace(id: "ImmersiveSpace") {
            HandTrackingView()
        }
    }
}
