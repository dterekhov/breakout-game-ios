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
    }
    
    // MARK: - Members
    private lazy var collider: UICollisionBehavior = {
        let lazilyCreatedCollider = UICollisionBehavior()
        lazilyCreatedCollider.action = {
            if self.ball != nil && !CGRectIntersectsRect(self.ball!.frame, self.dynamicAnimator!.referenceView!.bounds) {
                self.removeBallBehavior(self.ball!)
                if self.ballOutOfGameViewBoundsHandler != nil {
                    self.ballOutOfGameViewBoundsHandler!()
                }
            }
        }
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
    
    var ball: UIView? {
        return collider.items.filter{ $0 is UIView }.map{ $0 as! UIView }.first
    }
    
    private var ballLinearVelocity: CGPoint {
        if ball == nil { return CGPointZero }
        return baseBehavior.linearVelocityForItem(ball!)
    }
    
    private var pauseLinearVelocity = CGPointZero
    
    var ballSpeed: CGFloat = 1
    
    var ballOutOfGameViewBoundsHandler: (() -> ())?
    
    // MARK: - Accessors
    var collisionDelegate: UICollisionBehaviorDelegate? {
        get { return collider.collisionDelegate }
        set { collider.collisionDelegate = newValue }
    }
    
    // MARK: - Lifecycle
    override init() {
        super.init()
        addChildBehavior(collider)
        addChildBehavior(baseBehavior)
    }
    
    // MARK: - Complex behaviors
    // MARK: Ball
    func addBallBehavior(ball: UIView) {
        removeBallBehavior(ball)
        
        dynamicAnimator?.referenceView?.addSubview(ball)
        collider.addItem(ball)
        baseBehavior.addItem(ball)
    }
    
    private func removeBallBehavior(ball: UIView) {
        collider.removeItem(ball)
        baseBehavior.removeItem(ball)
        ball.removeFromSuperview()
    }
    
    func pushBall() {
        if ball == nil {
            return
        }
        stopBall()
        
        let push = UIPushBehavior(items: [ball!], mode: UIPushBehaviorMode.Instantaneous)
        push.magnitude = ballSpeed
        
        push.angle = CGFloat(Double(arc4random()) * M_PI * 2 / Double(UINT32_MAX))
        push.action = { [weak push] in
            if !push!.active {
                self.removeChildBehavior(push!)
            }
        }
        addChildBehavior(push)
    }
    
    func stopBall() {
        pauseLinearVelocity = ballLinearVelocity
        baseBehavior.addLinearVelocity(CGPoint(x: -ballLinearVelocity.x, y: -ballLinearVelocity.y), forItem: ball!)
    }
    
    func continueBall() {
        if ball == nil { return }
        baseBehavior.addLinearVelocity(pauseLinearVelocity, forItem: ball!)
        pauseLinearVelocity = CGPointZero
    }
    
    func isBallInMotion() -> Bool {
        return ballLinearVelocity != CGPointZero
    }
    
    // MARK: Barriers
    func addBarrier(path: UIBezierPath, named name: NSCopying) {
        collider.removeBoundaryWithIdentifier(name)
        collider.addBoundaryWithIdentifier(name, forPath: path)
    }
    
    func removeBarrier(name: NSCopying) {
        collider.removeBoundaryWithIdentifier(name)
    }
}
