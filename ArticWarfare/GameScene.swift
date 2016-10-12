//
//  GameScene.swift
//  ArticWarfare
//
//  Created by JJ on 8/3/16.
//  Copyright (c) 2016 JJ. All rights reserved.
//

import SpriteKit
import GameplayKit

fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l < r
  case (nil, _?):
    return true
  default:
    return false
  }
}

fileprivate func > <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l > r
  default:
    return rhs < lhs
  }
}


protocol CustomNodeEvents {
    func didMoveToScene()
}

protocol SKSceneDelegate {
    var health: Int {get}
    func update()
}

class GameScene: SKScene, SKPhysicsContactDelegate {
    
    //Nodes in scene
    var penguin: SKSpriteNode?
    var enemy: SKNode?
    var spriteLayer = SKNode()
    var worldLayer = SKNode()
    var slingshot = SKNode()
    var background = SKNode()
    var backgroundLayer1 = SKNode()
    var backgroundLayer2 = SKNode()
    var backgroundLayer3 = SKNode()
    
    //Camera and related constraints
    var cameraNode = SKCameraNode()
    var previousPosition: CGPoint = CGPoint(x: 275, y: -500)
    var lerpDiff: CGPoint?
    var penguinInScene: Bool = false
    var actions = Array<SKAction>()
    var cameraVector: CGVector!
    var cameraXMovement: CGFloat!
    var cameraYMovement: CGFloat!
    var cameraXYConstraint: SKConstraint!
    var cameraScaleConstraint: SKConstraint!
    var penguinCameraConstraint: SKConstraint?
    
    //Touches
    var penguinIsDragged = false
    var touchCurrentPoint: CGPoint!
    var touchStartingPoint: CGPoint!
    var selectedNodes = [UITouch:SKSpriteNode]() //only if multi touch enabled
    
    //Values in scene
    var score: Int = 0
    var penguinsRemaining: Int = 0
    
    //HUD
    var scoreLabel: SKLabelNode!
    var penguinsRemainingLabel: SKLabelNode?

    //Bools
    var penguinExists: Bool = false
    var penguinInAction: Bool = false
    var hasNotMadeContact: Bool = false
    var penguinCanInteract: Bool = true
    var updatesCalled = 0
    var isPinching = false
    
    //Gestures
    let pinchSender = UIPinchGestureRecognizer()
    
    //Sounds
    var bgSounds: SKAudioNode!
    let elasticSnapSound = SKAction.playSoundFileNamed("elasticBandSnap.m4a", waitForCompletion: false)
    let erikWeeSound = SKAction.playSoundFileNamed("erikWee.m4a", waitForCompletion: false)
    let poofSound = SKAction.playSoundFileNamed("poof.m4a", waitForCompletion: false)
    let rockHit1Sound = SKAction.playSoundFileNamed("rockHit1.m4a", waitForCompletion: false)
    let rockCrumble1Sound = SKAction.playSoundFileNamed("stoneCrumble1.m4a", waitForCompletion: false)
    let slingshotStressSound = SKAction.playSoundFileNamed("slingshotStressSound.m4a", waitForCompletion: true)
    let slushSound = SKAction.playSoundFileNamed("slushSound1.m4a", waitForCompletion: false)
    let woodCrack = SKAction.playSoundFileNamed("woodCrack1.m4a", waitForCompletion: false)
    let woodHit1Sound = SKAction.playSoundFileNamed("woodHit1.mp3", waitForCompletion: false)
    
    //Animations
    var penguinStdFly: [SKTexture]?
    
    //SKEmitters
    
    //Update
    var lastUpdate: TimeInterval!
    var deltaTime: CGFloat!
    var deltaX: CGFloat = 0.0
    
    //Parallax
    
    let scale: CGFloat = 2.0
    var moveXFactor: CGFloat = 0.0
    let bg1ParallaxSpeedFactor: CGFloat = -0.4
    let bg2ParallaxSpeedFactor: CGFloat = -0.2
    let bg3ParallaxSpeedFactor: CGFloat = -0.1
    
    //Physics fields
    var airResistance = SKFieldNode.dragField()
    
    /*
    **  Setup view
    */
    
