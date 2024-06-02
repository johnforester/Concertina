//
//  HandTrackingView.swift
//  Concertina
//
//  Created by John Forester on 3/30/24.
//

import SwiftUI
import RealityKit
import ARKit
import RealityKitContent
import Tonic
import Combine
import AudioKit
import AVFAudio

class KalmanFilter {
    var Q: Float = 0.0001  // Process noise covariance
    var R: Float = 0.1     // Measurement noise covariance
    var x: Float = 0.0     // Value
    var P: Float = 1.0     // Estimation error covariance
    var K: Float = 0.0     // Kalman gain

    func update(measurement: Float) -> Float {
        // Prediction update
        P = P + Q

        // Measurement update
        K = P / (P + R)
        x = x + K * (measurement - x)
        P = (1 - K) * P

        return x
    }
}

enum BellowsDirection {
    case stable
    case pushIn
    case pullOut
}

struct HandTrackingView: View {
    @StateObject var concertina = ConcertinaSynth()
    
    @State private var sceneUpdateSubscription : Cancellable? = nil
    @State private var collisionSubscriptions = [EventSubscription]()

    let session = ARKitSession()
    var handTrackingProvider = HandTrackingProvider()
    @State var domsSong: AVAudioPlayer?

    @State var spheres: [Entity] = []
    let totalSpheres = 10
    
    @State var buttons: [Entity] = []
    @State var buttonViewModels: [ButtonViewModel]
    @State var activeButtons = [ButtonViewModel]()
    
    @State var previousDistance: Float = 0.0
    @State var bellowsDirection = BellowsDirection.stable
    let kalmanFilter = KalmanFilter()
    
    @State var latestHandTracking: HandsUpdates = .init(left: nil, right: nil)
    
    @State var leftWristModelEntity: Entity?
    @State var rightWristModelEntity: Entity?
    
    @State var leftLastPosition = SIMD3<Float>(0,0,0)
    @State var rightLastPosition = SIMD3<Float>(0,0,0)
    
    @State var leftThumbKnuckleModelEntity = Entity()
    @State var leftThumbIntermediateBaseModelEntity = Entity()
    @State var leftThumbIntermediateTipModelEntity = Entity()
    @State var leftThumbTipModelEntity = Entity()
    @State var leftIndexFingerMetacarpalModelEntity = Entity()
    @State var leftIndexFingerKnuckleModelEntity = Entity()
    @State var leftIndexFingerIntermediateBaseModelEntity = Entity()
    @State var leftIndexFingerIntermediateTipModelEntity = Entity()
    @State var leftIndexFingerTipModelEntity = ModelEntity(
        mesh: .generateSphere(radius: 0.01),
        materials: [SimpleMaterial(color: .cyan, isMetallic: false)]
      )
    @State var leftMiddleFingerMetacarpalModelEntity = Entity()
    @State var leftMiddleFingerKnuckleModelEntity = Entity()
    @State var leftMiddleFingerIntermediateBaseModelEntity = Entity()
    @State var leftMiddleFingerIntermediateTipModelEntity = Entity()
    @State var leftMiddleFingerTipModelEntity = ModelEntity(
        mesh: .generateSphere(radius: 0.01),
        materials: [SimpleMaterial(color: .cyan, isMetallic: false)]
      )
    @State var leftRingFingerMetacarpalModelEntity = Entity()
    @State var leftRingFingerKnuckleModelEntity = Entity()
    @State var leftRingFingerIntermediateBaseModelEntity = Entity()
    @State var leftRingFingerIntermediateTipModelEntity = Entity()
    @State var leftRingFingerTipModelEntity = ModelEntity(
        mesh: .generateSphere(radius: 0.01),
        materials: [SimpleMaterial(color: .cyan, isMetallic: false)]
      )
    @State var leftLittleFingerMetacarpalModelEntity = Entity()
    @State var leftLittleFingerKnuckleModelEntity = Entity()
    @State var leftLittleFingerIntermediateBaseModelEntity = Entity()
    @State var leftLittleFingerIntermediateTipModelEntity = Entity()
    @State var leftLittleFingerTipModelEntity = ModelEntity(
        mesh: .generateSphere(radius: 0.01),
        materials: [SimpleMaterial(color: .cyan, isMetallic: false)]
      )
    @State var leftForearmWristModelEntity = Entity()
    @State var leftForearmArmModelEntity = Entity()
    
