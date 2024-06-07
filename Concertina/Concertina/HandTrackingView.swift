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

// Filter for noise in hand positions to get cleaner/more accurate push in and pull out concertina bellow
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
    
    @Bindable var viewModel: ConcertinaViewModel
    
    @State var previousDistance: Float = 0.0
    let kalmanFilter = KalmanFilter()
    
    @State var latestHandTracking: HandsUpdates = .init(left: nil, right: nil)
    
    @State var leftConcertinaFace: Entity?
    @State var rightConcertinaFace: Entity?
    
    @State var leftLastPosition = SIMD3<Float>(0,0,0)
    @State var rightLastPosition = SIMD3<Float>(0,0,0)
    
    @State var leftIndexFingerTipModelEntity =  fingerTipEntity(false)
    @State var leftMiddleFingerTipModelEntity = fingerTipEntity(false)
    @State var leftRingFingerTipModelEntity = fingerTipEntity(false)
    @State var leftLittleFingerTipModelEntity = fingerTipEntity(false)
    @State var rightIndexFingerTipModelEntity = fingerTipEntity(false)
    @State var rightMiddleFingerTipModelEntity = fingerTipEntity(false)
    @State var rightRingFingerTipModelEntity = fingerTipEntity(false)
    @State var rightLittleFingerTipModelEntity = fingerTipEntity(false)
    
    struct HandsUpdates {
        var left: HandAnchor?
        var right: HandAnchor?
    }
    
    var body: some View {
        VStack {
            RealityView { content in
                addHandModelEntities(content)
                
                if let immersiveContentEntity = try? await Entity(named: "Immersive", in: realityKitContentBundle) {
                    content.add(immersiveContentEntity)
                    
                    if let leftEntity = immersiveContentEntity.findEntity(named: "Left_ConcertinaFace") {
                        leftConcertinaFace = leftEntity
                        leftLastPosition = leftConcertinaFace?.position ?? SIMD3<Float>(0,0,0)
                    } else {
                        print("Left face not found")
                    }
                    
                    if let rightEntity = immersiveContentEntity.findEntity(named: "Right_ConcertinaFace") {
                        rightConcertinaFace = rightEntity
                        rightLastPosition = rightConcertinaFace?.position ?? SIMD3<Float>(0,0,0)
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
                    
                    for buttonViewModel in viewModel.buttonViewModels {
                        let mesh = MeshResource.generateCylinder(height: 0.01, radius: 0.01)
                        let material = SimpleMaterial(color: .white, isMetallic: false)
                        let button = ModelEntity(mesh: mesh,
                                                 materials: [material])
                        button.generateCollisionShapes(recursive: true)
                        button.name = String(buttonViewModel.inNote)
                        content.add(button)
                        buttons.append(button)
                        
                        collisionSubscriptions.append(content.subscribe(to: CollisionEvents.Began.self, on: button) { collisionEvent in
                            // print("💥 Collision between \(collisionEvent.entityA.name) and \(collisionEvent.entityB.name)")
                            concertina.noteOn(note: buttonViewModel.inNote)
                            viewModel.activeButtons.append(buttonViewModel)
                            button.components.set(ModelComponent(mesh: mesh, materials: [HandTrackingView.emissiveMaterial()]))
                        
                        })
                        
                        collisionSubscriptions.append(content.subscribe(to: CollisionEvents.Ended.self, on: button) { collisionEvent in
                            // print("End Collision between \(collisionEvent.entityA.name) and \(collisionEvent.entityB.name) 💥")
                            concertina.noteOff(note: buttonViewModel.inNote)
                            if let index = viewModel.activeButtons.firstIndex(of: buttonViewModel) {
                                viewModel.activeButtons.remove(at: index)
                                button.components.set(ModelComponent(mesh: mesh, materials: [material]))
                            }
                        })
                    }
                    
                    
                    sceneUpdateSubscription = content.subscribe(to: SceneEvents.Update.self) { event in
                        if let leftWristModelEntity = leftConcertinaFace,
                           let rightWristModelEntity = rightConcertinaFace {
                            
                            let currentDistance = distance(leftWristModelEntity.position, rightWristModelEntity.position)
                            
                           /* if let domsSong = domsSong, domsSong.isPlaying {
                                print("Dom's song is already playing")
                            } else if currentDistance > 1.4 {
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
                            
                            let filteredDistance = kalmanFilter.update(measurement: currentDistance)
                            
                            // Determine if the distance is increasing or decreasing
                            if filteredDistance < previousDistance {
                                viewModel.bellowsDirection = .pushIn
                                //  print("Distance is getting smaller | filtered: \(filteredDistance)")
                            } else if filteredDistance > previousDistance {
                                viewModel.bellowsDirection = .pullOut
                                // print("Distance is getting bigger | filtered: \(filteredDistance)")
                            } else {
                                viewModel.bellowsDirection = .stable
                                // print("Distance is stable")
                            }
                            
                            // Update the previous filtered distance for the next iteration
                            previousDistance = filteredDistance
                        }
                    } as? any Cancellable
                }
            } update: { content in
                updateHandTracking()
            }
        }.onAppear {
            handTrackingSetup()
        }.onChange(of: viewModel.bellowsDirection) {
            for buttonModel in viewModel.activeButtons {
                if viewModel.bellowsDirection == .stable {
                    // TODO figure out better way to determing if not moving, this is not accurate enough
                    // to turn off notes reliably
                    // concertina.noteOff(note: buttonModel.inNote)
                    // concertina.noteOff(note: buttonModel.outNote)
                } else if viewModel.bellowsDirection == .pushIn {
                    concertina.noteOn(note: buttonModel.inNote)
                    concertina.noteOff(note: buttonModel.outNote)
                } else {
                    concertina.noteOff(note: buttonModel.inNote)
                    concertina.noteOn(note: buttonModel.outNote)
                }
            }
        }
    }
    
    fileprivate func addHandModelEntities(_ content: RealityViewContent) {
        content.add(leftIndexFingerTipModelEntity)
        content.add(leftMiddleFingerTipModelEntity)
        content.add(leftRingFingerTipModelEntity)
        content.add(leftLittleFingerTipModelEntity)
        content.add(rightIndexFingerTipModelEntity)
        content.add(rightMiddleFingerTipModelEntity)
        content.add(rightRingFingerTipModelEntity)
        content.add(rightLittleFingerTipModelEntity)
    }
    
    func updateSpheresPosition(startEntity: Entity, endEntity: Entity) {
        let startPosition = startEntity.position(relativeTo: nil) + SIMD3(0.1,-0.1,-0.05)
        
        let endPosition = endEntity.position(relativeTo: nil) + SIMD3(-0.1,-0.1,-0.05)
        
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
        
        if let leftWristModelEntity = leftConcertinaFace {
            // TODO optimize when scaling is done?
            leftWristModelEntity.transform = getTransform(leftHandAnchor, .wrist, leftWristModelEntity.transform)
            leftWristModelEntity.scale = SIMD3(0.007, 0.007, 0.007)
            let pos = leftWristModelEntity.position
            leftWristModelEntity.position = SIMD3(pos.x - 0.005, pos.y + 0.1, pos.z - 0.05)
            
            var y: Float = 0.0
            var z: Float = 0.0
            var row = 0
            
            let leftButtonsCount = buttons.count / 2
            let buttonsPerRow = leftButtonsCount / 2
            
            for i in 0..<leftButtonsCount {
                let button = buttons[i]
                button.transform = getTransform(leftHandAnchor, .wrist, leftWristModelEntity.transform)
                
                let pos = button.position
                button.position = SIMD3(pos.x + 0.05, pos.y + 0.12 - y, pos.z - 0.15 + z)
                
                row = row+1
                
                if row == buttonsPerRow {
                    row = 0
                    z = 0.05
                    y = 0.0
                }
                y = y + 0.03
            }
        }
        
        if let rightWristModelEntity = rightConcertinaFace {
            rightWristModelEntity.transform = getTransform(rightHandAnchor, .wrist, rightWristModelEntity.transform)
            // TODO optimize when scaling is done?
            rightWristModelEntity.scale = SIMD3(0.007, 0.007, 0.007)
            
            rightWristModelEntity.transform.rotation *= simd_quatf(angle: .pi,
                                                                   axis: SIMD3<Float>(1, 0, 0))
            
            let pos = rightWristModelEntity.position
            rightWristModelEntity.position = SIMD3(pos.x + 0.005, pos.y + 0.1, pos.z - 0.05)
            
            var y: Float = 0.0
            var z: Float = 0.0
            var row = 0
            
            let rightButtonsCount = buttons.count / 2
            let buttonsPerRow = rightButtonsCount / 2
            
            for i in rightButtonsCount..<buttons.count {
                let button = buttons[i]
                button.transform = getTransform(rightHandAnchor, .wrist, rightWristModelEntity.transform)
                
                let pos = button.position
                button.position = SIMD3(pos.x - 0.05, pos.y + 0.12 - y, pos.z - 0.15 + z)
                
                row = row+1
                
                if row == buttonsPerRow {
                    row = 0
                    // start next row
                    z = 0.05
                    y = 0.0
                }
                y = y + 0.03
            }
        }
        
        leftIndexFingerTipModelEntity.transform = getTransform(leftHandAnchor, .indexFingerTip, leftIndexFingerTipModelEntity.transform)
        leftMiddleFingerTipModelEntity.transform = getTransform(leftHandAnchor, .middleFingerTip,leftMiddleFingerTipModelEntity.transform)
        leftRingFingerTipModelEntity.transform = getTransform(leftHandAnchor, .ringFingerTip,leftRingFingerTipModelEntity.transform)
        leftLittleFingerTipModelEntity.transform = getTransform(leftHandAnchor, .littleFingerTip,leftLittleFingerTipModelEntity.transform)
        
        rightIndexFingerTipModelEntity.transform = getTransform(rightHandAnchor, .indexFingerTip,rightIndexFingerTipModelEntity.transform)
        rightMiddleFingerTipModelEntity.transform = getTransform(rightHandAnchor, .middleFingerTip,rightMiddleFingerTipModelEntity.transform)
        rightRingFingerTipModelEntity.transform = getTransform(rightHandAnchor, .ringFingerTip,rightRingFingerTipModelEntity.transform)
        rightLittleFingerTipModelEntity.transform = getTransform(rightHandAnchor, .littleFingerTip, rightLittleFingerTipModelEntity.transform)
    }
    
    func getTransform(_ anchor: HandAnchor, _ jointName: HandSkeleton.JointName, _ beforeTransform: Transform) -> Transform {
        let joint = anchor.handSkeleton?.joint(jointName)
        if ((joint?.isTracked) != nil) {
            let t = matrix_multiply(anchor.originFromAnchorTransform, (anchor.handSkeleton?.joint(jointName).anchorFromJointTransform)!)
            return Transform(matrix: t)
        }
        return beforeTransform
    }
    
    func movingAverageFilter(values: [Float], windowSize: Int) -> Float {
        let sum = values.suffix(windowSize).reduce(0, +)
        return sum / Float(windowSize)
    }
    
    static func fingerTipEntity(_ visible: Bool) -> Entity {
        if visible {
            var entity = ModelEntity(
                mesh: .generateSphere(radius: 0.01),
                materials: [SimpleMaterial(color: .cyan, isMetallic: false)])
            entity.generateCollisionShapes(recursive: true)
            return entity
        }
        
        var entity = Entity()
        entity.components.set(CollisionComponent(shapes: [.generateSphere(radius: 0.01)], isStatic: false))
        return entity
    }
    
    static func emissiveMaterial() -> PhysicallyBasedMaterial {
        var emissiveMaterial = PhysicallyBasedMaterial()
        emissiveMaterial.emissiveIntensity = 1.0
        emissiveMaterial.emissiveColor = .init(color: .green)
        return emissiveMaterial
    }
}
