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

struct HandTrackingView: View {
    @StateObject var concertina = ConcertinaSynth()
    
    @State var sceneUpdateSubscription : Cancellable? = nil
    let session = ARKitSession()
    var handTrackingProvider = HandTrackingProvider()
    
    @State var spheres: [Entity] = []
    let totalSpheres = 10
    
    @State var latestHandTracking: HandsUpdates = .init(left: nil, right: nil)
    
    @State var leftWristModelEntity: Entity?
    @State var rightWristModelEntity: Entity?
    
    @State var leftLastPosition = SIMD3<Float>(0,0,0)
    @State var rightLastPosition = SIMD3<Float>(0,0,0)
    
    @State var leftThumbKnuckleModelEntity = ModelEntity(
        mesh: .generateSphere(radius: 0.015),
        materials: [SimpleMaterial(color: .white, isMetallic: true)])
    @State var leftThumbIntermediateBaseModelEntity = ModelEntity(
        mesh: .generateSphere(radius: 0.015),
        materials: [SimpleMaterial(color: .white, isMetallic: true)])
    @State var leftThumbIntermediateTipModelEntity = ModelEntity(
        mesh: .generateSphere(radius: 0.015),
        materials: [SimpleMaterial(color: .white, isMetallic: true)])
    @State var leftThumbTipModelEntity = ModelEntity(
        mesh: .generateSphere(radius: 0.015),
        materials: [SimpleMaterial(color: .white, isMetallic: true)])
    @State var leftIndexFingerMetacarpalModelEntity = ModelEntity(
        mesh: .generateSphere(radius: 0.015),
        materials: [SimpleMaterial(color: .white, isMetallic: true)])
    @State var leftIndexFingerKnuckleModelEntity = ModelEntity(
        mesh: .generateSphere(radius: 0.015),
        materials: [SimpleMaterial(color: .white, isMetallic: true)])
    @State var leftIndexFingerIntermediateBaseModelEntity = ModelEntity(
        mesh: .generateSphere(radius: 0.015),
        materials: [SimpleMaterial(color: .white, isMetallic: true)])
    @State var leftIndexFingerIntermediateTipModelEntity = ModelEntity(
        mesh: .generateSphere(radius: 0.015),
        materials: [SimpleMaterial(color: .white, isMetallic: true)])
    @State var leftIndexFingerTipModelEntity = ModelEntity(
        mesh: .generateSphere(radius: 0.015),
        materials: [SimpleMaterial(color: .white, isMetallic: true)])
    @State var leftMiddleFingerMetacarpalModelEntity = ModelEntity(
        mesh: .generateSphere(radius: 0.015),
        materials: [SimpleMaterial(color: .white, isMetallic: true)])
    @State var leftMiddleFingerKnuckleModelEntity = ModelEntity(
        mesh: .generateSphere(radius: 0.015),
        materials: [SimpleMaterial(color: .white, isMetallic: true)])
    @State var leftMiddleFingerIntermediateBaseModelEntity = ModelEntity(
        mesh: .generateSphere(radius: 0.015),
        materials: [SimpleMaterial(color: .white, isMetallic: true)])
    @State var leftMiddleFingerIntermediateTipModelEntity = ModelEntity(
        mesh: .generateSphere(radius: 0.015),
        materials: [SimpleMaterial(color: .white, isMetallic: true)])
    @State var leftMiddleFingerTipModelEntity = ModelEntity(
        mesh: .generateSphere(radius: 0.015),
        materials: [SimpleMaterial(color: .white, isMetallic: true)])
    @State var leftRingFingerMetacarpalModelEntity = ModelEntity(
        mesh: .generateSphere(radius: 0.015),
        materials: [SimpleMaterial(color: .white, isMetallic: true)])
    @State var leftRingFingerKnuckleModelEntity = ModelEntity(
        mesh: .generateSphere(radius: 0.015),
        materials: [SimpleMaterial(color: .white, isMetallic: true)])
    @State var leftRingFingerIntermediateBaseModelEntity = ModelEntity(
        mesh: .generateSphere(radius: 0.015),
        materials: [SimpleMaterial(color: .white, isMetallic: true)])
    @State var leftRingFingerIntermediateTipModelEntity = ModelEntity(
        mesh: .generateSphere(radius: 0.015),
        materials: [SimpleMaterial(color: .white, isMetallic: true)])
    @State var leftRingFingerTipModelEntity = ModelEntity(
        mesh: .generateSphere(radius: 0.015),
        materials: [SimpleMaterial(color: .white, isMetallic: true)])
    @State var leftLittleFingerMetacarpalModelEntity = ModelEntity(
        mesh: .generateSphere(radius: 0.015),
        materials: [SimpleMaterial(color: .white, isMetallic: true)])
    @State var leftLittleFingerKnuckleModelEntity = ModelEntity(
        mesh: .generateSphere(radius: 0.015),
        materials: [SimpleMaterial(color: .white, isMetallic: true)])
    @State var leftLittleFingerIntermediateBaseModelEntity = ModelEntity(
        mesh: .generateSphere(radius: 0.015),
        materials: [SimpleMaterial(color: .white, isMetallic: true)])
    @State var leftLittleFingerIntermediateTipModelEntity = ModelEntity(
        mesh: .generateSphere(radius: 0.015),
        materials: [SimpleMaterial(color: .white, isMetallic: true)])
    @State var leftLittleFingerTipModelEntity = ModelEntity(
        mesh: .generateSphere(radius: 0.015),
        materials: [SimpleMaterial(color: .white, isMetallic: true)])
    @State var leftForearmWristModelEntity = ModelEntity(
        mesh: .generateSphere(radius: 0.015),
        materials: [SimpleMaterial(color: .white, isMetallic: true)])
    @State var leftForearmArmModelEntity = ModelEntity(
        mesh: .generateBox(width: 0.5, height: 0.1, depth: 0.15),
        materials: [SimpleMaterial(color: .white, isMetallic: true)])
    
