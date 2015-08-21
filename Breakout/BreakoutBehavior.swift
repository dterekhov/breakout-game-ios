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
    private lazy var baseBehavior: UIDynamicItemBehavior = {
        let lazilyCreatedBaseBehavior = UIDynamicItemBehavior()
        lazilyCreatedBaseBehavior.allowsRotation = false
        lazilyCreatedBaseBehavior.elasticity = Constants.BallElasticity
        lazilyCreatedBaseBehavior.friction = 0
        lazilyCreatedBaseBehavior.resistance = 0
        lazilyCreatedBaseBehavior.angularResistance = 0
        return lazilyCreatedBaseBehavior
    }()
    
    var allowBallRotation: Bool {
        get { return baseBehavior.allowsRotation }
        set {
            baseBehavior.allowsRotation = newValue
            
            // Stop current ball's rotation
            if ball != nil && !newValue {
                let angularVelocity = baseBehavior.angularVelocityForItem(ball!)
                baseBehavior.addAngularVelocity(-angularVelocity, forItem: ball!)
            }
        }
    }
    
    private lazy var collider: UICollisionBehavior = {
        let lazilyCreatedCollider = UICollisionBehavior()
        lazilyCreatedCollider.action = {
            if self.ball != nil && !CGRectIntersectsRect(self.ball!.frame, self.dynamicAnimator!.referenceView!.bounds) {
                self.removeBallBehavior()
                if self.ballOutOfGameViewBoundsHandler != nil {
                    self.ballOutOfGameViewBoundsHandler!()
                }
            }
        }
        return lazilyCreatedCollider
    }()
    
    private var gravity = UIGravityBehavior()
    
    var allowBallGravity: Bool {
        get { return gravity.items.count > 0 }
        set {
            let motionManager = AppDelegate.Motion.Manager
            if !motionManager.accelerometerAvailable { return }
            if newValue {
                addChildBehavior(gravity)
                motionManager.startAccelerometerUpdatesToQueue(NSOperationQueue.mainQueue()) { (data, error) -> Void in
                    self.gravity.gravityDirection = CGVector(dx: data.acceleration.x, dy: -data.acceleration.y)
                }
            } else {
                removeChildBehavior(gravity)
                motionManager.stopAccelerometerUpdates()
            }
        }
    }
    
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
        removeBallBehavior()
        
        dynamicAnimator?.referenceView?.addSubview(ball)
        collider.addItem(ball)
        baseBehavior.addItem(ball)
        gravity.addItem(ball)
    }
    
    private func removeBallBehavior() {
        if ball == nil { return }
        baseBehavior.removeItem(ball!)
        gravity.removeItem(ball!)
        ball!.removeFromSuperview()
        // collider keep object 'ball' - so remove 'ball' from collider at the end
        collider.removeItem(ball!)
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
        if ball == nil { return }
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