    override func didMove(to view: SKView){
        playBackgroundMusic("bgWindSound2.m4a")
        physicsWorld.contactDelegate = self
        //Bounding box
        let playableRect = CGRect(x: -2000, y: 185, width: 6000, height: 4000)
        physicsBody = SKPhysicsBody(edgeLoopFrom: playableRect)
        physicsBody!.contactTestBitMask = PhysicsCategory.Penguin
        physicsBody!.categoryBitMask = PhysicsCategory.Edge
        physicsWorld.gravity = Settings.Game.gravity
        self.view?.isMultipleTouchEnabled = true
        createNodes()
        setupCamera()
        createField()
        
        //pinch gestures
        let pinchToZoom: UIPinchGestureRecognizer = UIPinchGestureRecognizer(target: self, action: #selector(GameScene.handlePinch(_:)))
        view.addGestureRecognizer(pinchToZoom)
        
        afterDelay(1.5, runBlock: {
            self.addPenguin()
        })
        
        //updates
        lastUpdate = 0
        deltaTime = 0.01666
    }
    
    /** SETUP **/
    
    /*
    **  Create initial nodes in scene
    */
    
    func createNodes() {
        //link custom nodes
        enumerateChildNodes(withName: "//*", using: { node, _ in
            if let customNode = node as? CustomNodeEvents {
                customNode.didMoveToScene()
            }
        })
        spriteLayer = childNode(withName: "Sprites")!
        background = childNode(withName: "Background")!
        backgroundLayer1 = background.childNode(withName: "background")!
        backgroundLayer2 = background.childNode(withName: "backgroundMountains")!
        backgroundLayer3 = background.childNode(withName: "backgroundDomes")!
        slingshot = spriteLayer.childNode(withName: "slingshot")!
        
        //Constrain nodes as needed
        constrainBackgroundNode(backgroundLayer1, lowerRange: -1200, upperRange: 600)
        constrainBackgroundNode(backgroundLayer2, lowerRange: -1200, upperRange: 900)
        constrainBackgroundNode(backgroundLayer3, lowerRange: -1200, upperRange: 600)
    }
    
    /*
    **  Physics field for resistance (wind)
    */
    
    func createField() {
        airResistance.isEnabled = true
        airResistance.strength = 0.005
        //airResistance.falloff = 50
        airResistance.position = spriteLayer.position
        print("sprite layer position: \(spriteLayer.position)")
        //addChild(airResistance)
    }
    
    /*
    **  Setup camera node and set constraints for scale and position
    */
    
    func setupCamera() {
        spriteLayer.addChild(cameraNode)
        self.camera = cameraNode
        cameraNode.setScale(0.8)
        cameraNode.position = CGPoint(x: 275, y: -500 )
        //get scene size as scaled by 'scaleMode = .AspectFill'
        let scaledSize = CGSize(width: self.size.width * cameraNode.xScale, height: self.size.height * cameraNode.yScale)
        //get the frame of the entire level contents
        let worldRect = spriteLayer.calculateAccumulatedFrame()
        //inset the frame from the edges of the level 
        let xInset = min((scaledSize.width/2)-100, worldRect.width/2)
        let yInset = min((scaledSize.height/2)-100, worldRect.height/2)
        let insetContentRect = worldRect.insetBy(dx: xInset, dy: yInset)
    
        //use the corners of the inset as the X and Y range of a position constraint
        let xRange = SKRange(lowerLimit: insetContentRect.minX, upperLimit: insetContentRect.maxX)
        let yRange = SKRange(lowerLimit: insetContentRect.minY, upperLimit: insetContentRect.maxY)
        let levelEdgeConstraint = SKConstraint.positionX(xRange, y: yRange)
        levelEdgeConstraint.referenceNode = spriteLayer
        
        
        /* 
        **  HUD - bound to camera to stay in position of scene
        */
        
        scoreLabel = SKLabelNode()
        scoreLabel.text = "Score: 0"
        scoreLabel.fontName = "helvetica"
        scoreLabel.fontSize = 50
        scoreLabel.fontColor = UIColor.white
        scoreLabel.zPosition = 2000
        cameraNode.addChild(scoreLabel)
        scoreLabel.position = CGPoint(x: 800, y: 700)
        //cameraNode.constraints = [cameraXYConstraint]
    }
    
    /*
    **  Update score on HUD - for use in update loop
    */
    
    func updateHUD() {
        scoreLabel.text = "Score: \(score)"
    }
    
    /*
    **  Update camera depending on penguin launch - for use in update loop
    */
    
    func updateCamera() {
        //keep camera on penguin x coordinate if penguinInAction is true
        if penguinInAction {
            if (hasNotMadeContact) {
                cameraNode.position.x = penguin!.position.x
            }
        }
    }
    
    /*
    **  Create texture array for animations
    */
    
    func createAnimations(_ textureAtlas: SKTextureAtlas, textureName: String) -> [SKTexture] {
        var textureArray = [SKTexture]()
        let numImages = textureAtlas.textureNames.count
        for i in 1..<(numImages) {
            let texturesName = "\(textureName)\(i)"
            textureArray.append(textureAtlas.textureNamed(texturesName))
        }
        return textureArray
    }
    
    /*
    **  Add penguin node to screen
    */
    
    func addPenguin() {
        if(penguinExists) {
            return
        }
        penguinCanInteract = true
        penguinExists = true
        penguin = SKSpriteNode(imageNamed: "penguin")
        penguin!.name = "penguin"
        penguin!.position = Settings.Metrics.penguinRestPosition
        penguin!.zPosition = 300
        spriteLayer.addChild(penguin!)
        penguin!.physicsBody = SKPhysicsBody(circleOfRadius: penguin!.frame.size.width * 0.35)
        penguin!.physicsBody!.categoryBitMask = PhysicsCategory.Penguin
        penguin!.physicsBody!.collisionBitMask = PhysicsCategory.Edge | PhysicsCategory.WoodBlock | PhysicsCategory.StoneBlock | PhysicsCategory.Penguin
        penguin!.physicsBody!.contactTestBitMask = PhysicsCategory.StoneBlock | PhysicsCategory.WoodBlock | PhysicsCategory.Enemy
        penguin!.physicsBody!.isDynamic = false
        penguin!.physicsBody!.affectedByGravity = false
        penguin!.physicsBody!.allowsRotation = false
        penguin!.physicsBody!.mass = 0.05
        penguin!.physicsBody!.restitution = 0.2
        penguin!.physicsBody!.friction = 0.8
        penguin!.physicsBody!.usesPreciseCollisionDetection = true
        let moveToPenguin = SKAction.moveTo(x: penguin!.position.x + CGFloat(100), duration: 0.5)
        let scaleToPenguin = SKAction.scale(to: 0.8, duration: 0.5)
        actions.append(scaleToPenguin)
        actions.append(moveToPenguin)
        let group = SKAction.group(actions)
        self.cameraNode.run(group)
        actions.removeAll()
        
    }
    
    /*  
    **  Constraint to center camera on penguin
    */
    
    func constrainCameraToPenguin(_ node: SKNode) {
        let penguinCamRange = SKRange(lowerLimit: 0, upperLimit: 100)
        if node.position.x > slingshot.position.x || node.position.x < slingshot.position.x {
            penguinCameraConstraint = SKConstraint.distance(penguinCamRange, to: penguin!)
            cameraNode.constraints?.append(penguinCameraConstraint!)
        }
        
    }
    
    /*
    **  When penguin is released from slingshot
    */
    
    func launchPenguin(_ node: SKNode) {
        penguinInAction = true
        run(elasticSnapSound)
        run(erikWeeSound, withKey: "wee")
        constrainCameraToPenguin(node)
        let zoomOutFromPenguin = SKAction.scale(to: maxCameraScale(), duration: 3.0)
        cameraNode.run(zoomOutFromPenguin)
        hasNotMadeContact = true
        cameraNode.position.x = penguin!.position.x
        afterDelay(7, runBlock: {
            self.removePenguin(node)
        })
    }
    
    /*
    **  Remove penguin from scene - used after set time //TODO: remove after movement ceases
    */
    
    func removePenguin(_ node: SKNode) {
        penguin!.physicsBody!.contactTestBitMask = 0
        penguinCanInteract = false
        penguinInAction = false
        penguinExists = false
        emitParticles("BirdPoofFX", node: node, remove: true)
        run(poofSound)
        afterDelay(1, runBlock: {
            //self.cameraNode.constraints = [self.cameraXYConstraint]
            self.addPenguin()
        })
    }
    
    /*
    **  Emitters - takes filename of texture, node, and remove after duration if applicable
    */
    
    func emitParticles(_ name: String, node: SKNode, remove: Bool) {
        let pos = node.position
        let particles = SKEmitterNode(fileNamed: name)!
        particles.position = pos
        particles.zPosition = 2000
        spriteLayer.addChild(particles)
        particles.run(SKAction.removeFromParentAfterDelay(1.0))
        if remove {
            node.run(SKAction.sequence([SKAction.scale(to: 0.0, duration: 0.5), SKAction.removeFromParent()]))
        }
    }
    
    /*
    **  Touch handlers
    */
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if (touches.count == 2) {
            handlePinch(pinchSender)
        }
        func shouldStartDragging(_ touchLocation: CGPoint, threshold: CGFloat) -> Bool {
           let distance = fingerDistanceFromPenguinRestPosition(Settings.Metrics.penguinRestPosition, fingerPosition: touchLocation)
                return (distance < Settings.Metrics.penguinRadius + threshold)
        }
    
        if let touch = touches.first {
        let touchLocation = touch.location(in: spriteLayer)
            if let node = spriteLayer.atPoint(touchLocation) as? SKSpriteNode {
                if(node.name == "penguin") {
                    if !penguinIsDragged && shouldStartDragging(touchLocation, threshold: Settings.Metrics.penguinTouchThreshold) {
                        touchStartingPoint = touchLocation
                        penguinIsDragged = true
                    }
                }
            }
        }
        
    }
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        if penguinIsDragged {
            if let touch = touches.first {
                let touchLocation = touch.location(in: spriteLayer)
                let distance = fingerDistanceFromPenguinRestPosition(touchLocation, fingerPosition: touchStartingPoint)
                if distance < Settings.Metrics.rLimit {
                    touchCurrentPoint = touchLocation
                    if (self.action(forKey: "slingSound")) != nil {
                        //do nothing
                    } else {
                        self.run(slingshotStressSound, withKey: "slingSound")
                    }
                } else {
                    touchCurrentPoint = penguinPositionForFingerPosition(touchLocation, penguinRestPosition: touchStartingPoint,
                                                                            circleRadius: Settings.Metrics.rLimit)
                    
                }
                if (convertSpriteToScene(penguin!.position).y > 160) {
                    self.penguin!.position = touchCurrentPoint
                } else {
                    penguin!.position.y = 160 + 768
                    penguin!.position.x = touchCurrentPoint.x
                }
            }
        } else {
            for touch in touches {
                /**Move camera with finger along x-axis**/
                //cameraNode.constraints! = [cameraXYConstraint]
                let location = touch.location(in: self)
                let previousLocation = touch.previousLocation(in: self)
                deltaX = location.x - previousLocation.x
                cameraNode.position.x -= deltaX
            }
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        if penguinIsDragged {
            penguinIsDragged = false
            let distance = fingerDistanceFromPenguinRestPosition(touchCurrentPoint, fingerPosition: touchStartingPoint)
            if distance > Settings.Metrics.penguinSnapLimit {
                let vectorX = touchStartingPoint.x - touchCurrentPoint.x
                let vectorY = touchStartingPoint.y - touchCurrentPoint.y
                penguin!.physicsBody!.isDynamic = true
                penguin!.physicsBody!.affectedByGravity = true
                penguin!.physicsBody!.allowsRotation = true
                penguin!.physicsBody!.applyImpulse(CGVector(dx: vectorX * Settings.Metrics.forceMultiplier,
                    dy: vectorY * Settings.Metrics.forceMultiplier))
                launchPenguin(self.penguin!)
            } else {
                penguin!.position = Settings.Metrics.penguinRestPosition
            }
        }
    }
    
