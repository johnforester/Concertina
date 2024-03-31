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

    
    func noteOn(note: MIDINoteNumber) {
      //  isPlaying = true
        sampler.play(noteNumber: note, velocity: 127)
    }
    
    func noteOff(note: MIDINoteNumber) {
      //  isPlaying = false
        sampler.stop(noteNumber: note)
    }
    
    @Published var isPlaying: Bool = false {
        didSet { isPlaying ? sampler.start() : sampler.stop() }
    }
        
    let wavFilesAndMIDINotes: [(audioName: String, midiNoteNumber: Int32, frequency: Float)] = [

        ("G", 67, 391.995),
        ("A", 69, 440.00),
        ("B", 71, 493.88),
        ("C", 72, 523.25),
        ("D", 74, 587.33),
        ("E", 76, 659.25),
        ("Gb", 78, 739.989),
        ("G2", 79, 783.99)
    ]
    
    func loadWAVs() {
        var filesAndSamplerData = [(sampleDescriptor: SampleDescriptor, file: AVAudioFile)]()
        
        for (audioName, midiNoteNumber, frequency) in wavFilesAndMIDINotes {
            do {
                if let fileURL = Bundle.main.url(forResource: audioName, withExtension: "wav") {
                    let audioFile = try AVAudioFile(forReading: fileURL)
                    let fileAndSamplerData =
                          (SampleDescriptor(noteNumber: midiNoteNumber, noteFrequency: frequency, minimumNoteNumber: midiNoteNumber, maximumNoteNumber: midiNoteNumber, minimumVelocity: 0, maximumVelocity: 127, isLooping: false, loopStartPoint: 9, loopEndPoint: 1000, startPoint: 0.0, endPoint: 44100.0 * 5.0), audioFile)
                    filesAndSamplerData.append(fileAndSamplerData)
                }
            } catch {
                print("problem loading file")
            }

            let sampleData = SamplerData(filesWithSampleDescriptors: filesAndSamplerData)
            sampleData.buildKeyMap()
            sampler.update(data: sampleData)
           }
    
        sampler.masterVolume = 0.2
        engine.output = sampler
        try! engine.start()
        
//        sampler.play(noteNumber: 69, velocity: 127)
    }
    
    func playTest() {
        sampler.masterVolume = 0.2
        engine.output = sampler
        try! engine.start()
        
        noteOn(note: 79)
    }

    func stopTest() {
        sampler.stop(noteNumber: 69)
    }

    init() {
        loadWAVs()
    }
}
