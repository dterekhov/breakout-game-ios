//
//  FirstViewController.swift
//  Breakout
//
//  Created by Dmitry Terekhov on 01.08.15.
//  Copyright (c) 2015 Stanford University. All rights reserved.
//

import UIKit

class GameViewController: UIViewController, UICollisionBehaviorDelegate, UIAlertViewDelegate {
    private struct Constants {
        static let PaddleHeight: CGFloat = 10
        static let PaddleBottomIndent: CGFloat = 10
        static let PaddleCornerRadius: CGFloat = 5
        static let PaddleBoundaryIdentifier = "Paddle"
        static let GameViewBoundaryIdentifier = "GameView"
        static let BallSpeed: CGFloat = 0.5
        
        static let PlayImage = UIImage(named: "ico_play")
        static let PauseImage = UIImage(named: "ico_pause")
    }
    
    // MARK: - Members
    @IBOutlet private weak var gameView: BezierPathsView!
    @IBOutlet weak var pauseButton: UIButton!
    
    private lazy var breakoutBehavior: BreakoutBehavior = {
        let breakoutBehavior = BreakoutBehavior()
        breakoutBehavior.ballSpeed = Constants.BallSpeed
        breakoutBehavior.collisionDelegate = self
        breakoutBehavior.ballOutOfGameViewBoundsHandler = {
            self.resetBall()
        }
        return breakoutBehavior
    }()
    
    private lazy var animator: UIDynamicAnimator = {
        let lazilyCreatedDynamicAnimator = UIDynamicAnimator(referenceView: self.gameView)
        lazilyCreatedDynamicAnimator.addBehavior(self.breakoutBehavior)
        return lazilyCreatedDynamicAnimator
    }()
    
    private lazy var paddle: UIView = {
        let paddle = UIView()
        paddle.layer.cornerRadius = Constants.PaddleCornerRadius
        paddle.backgroundColor = UIColor.darkGrayColor()
        self.gameView.addSubview(paddle)
        return paddle
    }()
    
    // Game started when ball pushing
    private var isGameStarted = false
    
    private var isGamePaused: Bool {
        // Pause state:
        // Ball was pushed but ball now not in motion
        return isGameStarted && !breakoutBehavior.isBallInMotion()
    }
    
