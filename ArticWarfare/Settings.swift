//
//  Settings.swift
//  ArticWarfare
//
//  Created by JJ on 8/25/16.
//  Copyright © 2016 JJ. All rights reserved.
//

import Foundation
import SpriteKit

struct PhysicsCategory {
    static let None:        UInt32 = 0
    static let Penguin:     UInt32 = 0b1
    static let Blank:       UInt32 = 0b10
    static let Enemy:       UInt32 = 0b100
    static let WoodBlock:   UInt32 = 0b1000
    static let StoneBlock:  UInt32 = 0b10000
    static let Edge:        UInt32 = 0b100000
}

//Slingshot
struct Settings {
    struct Metrics {
        static let penguinRadius = CGFloat(24.5)
        static let penguinRestPosition = CGPoint(x: -1020, y: -430)
        static let penguinTouchThreshold = CGFloat(24.5)
        static let penguinSnapLimit = CGFloat(24.5)
        static let forceMultiplier = CGFloat(0.6)
        static let rLimit = CGFloat(140)
    }
    
    struct Game {
        static let gravity = CGVector(dx: 0.0, dy: -5.0)
    }
}