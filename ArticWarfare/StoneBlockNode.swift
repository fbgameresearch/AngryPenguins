//
//  StoneBlockNode.swift
//  ArticWarfare
//
//  Created by JJ on 8/4/16.
//  Copyright © 2016 JJ. All rights reserved.
//

import SpriteKit

class StoneBlockNode: SKSpriteNode, CustomNodeEvents {
    //properties
    var health: Int = 0
    
    
    func didMoveToScene() {
        self.name = "block"
        physicsBody!.friction = 0.4
        physicsBody!.isDynamic = true
        physicsBody!.affectedByGravity = true
        physicsBody!.categoryBitMask = PhysicsCategory.StoneBlock
        physicsBody!.collisionBitMask = PhysicsCategory.Edge | PhysicsCategory.WoodBlock |
            PhysicsCategory.Penguin | PhysicsCategory.StoneBlock | PhysicsCategory.Enemy
        physicsBody!.contactTestBitMask = PhysicsCategory.StoneBlock
        physicsBody!.restitution = 0.1
        self.physicsBody!.mass = (self.physicsBody!.mass * 2.0)
        self.health = Int(self.physicsBody!.mass * 100)
    }
    
    func contactWithPenguin(_ contactImpulse: CGFloat) {
        guard let gameScene = self.scene as? GameScene else {
            fatalError("This node does not belong to a GameScene")
        }
        self.health -= Int(contactImpulse/2)
        gameScene.score += 25
        if(self.health <= 0) {
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
        breakBlock()
        }
    }
    
    func breakBlock() {
        guard let gameScene = self.scene as? GameScene else {
            fatalError("This node does not belong to a GameScene")
        }
        gameScene.emitParticles("100", node: self, remove: false)
        gameScene.score += 100
        run(gameScene.rockCrumble1Sound)
        gameScene.emitParticles("BrokenStoneFX", node: self, remove: true)
    }
}
