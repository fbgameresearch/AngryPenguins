//
//  EnemyNode.swift
//  ArticWarfare
//
//  Created by JJ on 9/3/16.
//  Copyright © 2016 JJ. All rights reserved.
//

import SpriteKit

class EnemyNode: SKSpriteNode, CustomNodeEvents {
    //properties
    var health: Int = 0
    
    
    func didMoveToScene() {
        self.physicsBody = SKPhysicsBody(circleOfRadius: self.frame.height/2)
        physicsBody!.friction = 1.0
        physicsBody!.isDynamic = true
        physicsBody!.affectedByGravity = true
        physicsBody!.categoryBitMask = PhysicsCategory.Enemy
        physicsBody!.collisionBitMask = PhysicsCategory.Edge | PhysicsCategory.WoodBlock |
                                    PhysicsCategory.Penguin | PhysicsCategory.StoneBlock | PhysicsCategory.Enemy
        physicsBody!.contactTestBitMask = PhysicsCategory.Penguin | PhysicsCategory.Enemy
        physicsBody!.restitution = 0.05
        self.health = 25
        print("enemy health: \(self.health)")
    }
    
    func contactWithPenguin(_ contactImpulse: CGFloat) {
        guard let gameScene = self.scene as? GameScene else {
            fatalError("This node does not belong to a GameScene")
        }
        self.health -= Int(contactImpulse/5)
        gameScene.score += 25
        if(self.health <= 0) {
            enemyKilled()
        }
    }
    
    func contactWithEnemy(_ contactImpulse: CGFloat) {
        guard let gameScene = self.scene as? GameScene else {
            fatalError("This node does not belong to a GameScene")
        }
        self.health -= Int(contactImpulse/2)
        gameScene.score += 5
        if(self.health <= 0) {
            enemyKilled()
        }
    }
    
    func enemyKilled() {
        guard let gameScene = self.scene as? GameScene else {
            fatalError("This node does not belong to a GameScene")
        }
        gameScene.emitParticles("100", node: self, remove: true)
        gameScene.score += 100
        //runAction(gameScene.rockCrumble1Sound)
        //gameScene.emitParticles("BirdPoofFX", node: self, remove: true)
    }
}
