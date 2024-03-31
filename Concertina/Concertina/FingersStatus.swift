//
//  FingersStatus.swift
//  Concertina
//
//  Created by Thomas Corcos on 31/03/2024.
//

import Foundation
import RealityKit
import AudioKit

struct FingerStatus {
    var tip: Entity
    var knuckle: Entity
    var isPlaying: Bool
    var note: MIDINoteNumber
}
