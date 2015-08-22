//
//  BreakoutUIHelper.swift
//  Breakout
//
//  Created by Dmitry Terekhov on 20.08.15.
//  Copyright (c) 2015 Stanford University. All rights reserved.
//

import UIKit

class BreakoutUIHelper {
    static var isIPad: Bool {
        return UIDevice.currentDevice().userInterfaceIdiom == .Pad
    }
    
    static func fadeInOutAnimation(view: UIView) {
        UIView.animateWithDuration(1.0, animations: { () -> Void in
            view.alpha = 1.0
            }) { (finished) -> Void in
                UIView.animateWithDuration(0.2, animations: { () -> Void in
                    view.alpha = 0.0
                })
        }
    }
    
    static func addParallaxEffect(backgroundView: UIView, offset: Int) {
        // Set vertical effect
        let verticalMotionEffect = UIInterpolatingMotionEffect(keyPath: "center.y",
            type: .TiltAlongVerticalAxis)
        verticalMotionEffect.minimumRelativeValue = -offset
        verticalMotionEffect.maximumRelativeValue = offset
        
        // Set horizontal effect
        let horizontalMotionEffect = UIInterpolatingMotionEffect(keyPath: "center.x",
            type: .TiltAlongHorizontalAxis)
        horizontalMotionEffect.minimumRelativeValue = -offset
        horizontalMotionEffect.maximumRelativeValue = offset
        
        // Create group to combine both
        let group = UIMotionEffectGroup()
        group.motionEffects = [horizontalMotionEffect, verticalMotionEffect]
        
        // Add both effects to your view
        backgroundView.addMotionEffect(group)
    }
    
    static func addGradientColors(view: UIView, cornerRadius: CGFloat, gradientColors: [CGColor!], gradientStops: [Double]) {
        func refreshGradientLayer(layer: CAGradientLayer) {
            layer.cornerRadius = cornerRadius
            layer.frame = view.bounds
            layer.locations = gradientStops
            layer.colors = gradientColors
        }
        
        if let gradientLayer = view.layer.sublayers?.first as? CAGradientLayer {
            refreshGradientLayer(gradientLayer)
        } else {
            var gradientLayer = CAGradientLayer()
            refreshGradientLayer(gradientLayer)
            view.layer.insertSublayer(gradientLayer, atIndex: 0)
        }
    }
}