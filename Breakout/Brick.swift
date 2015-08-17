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
        static let BrickTypeNormalColor = UIColor.brownColor()
        static let BrickTypeSolidColor = UIColor.lightGrayColor()
        static let BrickTypeShortPaddleForceColor = UIColor.blueColor()
    }
    
    enum BrickType {
        case Normal
        case SolidBrick
        case ShortPaddleForce
    }
    
    var view: UIView
    var type: BrickType {
        didSet {
            changeViewByType(type)
        }
    }
    
    init(parentView: UIView, type: BrickType) {
        self.type = type
        self.view = UIView()
        changeViewByType(type)
        parentView.addSubview(self.view)
    }
    
    private func changeViewByType(type: BrickType) {
        switch type {
        case .Normal:
            view.backgroundColor = Constants.BrickTypeNormalColor
        case .SolidBrick:
            view.backgroundColor = Constants.BrickTypeSolidColor
        case .ShortPaddleForce:
            view.backgroundColor = Constants.BrickTypeShortPaddleForceColor
        }
    }
}