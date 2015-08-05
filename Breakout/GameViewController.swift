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
        static let PaddleHeight: CGFloat = 10
        static let PaddleBottomIndent: CGFloat = 10
        static let PaddleCornerRadius: CGFloat = 5
        static let PaddleBoundaryIdentifier = "Paddle"
    }
    
    // MARK: - Members
    @IBOutlet private weak var gameView: BezierPathsView!
    private let breakoutBehavior = BreakoutBehavior()
    private lazy var ball: UIView = {
        let ball = UIView()
        ball.backgroundColor = UIColor.lightGrayColor()
        return ball
    }()
    private lazy var paddle: UIView = {
        let paddle = UIView()
        paddle.layer.cornerRadius = Constants.PaddleCornerRadius
        paddle.backgroundColor = UIColor.darkGrayColor()
        self.gameView.addSubview(paddle)
        return paddle
    }()
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        animator.addBehavior(breakoutBehavior)
    }
    
    override func viewDidLayoutSubviews() {
        resetBall()
        resetPaddle()
    }
    
    // MARK: - Animation
    private lazy var animator: UIDynamicAnimator = {
        let lazilyCreatedDynamicAnimator = UIDynamicAnimator(referenceView: self.gameView)
        return lazilyCreatedDynamicAnimator
    }()
    
    // MARK: - Gestures
    @IBAction private func gameViewTap(sender: UITapGestureRecognizer) {
        breakoutBehavior.pushBall(ball)
    }
    
    @IBAction private func gameViewSwipe(sender: UIPanGestureRecognizer) {
        // TODO: Move paddle with horizontal swipe
    }
    
    // MARK: -
    private func resetBall() {
        ball.frame = CGRect(origin: CGPoint(x: gameView.bounds.midX - ballSize.width / 2, y: gameView.bounds.midY - ballSize.height / 2), size: ballSize)
        ball.layer.cornerRadius = ballSize.width / 2
        breakoutBehavior.addBallBehavior(ball)
    }
    
    private func resetPaddle() {
        paddle.frame = CGRect(origin: CGPoint(x: gameView.bounds.midX - paddleSize.width / 2, y: gameView.bounds.height - paddleSize.height - Constants.PaddleBottomIndent), size: paddleSize)
        breakoutBehavior.addBarrier(UIBezierPath(roundedRect: paddle.frame, cornerRadius: Constants.PaddleCornerRadius), named: Constants.PaddleBoundaryIdentifier)
    }
    
    // MARK: - Helpers
    private var ballSize: CGSize {
        let sideSize = gameView.bounds.size.width / 10
        return CGSize(width: sideSize, height: sideSize)
    }
    
    private var paddleSize: CGSize {
        let width = ballSize.width * 2
        return CGSize(width: width, height: Constants.PaddleHeight)
    }
}