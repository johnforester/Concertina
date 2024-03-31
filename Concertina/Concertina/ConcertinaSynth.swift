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
    var sf2URL: URL?

    
    func noteOn(pitch: MIDINoteNumber) {
        sampler.play(noteNumber: pitch, velocity: 127)
        isPlaying = true
    }
    
    func noteOff(pitch : MIDINoteNumber) {
        sampler.stop(noteNumber: pitch)
        isPlaying = false
    }
    
    @Published var isPlaying: Bool = false {
        didSet { isPlaying ? sampler.start() : sampler.stop() }
    }
    
    func loadSF2() {
        guard let sf2URL = Bundle.main.url(forResource: "Concertina", withExtension: "sf2") else {
            print("Failed to find the SF2 file in the bundle.")
            return
        }
        self.sf2URL = sf2URL
        sampler.loadSFZ(url: sf2URL)
    }
        
    let wavFilesAndMIDINotes: [(audioName: String, midiNoteNumber: Int32, frequency: Float)] = [
        ("A", 69, 440.00),
        ("B", 71, 493.88),
        ("C", 72, 523.25),
        ("D", 74, 587.33),
        ("E", 76, 659.25),
//        ("F", 77, 698.46),
        ("G", 79, 783.99)
    ]
    
    func loadWAVs() {
        var filesAndSamplerData = [(sampleDescriptor: SampleDescriptor, file: AVAudioFile)]()
        
        for (audioName, midiNoteNumber, frequency) in wavFilesAndMIDINotes {
            do {
                if let fileURL = Bundle.main.url(forResource: audioName, withExtension: "wav") {
                    let audioFile = try AVAudioFile(forReading: fileURL)
                    let fileAndSamplerData =
                          (SampleDescriptor(noteNumber: midiNoteNumber, noteFrequency: frequency, minimumNoteNumber: midiNoteNumber, maximumNoteNumber: midiNoteNumber, minimumVelocity: 0, maximumVelocity: 127, isLooping: false, loopStartPoint: 0, loopEndPoint: 1000.0, startPoint: 0.0, endPoint: 44100.0 * 5.0), audioFile)
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
    
    func playTestSF2() {
        guard let sf2URL = sf2URL else {
            print("SF2 URL is nil, cannot create SamplerData.")
            return
        }
        
        let data = SamplerData(sfzURL: sf2URL)
        data.buildKeyMap()
        sampler.update(data: data)
        sampler.masterVolume = 0.2
        engine.output = sampler
        try! engine.start()

        sampler.play(noteNumber: 79, velocity: 127)
    }
    
    func playTest() {
        sampler.masterVolume = 0.2
        engine.output = sampler
        try! engine.start()
        
        noteOn(pitch: 79)
    }

    func stopTest() {
        sampler.stop(noteNumber: 69)
    }

    init() {
        loadWAVs()
    }
}
