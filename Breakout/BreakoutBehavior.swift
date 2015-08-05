//
//  BreakoutBehavior.swift
//  Breakout
//
//  Created by Dmitry Terekhov on 02.08.15.
//  Copyright (c) 2015 Stanford University. All rights reserved.
//

import UIKit

/// Contains complex behavior (from simple behaviors) for different type views to animate
class BreakoutBehavior: UIDynamicBehavior {
    private struct Constants {
        static let BallElasticity: CGFloat = 1
        static let BallSpeed: CGFloat = 0.5
    }
    
    // MARK: - Members
    private lazy var collider: UICollisionBehavior = {
        let lazilyCreatedCollider = UICollisionBehavior()
        lazilyCreatedCollider.translatesReferenceBoundsIntoBoundary = true
        return lazilyCreatedCollider
    }()
    
    private lazy var baseBehavior: UIDynamicItemBehavior = {
        let lazilyCreatedBaseBehavior = UIDynamicItemBehavior()
        lazilyCreatedBaseBehavior.allowsRotation = false
        lazilyCreatedBaseBehavior.elasticity = Constants.BallElasticity
        lazilyCreatedBaseBehavior.friction = 0
        lazilyCreatedBaseBehavior.resistance = 0
        return lazilyCreatedBaseBehavior
    }()
    
    // MARK: - Lifecycle
    override init() {
        super.init()
        addChildBehavior(collider)
        addChildBehavior(baseBehavior)
    }
    
    // MARK: - Complex behaviors
    // MARK: Ball
    func addBallBehavior(ball: UIView) {
        dynamicAnimator?.referenceView?.addSubview(ball)
        collider.addItem(ball)
        baseBehavior.addItem(ball)
    }
    
    // TODO: - Убрать нарастание скорости
    func pushBall(ball: UIView) {
        let push = UIPushBehavior(items: [ball], mode: UIPushBehaviorMode.Instantaneous)
        push.magnitude = Constants.BallSpeed
        
        push.angle = CGFloat(Double(arc4random()) * M_PI * 2 / Double(UINT32_MAX))
        push.action = { [weak push] in
            if !push!.active {
                self.removeChildBehavior(push!)
            }
        }
        addChildBehavior(push)
    }
    
    // MARK:
    func addBarrier(path: UIBezierPath, named name: String) {
        collider.removeBoundaryWithIdentifier(name)
        collider.addBoundaryWithIdentifier(name, forPath: path)
    }
}
