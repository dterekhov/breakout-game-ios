//
//  BrickBuilder.swift
//  Breakout
//
//  Created by Dmitry Terekhov on 17.08.15.
//  Copyright (c) 2015 Stanford University. All rights reserved.
//

import UIKit

class BrickBuilder {
    private struct Constants {
        static let BrickRowsCount = 3
        static let BrickColumnsCount = 5
        static let BrickInteritemSpacing: CGFloat = 4
        static let BrickHeight: CGFloat = 30
    }
    
    private enum GameLevel {
        case GameLevel1
        case GameLevel2
    }
    
    var bricks = [Int:Brick]()
    var allBricksDestroyedHandler: (() -> ())?
    private var currentGameLevel = GameLevel.GameLevel1
    
    private let parentView: UIView
    private let breakoutBehavior: BreakoutBehavior
    
    init(parentView: UIView, breakoutBehavior: BreakoutBehavior) {
        self.parentView = parentView
        self.breakoutBehavior = breakoutBehavior
    }
    
    func buildBricks() {
        clearBricks()
        
        switch currentGameLevel {
        case .GameLevel1:
            buildBricksLevel1()
        case .GameLevel2:
            buildBricksLevel2()
        }
    }
    
    func buildBricksForNextLevel() {
        if currentGameLevel == .GameLevel1 {
            currentGameLevel = .GameLevel2
        }
        buildBricks()
    }
    
    private func clearBricks() {
        for pair in bricks {
            if let brick = bricks.removeValueForKey(pair.0) {
                breakoutBehavior.removeBarrier(pair.0)
                brick.view.removeFromSuperview()
            }
        }
    }
    
    private func buildBricksLevel1() {
        for index in 1...Constants.BrickRowsCount * Constants.BrickColumnsCount {
            bricks[index] = Brick(parentView: parentView, type: .Normal)
        }
    }
    
    private func buildBricksLevel2() {
        for index in 1...Constants.BrickRowsCount * Constants.BrickColumnsCount {
            let isRow0 = index >= 1 && index <= Constants.BrickColumnsCount
            let isRow1 = index >= 1 + Constants.BrickColumnsCount && index <= Constants.BrickColumnsCount * 2
            let isRow2 = index >= 1 + Constants.BrickColumnsCount * 2 && index <= Constants.BrickColumnsCount * 3
            
            if isRow0 {
                bricks[index] = Brick(parentView: parentView, type: .SolidBrick)
            } else if isRow1 {
                bricks[index] = Brick(parentView: parentView, type: .ShortPaddleForce)
            } else if isRow2 {
                bricks[index] = Brick(parentView: parentView, type: .Normal)
            } else {
                bricks[index] = Brick(parentView: parentView, type: .Normal)
            }
        }
    }
    
    func placeBricks() {
        let totalSpaceItemsWidth = CGFloat(Constants.BrickColumnsCount + 1) * Constants.BrickInteritemSpacing
        let brickWidth = (parentView.bounds.width - totalSpaceItemsWidth) / CGFloat(Constants.BrickColumnsCount)
        let brickSize = CGSize(width: brickWidth, height: Constants.BrickHeight)
        
        var origin = CGPoint(x: Constants.BrickInteritemSpacing, y: Constants.BrickInteritemSpacing)
        for row in 1...Constants.BrickRowsCount {
            for column in 1...Constants.BrickColumnsCount {
                let index = (row - 1) * Constants.BrickColumnsCount + column
                if let brick = bricks[index] {
                    brick.view.frame = CGRect(origin: origin, size: brickSize)
                    brick.refreshGradientColor()
                    breakoutBehavior.addBarrier(UIBezierPath(rect: brick.view.frame), named: index)
                }
                origin.x += brickWidth + Constants.BrickInteritemSpacing
            }
            origin = CGPoint(x: Constants.BrickInteritemSpacing, y: origin.y + Constants.BrickHeight + Constants.BrickInteritemSpacing)
        }
    }
    
    func destroyBrickAtIndex(index: Int) {
        self.breakoutBehavior.removeBarrier(index)
        
        if let brickView = bricks[index]?.view {
            UIView.transitionWithView(brickView, duration:1.0, options: UIViewAnimationOptions.TransitionFlipFromTop, animations: { () -> Void in
                brickView.alpha = 0.5
                }, completion: {
                    (success) -> Void in
                    brickView.removeFromSuperview()
                    self.bricks[index] = nil
                    
                    if self.bricks.count == 0 && self.allBricksDestroyedHandler != nil {
                        self.allBricksDestroyedHandler!()
                    }
            })
        }
    }
}