    @State var rightThumbKnuckleModelEntity = Entity()
    @State var rightThumbIntermediateBaseModelEntity = Entity()
    @State var rightThumbIntermediateTipModelEntity = Entity()
    @State var rightThumbTipModelEntity = Entity()
    @State var rightIndexFingerMetacarpalModelEntity = Entity()
    @State var rightIndexFingerKnuckleModelEntity = Entity()
    @State var rightIndexFingerIntermediateBaseModelEntity = Entity()
    @State var rightIndexFingerIntermediateTipModelEntity = Entity()
    @State var rightIndexFingerTipModelEntity = ModelEntity(
        mesh: .generateSphere(radius: 0.01),
        materials: [SimpleMaterial(color: .cyan, isMetallic: false)]
      )
    @State var rightMiddleFingerMetacarpalModelEntity = Entity()
    @State var rightMiddleFingerKnuckleModelEntity = Entity()
    @State var rightMiddleFingerIntermediateBaseModelEntity = Entity()
    @State var rightMiddleFingerIntermediateTipModelEntity = Entity()
    @State var rightMiddleFingerTipModelEntity = ModelEntity(
        mesh: .generateSphere(radius: 0.01),
        materials: [SimpleMaterial(color: .cyan, isMetallic: false)]
      )
    @State var rightRingFingerMetacarpalModelEntity = Entity()
    @State var rightRingFingerKnuckleModelEntity = Entity()
    @State var rightRingFingerIntermediateBaseModelEntity = Entity()
    @State var rightRingFingerIntermediateTipModelEntity = Entity()
    @State var rightRingFingerTipModelEntity = ModelEntity(
        mesh: .generateSphere(radius: 0.01),
        materials: [SimpleMaterial(color: .cyan, isMetallic: false)]
      )
    @State var rightLittleFingerMetacarpalModelEntity = Entity()
    @State var rightLittleFingerKnuckleModelEntity = Entity()
    @State var rightLittleFingerIntermediateBaseModelEntity = Entity()
    @State var rightLittleFingerIntermediateTipModelEntity = Entity()
    @State var rightLittleFingerTipModelEntity = ModelEntity(
        mesh: .generateSphere(radius: 0.01),
        materials: [SimpleMaterial(color: .cyan, isMetallic: false)]
      )
    @State var rightForearmWristModelEntity = Entity()
    @State var rightForearmArmModelEntity = Entity()
    
    struct ButtonSideModel {
        var rowModels = [ButtonRowModel]()
    }
    
    struct ButtonRowModel {
        var buttonViewModels = [ButtonViewModel]()
    }
    
    struct ButtonViewModel: Equatable {
        var inNote: MIDINoteNumber
        var outNote: MIDINoteNumber
    }
    
    struct HandsUpdates {
        var left: HandAnchor?
        var right: HandAnchor?
    }