    @State var rightThumbKnuckleModelEntity = ModelEntity(
        mesh: .generateSphere(radius: 0.015),
        materials: [SimpleMaterial(color: .white, isMetallic: true)])
    @State var rightThumbIntermediateBaseModelEntity = ModelEntity(
        mesh: .generateSphere(radius: 0.015),
        materials: [SimpleMaterial(color: .white, isMetallic: true)])
    @State var rightThumbIntermediateTipModelEntity = ModelEntity(
        mesh: .generateSphere(radius: 0.015),
        materials: [SimpleMaterial(color: .white, isMetallic: true)])
    @State var rightThumbTipModelEntity = ModelEntity(
        mesh: .generateSphere(radius: 0.015),
        materials: [SimpleMaterial(color: .white, isMetallic: true)])
    @State var rightIndexFingerMetacarpalModelEntity = ModelEntity(
        mesh: .generateSphere(radius: 0.015),
        materials: [SimpleMaterial(color: .white, isMetallic: true)])
    @State var rightIndexFingerKnuckleModelEntity = ModelEntity(
        mesh: .generateSphere(radius: 0.015),
        materials: [SimpleMaterial(color: .white, isMetallic: true)])
    @State var rightIndexFingerIntermediateBaseModelEntity = ModelEntity(
        mesh: .generateSphere(radius: 0.015),
        materials: [SimpleMaterial(color: .white, isMetallic: true)])
    @State var rightIndexFingerIntermediateTipModelEntity = ModelEntity(
        mesh: .generateSphere(radius: 0.015),
        materials: [SimpleMaterial(color: .white, isMetallic: true)])
    @State var rightIndexFingerTipModelEntity = ModelEntity(
        mesh: .generateSphere(radius: 0.015),
        materials: [SimpleMaterial(color: .white, isMetallic: true)])
    @State var rightMiddleFingerMetacarpalModelEntity = ModelEntity(
        mesh: .generateSphere(radius: 0.015),
        materials: [SimpleMaterial(color: .white, isMetallic: true)])
    @State var rightMiddleFingerKnuckleModelEntity = ModelEntity(
        mesh: .generateSphere(radius: 0.015),
        materials: [SimpleMaterial(color: .white, isMetallic: true)])
    @State var rightMiddleFingerIntermediateBaseModelEntity = ModelEntity(
        mesh: .generateSphere(radius: 0.015),
        materials: [SimpleMaterial(color: .white, isMetallic: true)])
    @State var rightMiddleFingerIntermediateTipModelEntity = ModelEntity(
        mesh: .generateSphere(radius: 0.015),
        materials: [SimpleMaterial(color: .white, isMetallic: true)])
    @State var rightMiddleFingerTipModelEntity = ModelEntity(
        mesh: .generateSphere(radius: 0.015),
        materials: [SimpleMaterial(color: .white, isMetallic: true)])
    @State var rightRingFingerMetacarpalModelEntity = ModelEntity(
        mesh: .generateSphere(radius: 0.015),
        materials: [SimpleMaterial(color: .white, isMetallic: true)])
    @State var rightRingFingerKnuckleModelEntity = ModelEntity(
        mesh: .generateSphere(radius: 0.015),
        materials: [SimpleMaterial(color: .white, isMetallic: true)])
    @State var rightRingFingerIntermediateBaseModelEntity = ModelEntity(
        mesh: .generateSphere(radius: 0.015),
        materials: [SimpleMaterial(color: .white, isMetallic: true)])
    @State var rightRingFingerIntermediateTipModelEntity = ModelEntity(
        mesh: .generateSphere(radius: 0.015),
        materials: [SimpleMaterial(color: .white, isMetallic: true)])
    @State var rightRingFingerTipModelEntity = ModelEntity(
        mesh: .generateSphere(radius: 0.015),
        materials: [SimpleMaterial(color: .white, isMetallic: true)])
    @State var rightLittleFingerMetacarpalModelEntity = ModelEntity(
        mesh: .generateSphere(radius: 0.015),
        materials: [SimpleMaterial(color: .white, isMetallic: true)])
    @State var rightLittleFingerKnuckleModelEntity = ModelEntity(
        mesh: .generateSphere(radius: 0.015),
        materials: [SimpleMaterial(color: .white, isMetallic: true)])
    @State var rightLittleFingerIntermediateBaseModelEntity = ModelEntity(
        mesh: .generateSphere(radius: 0.015),
        materials: [SimpleMaterial(color: .white, isMetallic: true)])
    @State var rightLittleFingerIntermediateTipModelEntity = ModelEntity(
        mesh: .generateSphere(radius: 0.015),
        materials: [SimpleMaterial(color: .white, isMetallic: true)])
    @State var rightLittleFingerTipModelEntity = ModelEntity(
        mesh: .generateSphere(radius: 0.015),
        materials: [SimpleMaterial(color: .white, isMetallic: true)])
    @State var rightForearmWristModelEntity = ModelEntity(
        mesh: .generateSphere(radius: 0.015),
        materials: [SimpleMaterial(color: .white, isMetallic: true)])
    @State var rightForearmArmModelEntity = ModelEntity(
        mesh: .generateBox(width: 0.5, height: 0.1, depth: 0.15),
        materials: [SimpleMaterial(color: .white, isMetallic: true)])
    
