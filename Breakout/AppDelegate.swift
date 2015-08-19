//
//  AppDelegate.swift
//  Breakout
//
//  Created by Dmitry Terekhov on 01.08.15.
//  Copyright (c) 2015 Stanford University. All rights reserved.
//

import UIKit
import CoreMotion

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    
    // Motion is done using hardware that must be shared
    // So anyone in this app using CoreMotion must use this
    struct Motion {
        static let Manager = CMMotionManager()
    }
}

