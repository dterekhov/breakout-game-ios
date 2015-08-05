//
//  FirstViewController.swift
//  Breakout
//
//  Created by Dmitry Terekhov on 01.08.15.
//  Copyright (c) 2015 Stanford University. All rights reserved.
//

import UIKit

class GameViewController: UIViewController {
    private struct Constants {
    }
    
    // MARK: - Members
    @IBOutlet private weak var gameView: BezierPathsView!
    private let breakoutBehavior = BreakoutBehavior()
    var ballInGame = false
    var ball: UIView?
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        animator.addBehavior(breakoutBehavior)
    }
    
    override func viewDidLayoutSubviews() {
        if !ballInGame {
            ballInGame = true
            
            addBall()
        }
    }
    
    // MARK: - Animation
    private lazy var animator: UIDynamicAnimator = {
        let lazilyCreatedDynamicAnimator = UIDynamicAnimator(referenceView: self.gameView)
        return lazilyCreatedDynamicAnimator
    }()
    
    // MARK: - Gestures
    @IBAction private func gameViewTap(sender: UITapGestureRecognizer) {
        breakoutBehavior.pushBall(ball!)
    }
    
    @IBAction private func gameViewSwipe(sender: UIPanGestureRecognizer) {
        
    }
    
    // MARK: -
    private func addBall() {
        let ball = UIView(frame: CGRect(origin: CGPoint.zeroPoint, size: ballSize))
        ball.center = CGPoint(x: view.bounds.midX, y: view.bounds.midY)
        ball.layer.cornerRadius = ballSize.width / 2
        ball.backgroundColor = UIColor.lightGrayColor()
        self.ball = ball
        
        breakoutBehavior.addBallBehavior(ball)
    }
    
    
    
    private var ballSize: CGSize {
        let sideSize = gameView.bounds.size.width / 10
        return CGSize(width: sideSize, height: sideSize)
    }
}