    /*
    **  Zoom to pinch - //TODO: pinch at position between touches
    */
    
    func handlePinch(_ sender: UIPinchGestureRecognizer) {
        self.isUserInteractionEnabled = true
        if sender.numberOfTouches == 2 {
            isPinching = true
            let locationInView = sender.location(in: self.view)
            //let location = self.locationInView(self.view)
            if sender.state == .changed {
                let deltaScale = (sender.scale - 1.0) * 2
                let convertedScale = sender.scale - deltaScale
                var newScale = cameraNode.xScale * convertedScale
                if newScale < 0.6 {
                    newScale = 0.6
                }
                if newScale > maxCameraScale() {
                    newScale = maxCameraScale()
                }
                cameraNode.setScale(newScale)
                
                let locationAfterScale = self.convertPoint(fromView: locationInView)
                let locationDelta = (locationInView - locationAfterScale)
                var newPoint = (cameraNode.position + locationDelta)
                if newPoint.y > convertSpriteToScene(slingshot.position).y {
                    newPoint.y = convertWorldLayerToSprites(slingshot.position).y
                }
                cameraNode.position = newPoint
                sender.scale = 1.0
            }
        }
        isPinching = false
    }
    
    /*
    **  Boolean for when penguin contacts another object - used in game logic
    */
    