    private lazy var brickBuilder: BrickBuilder = {
        var brickBuilder = BrickBuilder(parentView: self.gameView, breakoutBehavior: self.breakoutBehavior)
        brickBuilder.allBricksDestroyedHandler = {
            self.allBricksDestroyedHandler()
        }
        return brickBuilder
    }()
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        brickBuilder.buildBricksLevel2()
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "pauseGame", name: UIApplicationWillResignActiveNotification, object: nil)
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        pauseGame()
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIApplicationWillResignActiveNotification, object: nil)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        if !isGameStarted {
            resetGameObjects()
        }
    }
    
    // MARK: - Ball
    private func resetBall() {
        func placeBall(ball: UIView) {
            ball.frame = CGRect(origin: CGPoint(x: gameView.bounds.midX - ballSize.width / 2, y: paddle.frame.origin.y - ballSize.height), size: ballSize)
            ball.layer.cornerRadius = ballSize.width / 2
            animator.updateItemUsingCurrentState(ball)
        }
        
        if let ball = breakoutBehavior.ball {
            placeBall(ball)
        } else {
            let ball = UIView()
            placeBall(ball)
            ball.backgroundColor = UIColor.lightGrayColor()
            breakoutBehavior.addBallBehavior(ball)
        }
        
        isGameStarted = false
    }
    
    // MARK: - Paddle
    private func resetPaddle() {
        paddle.frame = CGRect(origin: CGPoint(x: gameView.bounds.midX - paddleSize.width / 2, y: gameView.bounds.height - paddleSize.height - Constants.PaddleBottomIndent), size: paddleSize)
        refreshBarrierInPaddle()
    }
    
    private func placePaddle(#deltaOriginX: CGFloat) {
        let newPaddleOriginX = paddle.frame.origin.x + deltaOriginX
        let maxPossiblePaddleOriginX = gameView.bounds.maxX - paddleSize.width
        
        // Handle to keep paddle between left and right bounds of gameView
        paddle.frame.origin.x = max(min(newPaddleOriginX, maxPossiblePaddleOriginX), 0.0)
        refreshBarrierInPaddle()
    }
    
    private func refreshBarrierInPaddle() {
        breakoutBehavior.addBarrier(UIBezierPath(ovalInRect: paddle.frame), named: Constants.PaddleBoundaryIdentifier)
    }
    
    // MARK: - UICollisionBehaviorDelegate, collision handlers
    func collisionBehavior(behavior: UICollisionBehavior, beganContactForItem item: UIDynamicItem, withBoundaryIdentifier identifier: NSCopying, atPoint p: CGPoint) {
        if let brickIndex = identifier as? Int {
            handleBrickCollisionActionAtIndex(brickIndex)
        }
    }
    
    private func handleBrickCollisionActionAtIndex(index: Int) {
        if let brick = brickBuilder.bricks[index] {
            switch brick.type {
            case .Normal:
                brickBuilder.destroyBrickAtIndex(index)
            case .SolidBrick:
                // Hack: handle case after little delay to except instant double collision action
                var dispatchTime: dispatch_time_t = dispatch_time(DISPATCH_TIME_NOW, Int64(0.05 * Double(NSEC_PER_SEC)))
                dispatch_after(dispatchTime, dispatch_get_main_queue(), { () -> Void in
                    brick.type = .Normal
                })
            case .ShortPaddleForce:
                brickBuilder.destroyBrickAtIndex(index)
                handleBrickShortPaddleForce()
            }
        }
    }
    
    private func handleBrickShortPaddleForce() {
        paddle.frame.size.width -= paddle.frame.width / 4
        refreshBarrierInPaddle()
    }
    
    // MARK: - Game
    private func allBricksDestroyedHandler() {
        breakoutBehavior.stopBall()
        let alertView = UIAlertView(title: "Congratulations!", message: "You completed level. Play again?", delegate: self, cancelButtonTitle: "Ok")
        alertView.show()
    }
    
    private func resetGameObjects() {
        addGameViewBarriers()
        brickBuilder.placeBricks()
        resetPaddle()
        resetBall()
    }
    
    @objc private func pauseGame() -> Bool {
        if breakoutBehavior.isBallInMotion() {
            breakoutBehavior.stopBall()
            pauseButton.setImage(Constants.PlayImage, forState: UIControlState.Normal)
            return true
        }
        return false
    }
    
    private func continueGame() {
        breakoutBehavior.continueBall()
        pauseButton.setImage(Constants.PauseImage, forState: UIControlState.Normal)
    }
    
    // MARK: - UIAlertViewDelegate
    func alertView(alertView: UIAlertView, clickedButtonAtIndex buttonIndex: Int) {
        brickBuilder.buildBricksLevel2()
        resetGameObjects()
    }
    
    // MARK: - User interaction
    @IBAction private func gameViewTap(gesture: UITapGestureRecognizer) {
        // On pause can't push the ball
        if isGamePaused {
            continueGame()
        } else {
            breakoutBehavior.pushBall()
            isGameStarted = true
        }
    }
    
    @IBAction private func gameViewSwipe(gesture: UIPanGestureRecognizer) {
        if isGamePaused { return } // On pause can't move the paddle
        if gesture.state == .Changed {
            placePaddle(deltaOriginX: gesture.translationInView(gameView).x)
            gesture.setTranslation(CGPointZero, inView: gameView)
        }
    }
    
    @IBAction private func pauseButtonTap() {
        // Pause or resume the game
        if !pauseGame() {
            continueGame()
        }
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
    
    private func addGameViewBarriers() {
        var rect = gameView.bounds;
        rect.size.height *= 2
        breakoutBehavior.addBarrier(UIBezierPath(rect: rect), named: Constants.GameViewBoundaryIdentifier)
    }
}