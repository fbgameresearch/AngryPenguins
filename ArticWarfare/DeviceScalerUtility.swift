//
//  DeviceScalerUtility.swift
//  ArticWarfare
//
//  Created by JJ on 8/19/16.
//  Copyright © 2016 JJ. All rights reserved.
//

import UIKit
import Foundation
import SpriteKit

enum UIUserInterfaceIdiom : Int {
    case unspecified
    case phone
    case pad
}

struct ScreenSize {
    static let SCREEN_WIDTH         = UIScreen.main.bounds.size.width
    static let SCREEN_HEIGHT        = UIScreen.main.bounds.size.height
    static let SCREEN_MAX_LENGTH    = max(ScreenSize.SCREEN_WIDTH, ScreenSize.SCREEN_HEIGHT)
    static let SCREEN_MIN_LENGTH    = min(ScreenSize.SCREEN_WIDTH, ScreenSize.SCREEN_HEIGHT)
}

struct DeviceType {
    static let IS_IPHONE_4_OR_LESS  = UIDevice.current.userInterfaceIdiom == .phone && ScreenSize.SCREEN_MAX_LENGTH < 568.0
    static let IS_IPHONE_5          = UIDevice.current.userInterfaceIdiom == .phone && ScreenSize.SCREEN_MAX_LENGTH == 568.0
    static let IS_IPHONE_6          = UIDevice.current.userInterfaceIdiom == .phone && ScreenSize.SCREEN_MAX_LENGTH == 667.0
    
    static let IS_IPHONE_6P         = UIDevice.current.userInterfaceIdiom == .phone && ScreenSize.SCREEN_MAX_LENGTH == 736.0
    static let IS_IPAD              = UIDevice.current.userInterfaceIdiom == .pad && ScreenSize.SCREEN_MAX_LENGTH == 1024.0
    static let IS_IPAD_PRO          = UIDevice.current.userInterfaceIdiom == .pad && ScreenSize.SCREEN_MAX_LENGTH == 1366.0
}

public func scaleXPhys(_ float: CGFloat) -> CGFloat {
    var width = CGFloat()
    if DeviceType.IS_IPHONE_5 {
        width = CGFloat(float*1.11)
    }
    if DeviceType.IS_IPHONE_6 {
        width = CGFloat(float*1.0)
    }
    if DeviceType.IS_IPHONE_6P {
        width = CGFloat(float*1.875)
    }
    if DeviceType.IS_IPAD {
        width = float
    }
    if DeviceType.IS_IPAD_PRO {
        width = CGFloat(float*2.668)
    }
    return width
}

public func scaleYPhys(_ float: CGFloat) -> CGFloat {
    var height = CGFloat()
    if DeviceType.IS_IPHONE_5 {
        height = CGFloat(float*0.8333)
    }
    if DeviceType.IS_IPHONE_6 {
        height = CGFloat(float*1.0)
    }
    if DeviceType.IS_IPHONE_6P {
        height = CGFloat(float*1.406)
    }
    if DeviceType.IS_IPAD {
        height = float
    }
    if DeviceType.IS_IPAD_PRO {
        height = CGFloat(float*2.667)
    }
    return height
}

public func scaleXYPhys(_ float: CGFloat) -> CGFloat {
    var scale = CGFloat()
    if DeviceType.IS_IPHONE_5 {
        scale = CGFloat(float*0.8333)
    }
    if DeviceType.IS_IPHONE_6 {
        scale = CGFloat(float*1.0)
    }
    if DeviceType.IS_IPHONE_6P {
        scale = CGFloat(float*1.406)
    }
    if DeviceType.IS_IPAD {
        scale = float
    }
    if DeviceType.IS_IPAD_PRO {
        scale = CGFloat(float*2.667)
    }
    return scale
}

public func maxCameraScale() -> CGFloat {
    var maxScale = CGFloat()
    if DeviceType.IS_IPAD {
        maxScale = 0.9
    } else {
        maxScale = 1.3
    }
    return maxScale
}
