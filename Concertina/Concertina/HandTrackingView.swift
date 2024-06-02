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
    @State var leftMiddleFingerTipModelEntity = Entity()
    @State var leftRingFingerMetacarpalModelEntity = Entity()
    @State var leftRingFingerKnuckleModelEntity = Entity()
    @State var leftRingFingerIntermediateBaseModelEntity = Entity()
    @State var leftRingFingerIntermediateTipModelEntity = Entity()
    @State var leftRingFingerTipModelEntity = Entity()
    @State var leftLittleFingerMetacarpalModelEntity = Entity()
    @State var leftLittleFingerKnuckleModelEntity = Entity()
    @State var leftLittleFingerIntermediateBaseModelEntity = Entity()
    @State var leftLittleFingerIntermediateTipModelEntity = Entity()
    @State var leftLittleFingerTipModelEntity = Entity()
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
    @State var rightIndexFingerTipModelEntity = Entity()
    @State var rightMiddleFingerMetacarpalModelEntity = Entity()
    @State var rightMiddleFingerKnuckleModelEntity = Entity()
    @State var rightMiddleFingerIntermediateBaseModelEntity = Entity()
    @State var rightMiddleFingerIntermediateTipModelEntity = Entity()
    @State var rightMiddleFingerTipModelEntity = Entity()
    @State var rightRingFingerMetacarpalModelEntity = Entity()
    @State var rightRingFingerKnuckleModelEntity = Entity()
    @State var rightRingFingerIntermediateBaseModelEntity = Entity()
    @State var rightRingFingerIntermediateTipModelEntity = Entity()
    @State var rightRingFingerTipModelEntity = Entity()
    @State var rightLittleFingerMetacarpalModelEntity = Entity()
    @State var rightLittleFingerKnuckleModelEntity = Entity()
    @State var rightLittleFingerIntermediateBaseModelEntity = Entity()
    @State var rightLittleFingerIntermediateTipModelEntity = Entity()
    @State var rightLittleFingerTipModelEntity = Entity()
    @State var rightForearmWristModelEntity = Entity()
    @State var rightForearmArmModelEntity = Entity()
    
    @State var fingerStatuses = [FingerStatus]()
    
    struct FingerStatus {
        var tip: Entity
        var knuckle: Entity
        var isPlaying: Bool
        var note: MIDINoteNumber
        var distanceToTrigger: Float
    }
    
    struct HandsUpdates {
        var left: HandAnchor?
        var right: HandAnchor?
    }
    
    fileprivate func addHandModelEntities(_ content: RealityViewContent) {
        fingerStatuses = [
            FingerStatus(tip: leftIndexFingerTipModelEntity,
                         knuckle: leftIndexFingerKnuckleModelEntity,
                         isPlaying: false,
                         note: 67,
                         distanceToTrigger: 0.05),
            FingerStatus(tip: leftMiddleFingerTipModelEntity,
                         knuckle: leftMiddleFingerKnuckleModelEntity,
                         isPlaying: false,
                         note: 69,
                         distanceToTrigger: 0.05),
            FingerStatus(tip: leftRingFingerTipModelEntity,
                         knuckle: leftRingFingerKnuckleModelEntity,
                         isPlaying: false,
                         note: 71,
                         distanceToTrigger: 0.07),
            FingerStatus(tip: leftLittleFingerTipModelEntity,
                         knuckle: leftForearmWristModelEntity,
                         isPlaying: false,
                         note: 72,
                         distanceToTrigger: 0.07),
            FingerStatus(tip: rightIndexFingerTipModelEntity,
                         knuckle: rightIndexFingerKnuckleModelEntity,
                         isPlaying: false,
                         note: 74,
                         distanceToTrigger: 0.05),
            FingerStatus(tip: rightMiddleFingerTipModelEntity,
                         knuckle: rightMiddleFingerKnuckleModelEntity,
                         isPlaying: false,
                         note: 76,
                         distanceToTrigger: 0.05),
            FingerStatus(tip: rightRingFingerTipModelEntity,
                         knuckle: rightRingFingerKnuckleModelEntity,
                         isPlaying: false,
                         note: 78,
                         distanceToTrigger: 0.07),
            FingerStatus(tip: rightLittleFingerTipModelEntity,
                         knuckle: rightForearmWristModelEntity,
                         isPlaying: false,
                         note: 79,
                         distanceToTrigger: 0.07)
            
        ]
        // content.add(leftWristModelEntity)
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
            Text("Hand Tracking.")
            RealityView { content in
                
                leftIndexFingerTipModelEntity.generateCollisionShapes(recursive: true)
                
                addHandModelEntities(content)
                
                if let immersiveContentEntity = try? await Entity(named: "Immersive", in: realityKitContentBundle) {
                    content.add(immersiveContentEntity)
                    
                  //  concertina.noteOn(note: 60) // TEST NOTE
                    
                   if let leftEntity = immersiveContentEntity.findEntity(named: "Left_ConcertinaFace") {
                        leftWristModelEntity = leftEntity
                       // leftWristModelEntity?.components.set(PhysicsMotionComponent())
                        leftLastPosition = leftWristModelEntity?.position ?? SIMD3<Float>(0,0,0)
                    } else {
                        print("Left face not found")
                    }
                    
                    if let rightEntity = immersiveContentEntity.findEntity(named: "Right_ConcertinaFace") {
                        rightWristModelEntity = rightEntity
                       // rightWristModelEntity?.components.set(PhysicsMotionComponent())
                        rightLastPosition = rightWristModelEntity?.position ?? SIMD3<Float>(0,0,0)
                    } else {
                        print("Right face not found")
                    }
                    
                    for _ in 0..<totalSpheres {
                        let mesh = MeshResource.generateSphere(radius: 0.05)
                        let material = SimpleMaterial(color: .darkGray, isMetallic: false)
                        let sphere = ModelEntity(mesh: mesh, materials: [material])
                        //sphere.components.set(CollisionComponent)
                        content.add(sphere)
                        spheres.append(sphere)
                    }
                    
                    //collisionSubscriptions.removeAll()
                    
                    for _ in 0..<4 {
                        let mesh = MeshResource.generateBox(width: 0.01, height: 0.01, depth: 0.01)
                        let material = SimpleMaterial(color: .blue, isMetallic: false)
                        let button = ModelEntity(mesh: mesh,
                                                 materials: [material])
                        button.generateCollisionShapes(recursive: true)
                        content.add(button)
                        buttons.append(button)
                        
                        collisionSubscriptions.append(content.subscribe(to: CollisionEvents.Began.self, on: button) { collisionEvent in
                            print("💥 Collision between \(collisionEvent.entityA.name) and \(collisionEvent.entityB.name)")
                        })
                    }
                    
                    
                    sceneUpdateSubscription = content.subscribe(to: SceneEvents.Update.self) {event in
                        if let leftWristModelEntity = leftWristModelEntity,
                           let rightWristModelEntity = rightWristModelEntity {
                            /*  if areEntitiesMovingTowardsEachOther(entity1: leftWristModelEntity, entity2: rightWristModelEntity, deltaTime: event.deltaTime) {*/
                            //  if !concertina.isPlaying {
                            //  concertina.noteOn(note: 64)
                            
                            let distance = distance(leftWristModelEntity.position, rightWristModelEntity.position)
                            
                            if distance > 1.1 {
                                // Easter egg
                                let path = Bundle.main.path(forResource: "Nearer_My_God_to_Thee_reverb_room", ofType:"m4a")!
                                let url = URL(fileURLWithPath: path)

//                                do {
//                                    domsSong = try AVAudioPlayer(contentsOf: url)
//                                    domsSong?.play()
//                                } catch {
//                                    print("couldn't load Dom's song")
//                                }
                            }
                            
                            updateFingerPositions()
                            
                            //   }
                            /*print("YES MOVING TOWARDS") } else {
                             // print("NOT MOVING TOWARDS")
                             // concertina.isPlaying = false
                             //  }*/
                            
                            updateSpheresPosition(startEntity: leftWristModelEntity, endEntity: rightWristModelEntity)
                            leftLastPosition = leftWristModelEntity.position
                            rightLastPosition = rightWristModelEntity.position
                        }
                    } as? any Cancellable
                    /*
                     let currentTime = Date().timeIntervalSinceReferenceDate
                     
                     // Calculate deltaTime as the difference between the current time and the last update time
                     let deltaTime = currentTime - lastUpdateTime
                     
                     // Update the lastUpdateTime for the next frame
                     lastUpdateTime = deltaTime
                     
                     print(lastUpdateTime)
                     */
                }
                concertina.isPlaying = true
            } update: { content in
                computeTransformHeartTracking()
            }
        }.onAppear {
            handTracking()
        }
    }
    
    func updateFingerPositions() {
        for i in 0..<fingerStatuses.count {
            
//            if fingerStatuses[i].tip == leftLittleFingerTipModelEntity {
//                print("little distance: \(distance(fingerStatuses[i].tip.position, fingerStatuses[i].knuckle.position))")
//            }
//            
         /*   if distance(fingerStatuses[i].tip.position, fingerStatuses[i].knuckle.position) < fingerStatuses[i].distanceToTrigger {
                if !fingerStatuses[i].isPlaying {
                    concertina.noteOn(note: fingerStatuses[i].note)
                    fingerStatuses[i].isPlaying = true
                } else {
                    // continue playing note
                }
            } else if fingerStatuses[i].isPlaying == true {
                concertina.noteOff(note: fingerStatuses[i].note)
                fingerStatuses[i].isPlaying = false
            }*/
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
    
    func areEntitiesMovingTowardsEachOther(entity1: Entity,
                                           entity2: Entity,
                                           deltaTime: TimeInterval) -> Bool {
        
        // Calculate displacement vectors
        let displacement1 = entity1.position - leftLastPosition;
        let displacement2 = entity2.position - rightLastPosition;
        
        //  print(displacement1)
        
        // Check if the displacement vectors are in opposite directions
        return (simd_dot(normalize(displacement1), normalize(displacement2)) < 0)
    }
    
    func handTracking() {
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
    
    func computeTransformHeartTracking() {
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
            for button in buttons {
                button.transform = getTransform(leftHandAnchor, .wrist, leftWristModelEntity.transform)
                //leftWristModelEntity.scale = SIMD3(0.01, 0.01, 0.01)
                
                let pos = button.position
                button.position = SIMD3(pos.x + 0.1, pos.y + 0.1 - y, pos.z - 0.1)
                y = y + 0.02
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
}
