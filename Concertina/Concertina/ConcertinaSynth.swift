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
        sampler.play(noteNumber: note, velocity: 127)
    }
    
    func noteOff(note: MIDINoteNumber) {
        sampler.stop(noteNumber: note)
    }
    
    @Published var isPlaying: Bool = false {
        didSet { isPlaying ? sampler.start() : sampler.stop() }
    }
        
    let wavFilesAndMIDINotes: [(audioName: String, midiNoteNumber: Int32, frequency: Float)] = [

        ("F", 53, 174.61),
        ("Gb", 54, 185.00),
        ("G", 55, 196),
        ("A", 56, 207.65), // Ab
        ("A", 57, 220.0),
        ("A", 58, 233.08), // Bb
        ("B", 59, 246.94),
        ("C", 60, 261.63),
        ("C", 61, 277.18), // Db
        ("D", 62, 293.66),
        ("D", 63, 311.13), // Eb
        ("E", 64, 329.63),
        ("Gb", 65, 349.23), // F
        ("Gb", 66, 369.99),
        ("G", 67, 391.995),
        ("G", 68, 415.3), // Ab
        ("A", 69, 440.00),
        ("A", 70, 466.16), // Bb
        ("B", 71, 493.88),
        ("C", 72, 523.25),
        ("C", 73, 554.37), // Db
        ("D", 74, 587.33),
        ("D", 75, 622.25), // Eb
        ("E", 76, 659.25),
        ("E", 77, 698.46), // F
        ("Gb", 78, 739.989),
        ("G2", 79, 783.99),
        ("G2", 80, 830.61), // Ab
        ("A", 81, 880),
        ("A", 82, 932.23) // Bb
    ]
    
    func loadWAVs() {
        var filesAndSamplerData = [(sampleDescriptor: SampleDescriptor, file: AVAudioFile)]()
        
        for (audioName, midiNoteNumber, frequency) in wavFilesAndMIDINotes {
            do {
                if let fileURL = Bundle.main.url(forResource: audioName, withExtension: "wav") {
                    let audioFile = try AVAudioFile(forReading: fileURL)
                    
                    let fileAndSamplerData =
                    (SampleDescriptor(noteNumber: midiNoteNumber, noteFrequency: frequency, minimumNoteNumber: midiNoteNumber, maximumNoteNumber: midiNoteNumber, minimumVelocity: 0, maximumVelocity: 127, isLooping: false, loopStartPoint: 9, loopEndPoint: 1000, startPoint: 0.0, endPoint: 44100.0 * 1.0), audioFile)
                    filesAndSamplerData.append(fileAndSamplerData)
                }
            } catch {
                print("problem loading file")
            }
        }
        
        let sampleData = SamplerData(filesWithSampleDescriptors: filesAndSamplerData)
        sampleData.buildKeyMap()
                    
        sampler.update(data: sampleData)
        
        sampler.masterVolume = 0.5
        engine.output = sampler
        try! engine.start()
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