    func penguinMadeContact(_ node: SKNode, sound: SKAction) {
        hasNotMadeContact = false
        removeAction(forKey: "wee")
        run(sound)
        node.removeAllChildren()
    }
    
    /*
    **  Did begin contact method - handles logic after collisions
    */
    
    func didBegin(_ contact: SKPhysicsContact) {
        if (updatesCalled == 0) {return}
        updatesCalled = 0
        
        var contactBody = SKPhysicsBody()
        var otherBody = SKPhysicsBody()
        
        if (contact.bodyA.categoryBitMask < contact.bodyB.categoryBitMask) {
            contactBody = contact.bodyA
            otherBody = contact.bodyB
        } else {
           contactBody = contact.bodyB
            otherBody = contact.bodyA
        }
        let contactMask = contact.bodyA.categoryBitMask | contact.bodyB.categoryBitMask
        
        switch(contactMask) {
            case PhysicsCategory.Penguin | PhysicsCategory.WoodBlock:
                if let block = otherBody.node as? WoodBlockNode {
                    if contact.collisionImpulse > 20.0 {
                        emitParticles("starFX", node: penguin!, remove: false)
                        penguinMadeContact(penguin!, sound: woodHit1Sound)
                        block.contactWithPenguin(contact.collisionImpulse)
                    } else if (contact.collisionImpulse > 5.0) {
                        block.contactWithPenguin(contact.collisionImpulse)
                    } else {
                        return
                    }
                }
            case PhysicsCategory.Penguin | PhysicsCategory.StoneBlock:
                if let block = otherBody.node as? StoneBlockNode {
                        if contact.collisionImpulse > 25.0 {
                        emitParticles("starFX", node: penguin!, remove: false)
                        penguinMadeContact(penguin!, sound: rockHit1Sound)
                        block.contactWithPenguin(contact.collisionImpulse)
                    } else if (contact.collisionImpulse > 5.0) {
                        block.contactWithPenguin(contact.collisionImpulse)
                    } else {
                        return
                    }
                }
            case PhysicsCategory.StoneBlock | PhysicsCategory.StoneBlock:
                if let stoneBlock1 = otherBody.node as? StoneBlockNode {
                    if let stoneBlock2 = contactBody.node as? StoneBlockNode {
                        if contact.collisionImpulse > 20.0 {
                            stoneBlock1.contactWithBlock(contact.collisionImpulse)
                            stoneBlock2.contactWithBlock(contact.collisionImpulse)
                        } else {
                            return
                        }
                    }
                }
            case PhysicsCategory.WoodBlock | PhysicsCategory.WoodBlock:
                if let woodBlock1 = otherBody.node as? WoodBlockNode {
                    if let woodBlock2 = contactBody.node as? WoodBlockNode {
                        if contact.collisionImpulse > 20.0 {
                            run(woodCrack)
                            woodBlock1.contactWithBlock(contact.collisionImpulse)
                            woodBlock2.contactWithBlock(contact.collisionImpulse)
                        } else {
                            return
                        }
                    }
            }
            
            case PhysicsCategory.StoneBlock | PhysicsCategory.WoodBlock:
                return
            case PhysicsCategory.Penguin | PhysicsCategory.Penguin:
                hasNotMadeContact = false
                removeAction(forKey: "wee")
            case PhysicsCategory.Penguin | PhysicsCategory.Edge:
                if penguinCanInteract {
                    penguinMadeContact(penguin!, sound: slushSound)
                }
            case PhysicsCategory.Penguin | PhysicsCategory.Enemy:
                if let enemy = otherBody.node as? EnemyNode {
                        if contact.collisionImpulse > 20 {
                            //runAction()
                            enemy.contactWithPenguin(contact.collisionImpulse)
                            print("\(contact.collisionImpulse)")
                        } else if contact.collisionImpulse > 5 {
                            //runAction()
                            print("\(contact.collisionImpulse)")
                            enemy.contactWithPenguin(contact.collisionImpulse)
                        } else if contact.collisionImpulse > 1 {
                            print("\(contact.collisionImpulse)")
                            enemy.contactWithPenguin(contact.collisionImpulse)
                        } else {
                            return
                        }
                }
                default:
                    return
            }
    }
    
