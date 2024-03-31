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
import DunneAudioKit
import AVFoundation
import AVFAudio
import CDunneAudioKit

class ConcertinaSynth: ObservableObject {
    let engine = AudioEngine()
    let sampler = Sampler()

    
    func noteOn(pitch: Pitch) {
        isPlaying = true
        sampler.play(noteNumber: 64, velocity: 127)

    }
    
    func noteOff(pitch _: Pitch) {
        isPlaying = false
    }
    
    @Published var isPlaying: Bool = false {
        didSet { isPlaying ? sampler.start() : sampler.stop() }
    }
    
    init() {
        var audioFile : AVAudioFile?
        do {
            if let fileURL = Bundle.main.url(forResource: "Accordian Back F C3", withExtension: "wav") {
                audioFile = try AVAudioFile(forReading: fileURL)
            }
            else {
                print("Error: could not find the accordian audio file")
            }
        }
        catch {
            print("Error loading accordian audio file: \(error)")
        }
        if let audioFile = audioFile {
            sampler.load(avAudioFile: audioFile)
            let data = SamplerData(sampleDescriptor: SampleDescriptor(noteNumber: 64, noteFrequency: 440, minimumNoteNumber: 0, maximumNoteNumber: 127, minimumVelocity: 0, maximumVelocity: 127, isLooping: false, loopStartPoint: 0, loopEndPoint: 1000.0, startPoint: 0.0, endPoint: 44100.0 * 5.0), file: audioFile)
            data.buildKeyMap()
            sampler.update(data: data)
            sampler.masterVolume = 0.2
            engine.output = sampler
            try! engine.start()
            
            sampler.play(noteNumber: 64, velocity: 127)
           
        }
    }
}
