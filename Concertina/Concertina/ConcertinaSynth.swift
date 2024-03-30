//
//  ConcertinaSynth.swift
//  Concertina
//
//  Created by John Forester on 3/29/24.
//

import Foundation
import AudioKit
import SoundpipeAudioKit
import Tonic

class ConcertinaSynth: ObservableObject {
    let engine = AudioEngine()
    var osc = Oscillator()
    
    func noteOn(pitch: Pitch) {
        isPlaying = true
        osc.frequency = AUValue(pitch.midiNoteNumber).midiNoteToFrequency()
    }
    
    func noteOff(pitch _: Pitch) {
        isPlaying = false
    }
    
    @Published var isPlaying: Bool = false {
        didSet { isPlaying ? osc.start() : osc.stop() }
    }
    
    init() {
        osc.amplitude = 0.2
        osc.start()
        engine.output = osc
        
        try! engine.start()
    }
}