    /*
    **  Update loop
    */
    
    override func update(_ currentTime: TimeInterval) {
        updateHUD()
        updateCamera()
        
        //camera follows penguin along x axis until it hits a block
        if(penguinInAction){
            if(!hasNotMadeContact) {
                //cameraNode.constraints! = [cameraXYConstraint]
            }
        }
        
        updatesCalled += 1
        
        deltaTime = CGFloat(currentTime - lastUpdate)
        lastUpdate = currentTime
        
        if deltaTime > 1.0 {
            deltaTime = 0.01666
        }
        
        if penguinInAction{
            if hasNotMadeContact {
                penguin!.rotateToVelocity(penguin!.physicsBody!.velocity, rate: 0.5)
            }
        }
        
        constrainCameraToScene()
        
        if cameraMoved() {
            if !isPinching {
                parallaxEffect()
            }
        }
        previousPosition.x = cameraNode.position.x  //for calculating deltaPosition
    }
    
    /*  
    ** Parallax effect for 3 background layers
    */
    
    func parallaxEffect() {
        moveXFactor = deltaX * scale
        
        backgroundLayer1.position = CGPoint(x: backgroundLayer1.position.x + bg1ParallaxSpeedFactor * moveXFactor,
                                            y: backgroundLayer1.position.y)
        backgroundLayer2.position = CGPoint(x: backgroundLayer2.position.x + bg2ParallaxSpeedFactor * moveXFactor,
                                            y: backgroundLayer2.position.y)
        backgroundLayer3.position = CGPoint(x: backgroundLayer3.position.x + bg3ParallaxSpeedFactor * moveXFactor,
                                            y: backgroundLayer3.position.y)
    }
    
