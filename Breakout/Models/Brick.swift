//
//  Brick.swift
//  Breakout
//
//  Created by Dmitry Terekhov on 17.08.15.
//  Copyright (c) 2015 Stanford University. All rights reserved.
//

import UIKit

class Brick {
    private struct Constants {
        static let GradientStops = [0.0, 0.2, 0.6, 1.0]
        static let CornerRadius: CGFloat = 2.0
        
        static let TypeNormal_ColorMiddle = UIColor(red:0.84, green:0.49, blue:0.36, alpha:1)
        static let TypeNormal_ColorLight = UIColor(red:0.9, green:0.66, blue:0.59, alpha:1)
        static let TypeNormal_ColorDark = UIColor(red:0.8, green:0.38, blue:0.22, alpha:1)
        static let TypeNormal_GradientColors = [
            TypeNormal_ColorMiddle.CGColor,
            TypeNormal_ColorLight.CGColor,
            TypeNormal_ColorDark.CGColor
        ]
        
        static let TypeSolid_ColorMiddle = UIColor(red:0.38, green:0.38, blue:0.4, alpha:1)
        static let TypeSolid_ColorLight = UIColor(red:0.6, green:0.62, blue:0.63, alpha:1)
        static let TypeSolid_ColorDark = UIColor(red:0.16, green:0.16, blue:0.14, alpha:1)
        static let TypeSolid_GradientColors = [
            TypeSolid_ColorMiddle.CGColor,
            TypeSolid_ColorLight.CGColor,
            TypeSolid_ColorDark.CGColor
        ]
        
        static let TypeShortPaddleForce_ColorMiddle = UIColor(red:0.4, green:0.8, blue:1, alpha:1)
        static let TypeShortPaddleForce_ColorLight = UIColor(red:0.4, green:1, blue:1, alpha:1)
        static let TypeShortPaddleForce_ColorDark = UIColor(red:0.01, green:0.5, blue:1, alpha:1)
        static let TypeShortPaddleForce_GradientColors = [
            TypeShortPaddleForce_ColorMiddle.CGColor,
            TypeShortPaddleForce_ColorLight.CGColor,
            TypeShortPaddleForce_ColorDark.CGColor
        ]
    }
    
    enum BrickType {
        case Normal
        case SolidBrick
        case ShortPaddleForce
    }
    
    var view: UIView
    var type: BrickType {
        didSet {
            refreshGradientColor()
        }
    }
    
    init(parentView: UIView, type: BrickType) {
        self.type = type
        self.view = UIView()
        parentView.addSubview(self.view)
    }
    
    func refreshGradientColor() {
        var gradientColors: [CGColor!]
        switch type {
        case .Normal:
            gradientColors = Constants.TypeNormal_GradientColors
        case .SolidBrick:
            gradientColors = Constants.TypeSolid_GradientColors
        case .ShortPaddleForce:
            gradientColors = Constants.TypeShortPaddleForce_GradientColors
        }
        BreakoutUIHelper.addGradientColors(view, cornerRadius: Constants.CornerRadius, gradientColors: gradientColors, gradientStops: Constants.GradientStops)
    }
}