    @State var fingerStatuses = [FingerStatus]()
    
    struct FingerStatus {
        var tip: Entity
        var knuckle: Entity
        var isPlaying: Bool
        var note: MIDINoteNumber
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
                         note: 69),
            FingerStatus(tip: leftMiddleFingerTipModelEntity,
                         knuckle: leftMiddleFingerKnuckleModelEntity,
                         isPlaying: false,
                         note: 71)
            
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
                addHandModelEntities(content)
                if let immersiveContentEntity = try? await Entity(named: "Immersive", in: realityKitContentBundle) {
                    content.add(immersiveContentEntity)
                    
                  //  concertina.noteOn(note: 60) // TEST NOTE
                    
                    if let leftEntity = immersiveContentEntity.findEntity(named: "Left_ConcertinaFace") {
                        leftWristModelEntity = leftEntity
                        leftWristModelEntity?.components.set(PhysicsMotionComponent())
                        leftLastPosition = leftWristModelEntity?.position ?? SIMD3<Float>(0,0,0)
                    } else {
                        print("Left face not found")
                    }
                    
                    if let rightEntity = immersiveContentEntity.findEntity(named: "Right_ConcertinaFace") {
                        rightWristModelEntity = rightEntity
                        rightWristModelEntity?.components.set(PhysicsMotionComponent())
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
                    
                    sceneUpdateSubscription = content.subscribe(to: SceneEvents.Update.self) {event in
                        
                        
                        if let leftWristModelEntity = leftWristModelEntity,
                           let rightWristModelEntity = rightWristModelEntity {
                            /*  if areEntitiesMovingTowardsEachOther(entity1: leftWristModelEntity, entity2: rightWristModelEntity, deltaTime: event.deltaTime) {*/
                            //  if !concertina.isPlaying {
                            //  concertina.noteOn(note: 64)
                            
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
            if distance(fingerStatuses[i].tip.position, fingerStatuses[i].knuckle.position) < 0.05 {
                if !fingerStatuses[i].isPlaying {
                    concertina.noteOn(note: fingerStatuses[i].note)
                    fingerStatuses[i].isPlaying = true
                } else {
                    // continue playing note
                }
            } else if fingerStatuses[i].isPlaying == true {
                concertina.noteOff(note: fingerStatuses[i].note)
                fingerStatuses[i].isPlaying = false
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