    /*
     **  New camera constraints
     */
    
    func constrainCameraToScene() {
        if (cameraNode.position.x < -2000.0) {
            cameraNode.position.x = -2000.0
        }
        if (cameraNode.position.x > (1200/(getCameraXScale()*2))) {
            cameraNode.position.x = (1200/(getCameraXScale()*2))
        }
        if (cameraNode.position.y < -300) {
            cameraNode.position.y = -300
        }
        if (cameraNode.position.y > 4000) {
            cameraNode.position.y = 4000
        }
    }
    
    /*
    **  Constrain background layers to scene
    */
    
    func constrainBackgroundNode(_ layer: SKNode, lowerRange: CGFloat, upperRange: CGFloat) {
        let xRange = SKRange(lowerLimit: lowerRange, upperLimit: upperRange)
        let levelEdgeConstraint = SKConstraint.positionX(xRange)
        levelEdgeConstraint.referenceNode = background
        layer.constraints = [levelEdgeConstraint]
        
    }
    
    /******HELPERS*****/
    
    /*
    **  Slingshot helper - keeps penguin within distance of slingshot 
    */
    
    func fingerDistanceFromPenguinRestPosition(_ penguinRestPosition: CGPoint, fingerPosition: CGPoint) -> CGFloat {
        return sqrt(pow(penguinRestPosition.x - fingerPosition.x,2) + pow(penguinRestPosition.y - fingerPosition.y,2))
    }
    
    func penguinPositionForFingerPosition(_ fingerPosition: CGPoint, penguinRestPosition: CGPoint, circleRadius rLimit: CGFloat) -> CGPoint {
        let theta = atan2(fingerPosition.x - penguinRestPosition.x, fingerPosition.y - penguinRestPosition.y)
        let cX = sin(theta) * rLimit
        let cY = cos(theta) * rLimit
        return CGPoint(x: cX + penguinRestPosition.x, y: cY + penguinRestPosition.y)
    }
    
    /*
    **  Convert position position of node from one layer to another
    */
    
    func convertWorldLayerToSprites(_ position: CGPoint) -> CGPoint {
        let newPositionX = position.x - 1024
        let newPositionY = position.y - 768
        return CGPoint(x: newPositionX, y: newPositionY)
    }
    
    func convertSpriteToScene(_ position: CGPoint) -> CGPoint {
        let newPositionX = position.x + 1024
        let newPositionY = position.y + 768
        return CGPoint(x: newPositionX, y: newPositionY)
    }
    
    /*
    ** Camera functions and bools
    */
    
    func getCameraXScale() -> CGFloat {
        return cameraNode.xScale
    }
    func getCameraYScale() -> CGFloat {
        return cameraNode.yScale
    }
    
    func cameraMoved() -> Bool {
        
        if previousPosition.x != cameraNode.position.x {
            return true
        }
        return false
    }
    
    /*
    **  Playbackground music
    */
    
    func playBackgroundMusic(_ name: String) {
        if bgSounds != nil {
            bgSounds.removeFromParent()
        }
        let tempSounds = SKAudioNode(fileNamed: name)
        tempSounds.autoplayLooped = true
        bgSounds = tempSounds
        addChild(bgSounds)
    }
}