    fileprivate func addHandModelEntities(_ content: RealityViewContent) {
        buttonViewModels =  [
            ButtonViewModel(inNote: 80, outNote: 82), // G# | Bb
            ButtonViewModel(inNote: 81, outNote: 79), // A | G
            ButtonViewModel(inNote: 73, outNote: 75), // C# | Eb
            ButtonViewModel(inNote: 57, outNote: 58), // A | Bb
            ButtonViewModel(inNote: 64, outNote: 65), // E | F
            
            ButtonViewModel(inNote: 79, outNote: 81), // G | A
            ButtonViewModel(inNote: 76, outNote: 77), // E | F
            ButtonViewModel(inNote: 61, outNote: 63), // C | D
            ButtonViewModel(inNote: 55, outNote: 59), // G | B
            ButtonViewModel(inNote: 60, outNote: 55), // C | G
            
            ButtonViewModel(inNote: 72, outNote: 71), // C | B
            ButtonViewModel(inNote: 64, outNote: 62), // E | D
            ButtonViewModel(inNote: 67, outNote: 65), // G | F
            ButtonViewModel(inNote: 60, outNote: 58), // C | A
            ButtonViewModel(inNote: 64, outNote: 59), // E || B
            
            ButtonViewModel(inNote: 73, outNote: 75), // C# | Eb
            ButtonViewModel(inNote: 69, outNote: 67), // A | G
            ButtonViewModel(inNote: 68, outNote: 70), // G# | Bb
            ButtonViewModel(inNote: 61, outNote: 63), // C# | Eb
            ButtonViewModel(inNote: 57, outNote: 53)] // A | F
        
        content.add(leftThumbKnuckleModelEntity)
        content.add(leftThumbIntermediateBaseModelEntity)
        content.add(leftThumbIntermediateTipModelEntity)
        content.add(leftThumbTipModelEntity)
        content.add(leftIndexFingerMetacarpalModelEntity)
        content.add(leftIndexFingerKnuckleModelEntity)
        content.add(leftIndexFingerIntermediateBaseModelEntity)
        content.add(leftIndexFingerIntermediateTipModelEntity)
        content.add(leftIndexFingerTipModelEntity)
        content.add(leftMiddleFingerMetacarpalModelEntity)
        content.add(leftMiddleFingerKnuckleModelEntity)
        content.add(leftMiddleFingerIntermediateBaseModelEntity)
        content.add(leftMiddleFingerIntermediateTipModelEntity)
        content.add(leftMiddleFingerTipModelEntity)
        content.add(leftRingFingerMetacarpalModelEntity)
        content.add(leftRingFingerKnuckleModelEntity)
        content.add(leftRingFingerIntermediateBaseModelEntity)
        content.add(leftRingFingerIntermediateTipModelEntity)
        content.add(leftRingFingerTipModelEntity)
        content.add(leftLittleFingerMetacarpalModelEntity)
        content.add(leftLittleFingerKnuckleModelEntity)
        content.add(leftLittleFingerIntermediateBaseModelEntity)
        content.add(leftLittleFingerIntermediateTipModelEntity)
        content.add(leftLittleFingerTipModelEntity)
        content.add(leftForearmWristModelEntity)
        content.add(leftForearmArmModelEntity)
        
        content.add(rightThumbKnuckleModelEntity)
        content.add(rightThumbIntermediateBaseModelEntity)
        content.add(rightThumbIntermediateTipModelEntity)
        content.add(rightThumbTipModelEntity)
        content.add(rightIndexFingerMetacarpalModelEntity)
        content.add(rightIndexFingerKnuckleModelEntity)
        content.add(rightIndexFingerIntermediateBaseModelEntity)
        content.add(rightIndexFingerIntermediateTipModelEntity)
        content.add(rightIndexFingerTipModelEntity)
        content.add(rightMiddleFingerMetacarpalModelEntity)
        content.add(rightMiddleFingerKnuckleModelEntity)
        content.add(rightMiddleFingerIntermediateBaseModelEntity)
        content.add(rightMiddleFingerIntermediateTipModelEntity)
        content.add(rightMiddleFingerTipModelEntity)
        content.add(rightRingFingerMetacarpalModelEntity)
        content.add(rightRingFingerKnuckleModelEntity)
        content.add(rightRingFingerIntermediateBaseModelEntity)
        content.add(rightRingFingerIntermediateTipModelEntity)
        content.add(rightRingFingerTipModelEntity)
        content.add(rightLittleFingerMetacarpalModelEntity)
        content.add(rightLittleFingerKnuckleModelEntity)
        content.add(rightLittleFingerIntermediateBaseModelEntity)
        content.add(rightLittleFingerIntermediateTipModelEntity)
        content.add(rightLittleFingerTipModelEntity)
        content.add(rightForearmWristModelEntity)
        content.add(rightForearmArmModelEntity)
    }
    
