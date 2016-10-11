//
//  WoodBlockNode.swift
//  ArticWarfare
//
//  Created by JJ on 8/4/16.
//  Copyright © 2016 JJ. All rights reserved.
//

import SpriteKit

class WoodBlockNode: SKSpriteNode, CustomNodeEvents {
    
    var health: Int = 0
    let brokenAnim = SKEmitterNode(fileNamed: "BrokenStoneFX")!
    
    func didMoveToScene() {
        self.name = "block"
        physicsBody!.friction = 0.3
        physicsBody!.isDynamic = true
        physicsBody!.affectedByGravity = true
        physicsBody!.categoryBitMask = PhysicsCategory.WoodBlock
        physicsBody!.collisionBitMask = PhysicsCategory.Edge | PhysicsCategory.StoneBlock |
            PhysicsCategory.Penguin | PhysicsCategory.WoodBlock | PhysicsCategory.Enemy
        physicsBody!.contactTestBitMask = PhysicsCategory.WoodBlock
        self.health = Int(self.physicsBody!.mass * 100) //placeholder for health
    }
    
    func contactWithPenguin(_ contactImpulse: CGFloat) {
        guard let gameScene = self.scene as? GameScene else {
            fatalError("This node does not belong to a GameScene")
        }
        self.health -= Int(contactImpulse/2)
        gameScene.score += 10
        if(self.health <= 0) {
            gameScene.score += 50
            breakBlock()
        }
    }
    
    func contactWithBlock(_ contactImpulse: CGFloat) {
        guard let gameScene = self.scene as? GameScene else {
            fatalError("This node does not belong to a GameScene")
        }
        self.health -= Int(contactImpulse/2)
        gameScene.score += 5
        if(self.health <= 0) {
            gameScene.score += 100
            breakBlock()
        }
    }
    
    func breakBlock() {
        guard let gameScene = self.scene as? GameScene else {
            fatalError("This node does not belong to a GameScene")
        }
        run(gameScene.woodCrack)
        gameScene.emitParticles("BrokenWoodFX", node: self, remove: false)
        gameScene.emitParticles("50.sks", node: self, remove: true)
    }
}
