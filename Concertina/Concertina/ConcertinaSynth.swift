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
    
    func loadSingleWAV(audioName: String, midiNoteNumber: Int32, frequency: Float) {
        var audioFile : AVAudioFile?
        do {
            if let fileURL = Bundle.main.url(forResource: audioName, withExtension: "wav") {
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
            let data = SamplerData(sampleDescriptor: SampleDescriptor(noteNumber: midiNoteNumber, noteFrequency: frequency, minimumNoteNumber: midiNoteNumber, maximumNoteNumber: midiNoteNumber, minimumVelocity: 0, maximumVelocity: 127, isLooping: false, loopStartPoint: 0, loopEndPoint: 1000.0, startPoint: 0.0, endPoint: 44100.0 * 5.0), file: audioFile)
//            data.buildSimpleKeyMap()
            sampler.update(data: data)
            sampler.masterVolume = 0.2
            engine.output = sampler
//            try! engine.start()
//            
//            sampler.play(noteNumber: UInt8(midiNoteNumber), velocity: 127)
//            
//            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
//                    // Stop the note
//                    self.sampler.stop(noteNumber: UInt8(midiNoteNumber))
//                }
        }
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
    
    func loadWAVsSequentially(index: Int = 0) {
        guard index < wavFilesAndMIDINotes.count else { return } // Exit condition

        let (audioName, midiNoteNumber, frequency) = wavFilesAndMIDINotes[index]

        // Load the current WAV file
        loadSingleWAV(audioName: audioName, midiNoteNumber: midiNoteNumber, frequency: frequency)

        // Schedule the next call with a delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            // Call the function recursively with the next index
            self.loadWAVsSequentially(index: index + 1)
        }
        
        sampler.masterVolume = 0.2
        engine.output = sampler
        try! engine.start()

    }


    
    func loadWAVs() {
        for (audioName, midiNoteNumber, frequency) in wavFilesAndMIDINotes {
            loadSingleWAV(audioName: audioName, midiNoteNumber: midiNoteNumber, frequency: frequency)
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