    var body: some View {
        VStack {
            RealityView { content in
                addHandModelEntities(content)
                
                leftIndexFingerTipModelEntity.generateCollisionShapes(recursive: true)
                leftMiddleFingerTipModelEntity.generateCollisionShapes(recursive: true)
                leftRingFingerTipModelEntity.generateCollisionShapes(recursive: true)
                leftLittleFingerTipModelEntity.generateCollisionShapes(recursive: true)
                rightIndexFingerTipModelEntity.generateCollisionShapes(recursive: true)
                rightMiddleFingerTipModelEntity.generateCollisionShapes(recursive: true)
                rightRingFingerTipModelEntity.generateCollisionShapes(recursive: true)
                rightLittleFingerTipModelEntity.generateCollisionShapes(recursive: true)
                
                if let immersiveContentEntity = try? await Entity(named: "Immersive", in: realityKitContentBundle) {
                    content.add(immersiveContentEntity)
                                        
                   if let leftEntity = immersiveContentEntity.findEntity(named: "Left_ConcertinaFace") {
                        leftWristModelEntity = leftEntity
                        leftLastPosition = leftWristModelEntity?.position ?? SIMD3<Float>(0,0,0)
                    } else {
                        print("Left face not found")
                    }
                    
                    if let rightEntity = immersiveContentEntity.findEntity(named: "Right_ConcertinaFace") {
                        rightWristModelEntity = rightEntity
                        rightLastPosition = rightWristModelEntity?.position ?? SIMD3<Float>(0,0,0)
                    } else {
                        print("Right face not found")
                    }
                    
                    for _ in 0..<totalSpheres {
                        let mesh = MeshResource.generateSphere(radius: 0.05)
                        let material = SimpleMaterial(color: .darkGray, isMetallic: false)
                        let sphere = ModelEntity(mesh: mesh, materials: [material])
                        content.add(sphere)
                        spheres.append(sphere)
                    }
                    
                    collisionSubscriptions.removeAll()
                    
                    for buttonViewModel in buttonViewModels {
                        let mesh = MeshResource.generateCylinder(height: 0.01, radius: 0.01)
                        let material = SimpleMaterial(color: .white, isMetallic: false)
                        let button = ModelEntity(mesh: mesh,
                                                 materials: [material])
                        button.generateCollisionShapes(recursive: true)
                        button.name = String(buttonViewModel.inNote)
                        content.add(button)
                        buttons.append(button)
                        
                        collisionSubscriptions.append(content.subscribe(to: CollisionEvents.Began.self, on: button) { collisionEvent in
                            print("💥 Collision between \(collisionEvent.entityA.name) and \(collisionEvent.entityB.name)")
                            concertina.noteOn(note: buttonViewModel.inNote)
                            activeButtons.append(buttonViewModel)
                        })
                        
                        collisionSubscriptions.append(content.subscribe(to: CollisionEvents.Ended.self, on: button) { collisionEvent in
                            print("End Collision between \(collisionEvent.entityA.name) and \(collisionEvent.entityB.name) 💥")
                            concertina.noteOff(note: buttonViewModel.inNote)
                            if let index = activeButtons.firstIndex(of: buttonViewModel) {
                                activeButtons.remove(at: index)
                            }
                        })
                    }
                    
                    
                    sceneUpdateSubscription = content.subscribe(to: SceneEvents.Update.self) { event in
                        if let leftWristModelEntity = leftWristModelEntity,
                           let rightWristModelEntity = rightWristModelEntity {
                            
                            let currentDistance = distance(leftWristModelEntity.position, rightWristModelEntity.position)
                            
                           /* if currentDistance > 1.4 {
                                // Easter egg
                                let path = Bundle.main.path(forResource: "Nearer_My_God_to_Thee_reverb_room", ofType:"m4a")!
                                let url = URL(fileURLWithPath: path)

                                do {
                                    domsSong = try AVAudioPlayer(contentsOf: url)
                                    domsSong?.play()
                                } catch {
                                    print("couldn't load Dom's song")
                                }
                            }*/
                                                        
                            updateSpheresPosition(startEntity: leftWristModelEntity, endEntity: rightWristModelEntity)
                            leftLastPosition = leftWristModelEntity.position
                            rightLastPosition = rightWristModelEntity.position
                            
                            print("current distance: \(currentDistance)")

                            let filteredDistance = kalmanFilter.update(measurement: currentDistance)
                            
                               // Determine if the distance is increasing or decreasing
                               if filteredDistance < previousDistance {
                                   bellowsDirection = .pushIn
                                   print("Distance is getting smaller | filtered: \(filteredDistance)")
                               } else if filteredDistance > previousDistance {
                                   bellowsDirection = .pullOut
                                   print("Distance is getting bigger | filtered: \(filteredDistance)")
                               } else {
                                   bellowsDirection = .stable
                                   print("Distance is stable")
                               }

                               // Update the previous filtered distance for the next iteration
                               previousDistance = filteredDistance
                        }
                    } as? any Cancellable
                }
                concertina.isPlaying = true
            } update: { content in
                updateHandTracking()
            }
        }.onAppear {
            handTrackingSetup()
        }.onChange(of: bellowsDirection) {
            for buttonModel in activeButtons {
                if bellowsDirection == .stable {
                   // concertina.noteOff(note: buttonModel.inNote)
                   // concertina.noteOff(note: buttonModel.outNote)
                } else if bellowsDirection == .pushIn {
                    concertina.noteOn(note: buttonModel.inNote)
                    concertina.noteOff(note: buttonModel.outNote)
                } else {
                    concertina.noteOff(note: buttonModel.inNote)
                    concertina.noteOn(note: buttonModel.outNote)
                }
            }
        }
    }
    
