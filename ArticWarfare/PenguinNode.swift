//
//  PenguinNode.swift
//  ArticWarfare
//
//  Created by JJ on 8/22/16.
//  Copyright © 2016 JJ. All rights reserved.
//

import UIKit
import SpriteKit

class PenguinNode: SKSpriteNode {
    //properties
    
    
    func didMoveToScene() {
        print("Penguin added to scene")
        self.name = "block"
        physicsBody?.usesPreciseCollisionDetection = true
        physicsBody!.friction = 0.2
        physicsBody!.isDynamic = true
        physicsBody!.affectedByGravity = true
        physicsBody!.categoryBitMask = PhysicsCategory.Penguin
        physicsBody!.collisionBitMask = PhysicsCategory.Edge | PhysicsCategory.WoodBlock |
            PhysicsCategory.Penguin | PhysicsCategory.StoneBlock | PhysicsCategory.Enemy
        physicsBody!.contactTestBitMask = PhysicsCategory.Penguin
    }
    
    
    func didBeginContact(_ contact: SKPhysicsContact) {
        let other = contact.bodyA.categoryBitMask == PhysicsCategory.Penguin ? contact.bodyB : contact.bodyA
        switch other.categoryBitMask {
        case PhysicsCategory.Penguin:
            print("do something here")
        default:
            break;
        }
    }
    
    func removePenguin() {
        emitParticles("BirdPoofFX", node: self)
    }
    
    func emitParticles(_ name: String, node: SKNode) {
        let pos = CGPoint(x: node.frame.size.width/2, y: node.frame.size.height/2)
        let particles = SKEmitterNode(fileNamed: name)!
        particles.position = pos
        self.addChild(particles)
        particles.run(SKAction.removeFromParentAfterDelay(1.0))
        node.run(SKAction.sequence([SKAction.scale(to: 0.0, duration: 0.5), SKAction.removeFromParent()]))
    }
}