    func updateSpheresPosition(startEntity: Entity, endEntity: Entity) {
        let startPosition = startEntity.position(relativeTo: nil) + SIMD3(0.2,-0.1,-0.05)
        
        let endPosition = endEntity.position(relativeTo: nil) + SIMD3(-0.2,-0.1,-0.05)
        
        let vector = endPosition - startPosition
        let segmentLength = vector / Float(totalSpheres - 1)
        
        for (index, sphere) in spheres.enumerated() {
            let newPosition = startPosition + segmentLength * Float(index)
            sphere.position = newPosition
        }
    }
    
    func handTrackingSetup() {
        if HandTrackingProvider.isSupported {
            Task {
                try await session.run([handTrackingProvider])
                for await update in handTrackingProvider.anchorUpdates {
                    switch update.event {
                    case .updated:
                        let anchor = update.anchor
                        guard anchor.isTracked else { continue }
                        
                        if anchor.chirality == .left {
                            latestHandTracking.left = anchor
                            
                        } else if anchor.chirality == .right {
                            latestHandTracking.right = anchor
                        }
                    default:
                        break
                    }
                }
            }
        }
    }
    
    func updateHandTracking() {
        guard let leftHandAnchor = latestHandTracking.left,
              let rightHandAnchor = latestHandTracking.right,
              leftHandAnchor.isTracked, rightHandAnchor.isTracked else {
            return
        }
        
        if let leftWristModelEntity = leftWristModelEntity {
            // TODO optimize when scaling is done?
            leftWristModelEntity.transform = getTransform(leftHandAnchor, .wrist, leftWristModelEntity.transform)
            leftWristModelEntity.scale = SIMD3(0.01, 0.01, 0.01)
            let pos = leftWristModelEntity.position
            leftWristModelEntity.position = SIMD3(pos.x - 0.1, pos.y + 0.1, pos.z - 0.05)
            
            var y: Float = 0.0
            var z: Float = 0.0
            
            let leftButtonsCount = buttons.count / 2
            let buttonsPerRow = leftButtonsCount / 2
            
            for i in 0..<leftButtonsCount {
                let button = buttons[i]
                button.transform = getTransform(leftHandAnchor, .wrist, leftWristModelEntity.transform)
                
                let pos = button.position
                button.position = SIMD3(pos.x + 0.05, pos.y + 0.12 - y, pos.z - 0.12 + z)
                
                if i == buttonsPerRow-1 {
                    // start next row
                    z = 0.05
                    y = 0.0
                }
                y = y + 0.03
            }
        }
        
        if let rightWristModelEntity = rightWristModelEntity {
            rightWristModelEntity.transform = getTransform(rightHandAnchor, .wrist, rightWristModelEntity.transform)
            // TODO optimize when scaling is done?
            rightWristModelEntity.scale = SIMD3(0.01, 0.01, 0.01)
            
            rightWristModelEntity.transform.rotation *= simd_quatf(angle: .pi,
                                                                   axis: SIMD3<Float>(1, 0, 0))
            
            let pos = rightWristModelEntity.position
            rightWristModelEntity.position = SIMD3(pos.x + 0.1, pos.y + 0.1, pos.z - 0.05)
        }
        
        leftThumbKnuckleModelEntity.transform = getTransform(leftHandAnchor, .thumbKnuckle, leftThumbKnuckleModelEntity.transform)
        leftThumbIntermediateBaseModelEntity.transform = getTransform(leftHandAnchor, .thumbIntermediateBase, leftThumbIntermediateBaseModelEntity.transform)
        leftThumbIntermediateTipModelEntity.transform = getTransform(leftHandAnchor, .thumbIntermediateTip, leftThumbIntermediateTipModelEntity.transform)
        leftThumbTipModelEntity.transform = getTransform(leftHandAnchor, .thumbTip, leftThumbTipModelEntity.transform)
        leftIndexFingerMetacarpalModelEntity.transform = getTransform(leftHandAnchor, .indexFingerMetacarpal, leftIndexFingerMetacarpalModelEntity.transform)
        leftIndexFingerKnuckleModelEntity.transform = getTransform(leftHandAnchor, .indexFingerKnuckle, leftMiddleFingerKnuckleModelEntity.transform)
        leftIndexFingerIntermediateBaseModelEntity.transform = getTransform(leftHandAnchor, .indexFingerIntermediateBase, leftIndexFingerIntermediateBaseModelEntity.transform)
        leftIndexFingerIntermediateTipModelEntity.transform = getTransform(leftHandAnchor, .indexFingerIntermediateTip, leftIndexFingerIntermediateTipModelEntity.transform)
        
        // print("left index: \(leftIndexFingerTipModelEntity.position.z)")
        
        leftIndexFingerTipModelEntity.transform = getTransform(leftHandAnchor, .indexFingerTip, leftIndexFingerTipModelEntity.transform)
        leftMiddleFingerMetacarpalModelEntity.transform = getTransform(leftHandAnchor, .middleFingerMetacarpal, leftMiddleFingerMetacarpalModelEntity.transform)
        leftMiddleFingerKnuckleModelEntity.transform = getTransform(leftHandAnchor, .middleFingerKnuckle,leftMiddleFingerKnuckleModelEntity.transform)
        leftMiddleFingerIntermediateBaseModelEntity.transform = getTransform(leftHandAnchor, .middleFingerIntermediateBase,leftMiddleFingerIntermediateBaseModelEntity.transform)
        leftMiddleFingerIntermediateTipModelEntity.transform = getTransform(leftHandAnchor, .middleFingerIntermediateTip,leftMiddleFingerIntermediateTipModelEntity.transform)
        leftMiddleFingerTipModelEntity.transform = getTransform(leftHandAnchor, .middleFingerTip,leftMiddleFingerTipModelEntity.transform)
        leftRingFingerMetacarpalModelEntity.transform = getTransform(leftHandAnchor, .ringFingerMetacarpal,leftRingFingerMetacarpalModelEntity.transform)
        leftRingFingerKnuckleModelEntity.transform = getTransform(leftHandAnchor, .ringFingerKnuckle,leftRingFingerKnuckleModelEntity.transform)
        leftRingFingerIntermediateBaseModelEntity.transform = getTransform(leftHandAnchor, .ringFingerIntermediateBase,leftRingFingerIntermediateBaseModelEntity.transform)
        leftRingFingerIntermediateTipModelEntity.transform = getTransform(leftHandAnchor, .ringFingerIntermediateTip,leftRingFingerIntermediateTipModelEntity.transform)
        leftRingFingerTipModelEntity.transform = getTransform(leftHandAnchor, .ringFingerTip,leftRingFingerTipModelEntity.transform)
        leftLittleFingerMetacarpalModelEntity.transform = getTransform(leftHandAnchor, .littleFingerMetacarpal,leftLittleFingerMetacarpalModelEntity.transform)
        leftLittleFingerKnuckleModelEntity.transform = getTransform(leftHandAnchor, .littleFingerKnuckle,leftLittleFingerKnuckleModelEntity.transform)
        leftLittleFingerIntermediateBaseModelEntity.transform = getTransform(leftHandAnchor, .littleFingerIntermediateBase, leftLittleFingerIntermediateBaseModelEntity.transform)
        leftLittleFingerIntermediateTipModelEntity.transform = getTransform(leftHandAnchor, .littleFingerIntermediateTip,leftLittleFingerIntermediateTipModelEntity.transform)
        leftLittleFingerTipModelEntity.transform = getTransform(leftHandAnchor, .littleFingerTip,leftLittleFingerTipModelEntity.transform)
        leftForearmWristModelEntity.transform = getTransform(leftHandAnchor, .forearmWrist,leftForearmWristModelEntity.transform)
        leftForearmArmModelEntity.transform = getTransform(leftHandAnchor, .forearmArm,leftForearmArmModelEntity.transform)
        
        rightThumbKnuckleModelEntity.transform = getTransform(rightHandAnchor, .thumbKnuckle,rightThumbKnuckleModelEntity.transform)
        rightThumbIntermediateBaseModelEntity.transform = getTransform(rightHandAnchor, .thumbIntermediateBase,rightThumbIntermediateBaseModelEntity.transform)
        rightThumbIntermediateTipModelEntity.transform = getTransform(rightHandAnchor, .thumbIntermediateTip,rightThumbIntermediateTipModelEntity.transform)
        rightThumbTipModelEntity.transform = getTransform(rightHandAnchor, .thumbTip,rightThumbTipModelEntity.transform)
        rightIndexFingerMetacarpalModelEntity.transform = getTransform(rightHandAnchor, .indexFingerMetacarpal,rightIndexFingerMetacarpalModelEntity.transform)
        rightIndexFingerKnuckleModelEntity.transform = getTransform(rightHandAnchor, .indexFingerKnuckle,rightIndexFingerKnuckleModelEntity.transform)
        rightIndexFingerIntermediateBaseModelEntity.transform = getTransform(rightHandAnchor, .indexFingerIntermediateBase,rightIndexFingerIntermediateBaseModelEntity.transform)
        rightIndexFingerIntermediateTipModelEntity.transform = getTransform(rightHandAnchor, .indexFingerIntermediateTip,rightIndexFingerIntermediateTipModelEntity.transform)
        rightIndexFingerTipModelEntity.transform = getTransform(rightHandAnchor, .indexFingerTip,rightIndexFingerTipModelEntity.transform)
        rightMiddleFingerMetacarpalModelEntity.transform = getTransform(rightHandAnchor, .middleFingerMetacarpal,rightMiddleFingerMetacarpalModelEntity.transform)
        rightMiddleFingerKnuckleModelEntity.transform = getTransform(rightHandAnchor, .middleFingerKnuckle,rightMiddleFingerKnuckleModelEntity.transform)
        rightMiddleFingerIntermediateBaseModelEntity.transform = getTransform(rightHandAnchor, .middleFingerIntermediateBase,rightMiddleFingerIntermediateBaseModelEntity.transform)
        rightMiddleFingerIntermediateTipModelEntity.transform = getTransform(rightHandAnchor, .middleFingerIntermediateTip, rightMiddleFingerIntermediateTipModelEntity.transform)
        rightMiddleFingerTipModelEntity.transform = getTransform(rightHandAnchor, .middleFingerTip,rightMiddleFingerTipModelEntity.transform)
        rightRingFingerMetacarpalModelEntity.transform = getTransform(rightHandAnchor, .ringFingerMetacarpal,rightRingFingerMetacarpalModelEntity.transform)
        rightRingFingerKnuckleModelEntity.transform = getTransform(rightHandAnchor, .ringFingerKnuckle,rightRingFingerKnuckleModelEntity.transform)
        rightRingFingerIntermediateBaseModelEntity.transform = getTransform(rightHandAnchor, .ringFingerIntermediateBase,rightRingFingerIntermediateBaseModelEntity.transform)
        rightRingFingerIntermediateTipModelEntity.transform = getTransform(rightHandAnchor, .ringFingerIntermediateTip, rightRingFingerIntermediateTipModelEntity.transform)
        rightRingFingerTipModelEntity.transform = getTransform(rightHandAnchor, .ringFingerTip,rightRingFingerTipModelEntity.transform)
        rightLittleFingerMetacarpalModelEntity.transform = getTransform(rightHandAnchor, .littleFingerMetacarpal,rightLittleFingerMetacarpalModelEntity.transform)
        rightLittleFingerKnuckleModelEntity.transform = getTransform(rightHandAnchor, .littleFingerKnuckle, rightLittleFingerKnuckleModelEntity.transform)
        rightLittleFingerIntermediateBaseModelEntity.transform = getTransform(rightHandAnchor, .littleFingerIntermediateBase, rightLittleFingerIntermediateBaseModelEntity.transform)
        rightLittleFingerIntermediateTipModelEntity.transform = getTransform(rightHandAnchor, .littleFingerIntermediateTip, rightLittleFingerIntermediateTipModelEntity.transform)
        rightLittleFingerTipModelEntity.transform = getTransform(rightHandAnchor, .littleFingerTip, rightLittleFingerTipModelEntity.transform)
        rightForearmWristModelEntity.transform = getTransform(rightHandAnchor, .forearmWrist, rightForearmWristModelEntity.transform)
        rightForearmArmModelEntity.transform = getTransform(rightHandAnchor, .forearmArm, rightForearmArmModelEntity.transform)
    }
    
    func getTransform(_ anchor: HandAnchor, _ jointName: HandSkeleton.JointName, _ beforeTransform: Transform) -> Transform {
        let joint = anchor.handSkeleton?.joint(jointName)
        if ((joint?.isTracked) != nil) {
            let t = matrix_multiply(anchor.originFromAnchorTransform, (anchor.handSkeleton?.joint(jointName).anchorFromJointTransform)!)
            return Transform(matrix: t)
        }
        return beforeTransform
    }
    
//    func lowPassFilter(currentValue: Float, previousValue: Float, alpha: Float) -> Float {
//        return alpha * currentValue + (1 - alpha) * previousValue
//    }
    func movingAverageFilter(values: [Float], windowSize: Int) -> Float {
        let sum = values.suffix(windowSize).reduce(0, +)
        return sum / Float(windowSize)
    }
}
