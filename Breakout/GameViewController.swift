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
        static let PaddleBottomIndent: CGFloat = 75
        static let PaddleCornerRadius: CGFloat = 5
        static let PaddleBoundaryIdentifier = "Paddle"
        static let GameViewBoundaryIdentifier = "GameView"
        static let BallSpeed: CGFloat = 0.5
        static let LivesCount = 3
        static let ParallaxOffset = 50
        
        static let PlayImage = UIImage(named: "ico_play")
        static let PauseImage = UIImage(named: "ico_pause")
    }
    
    // MARK: - Members
    @IBOutlet private weak var gameView: BezierPathsView!
    @IBOutlet weak var pauseButton: UIButton!
    @IBOutlet weak var livesLabel: UILabel!
    @IBOutlet weak var scoreLabel: UILabel!
    @IBOutlet weak var comboLabel: UILabel!
    @IBOutlet weak var backgroundImageView: UIImageView!
    
    private lazy var breakoutBehavior: BreakoutBehavior = {
        let breakoutBehavior = BreakoutBehavior()
        breakoutBehavior.ballSpeed = Constants.BallSpeed
        breakoutBehavior.collisionDelegate = self
        breakoutBehavior.ballOutOfGameViewBoundsHandler = {
            self.livesCount--
            if self.livesCount > 0 {
                self.resetBall()
            }
        }
        
        self.animator = UIDynamicAnimator(referenceView: self.gameView)
        self.animator!.addBehavior(breakoutBehavior)
        
        return breakoutBehavior
    }()
    
    var animator: UIDynamicAnimator?
    
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
            self.score += self.livesCount // Score for saved lives
            self.completeLevelAlert()
        }
        return brickBuilder
    }()
    
    var livesCount = 0 {
        didSet {
            // Refresh livesLabel
            var livesString = ""
            while count(livesString) != livesCount {
                livesString += "⦁"
            }
            livesLabel.text = "BALLS: " + livesString
            
            // Player lose handler
            if isPlayerLose {
                gameLoseAlert()
            }
        }
    }
    
    var isPlayerLose: Bool {
        return livesCount == 0
    }
    
    var score = 0 {
        didSet {
            scoreLabel.text = "\(score) POINTS"
        }
    }
    
    var comboBrickCollisionsCount = 0 {
        didSet {
            if comboBrickCollisionsCount > 1 {
                showComboLabel()
            }
        }
    }
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        addParallaxEffect(backgroundImageView, offset: Constants.ParallaxOffset)
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "pauseGame", name: UIApplicationWillResignActiveNotification, object: nil)
        
        newGame()
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        breakoutBehavior.gravityOn = false
        pauseGame()
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
//        breakoutBehavior.gravityOn = true
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIApplicationWillResignActiveNotification, object: nil)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        if !isGameStarted && livesCount > 0 {
            resetGameObjects()
        }
    }
    
    // MARK: - Ball
    private func resetBall() {
        let ball = UIView()
        ball.frame = CGRect(origin: CGPoint(x: gameView.bounds.midX - ballSize.width / 2, y: paddle.frame.origin.y - ballSize.height), size: ballSize)
        ball.layer.cornerRadius = ballSize.width / 2
        ball.backgroundColor = UIColor.lightGrayColor()
        breakoutBehavior.addBallBehavior(ball)
        
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
            comboBrickCollisionsCount++ // Several collisions in sequence
            handleBrickCollisionActionAtIndex(brickIndex)
        } else if identifier as? String == Constants.PaddleBoundaryIdentifier {
            comboBrickCollisionsCount = 0
        }
    }
    
    private func handleBrickCollisionActionAtIndex(index: Int) {
        if let brick = brickBuilder.bricks[index] {
            // Second collision and further give you 2 points instead 1 point
            score += comboBrickCollisionsCount > 1 ? 2 : 1
            
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
    @objc private func pauseGame() {
        if breakoutBehavior.isBallInMotion() {
            breakoutBehavior.stopBall()
            pauseButton.setImage(Constants.PlayImage, forState: UIControlState.Normal)
        }
    }
    
    private func continueGame() {
        breakoutBehavior.continueBall()
        pauseButton.setImage(Constants.PauseImage, forState: UIControlState.Normal)
    }
    
    private func completeLevelAlert() {
        breakoutBehavior.stopBall()
        let alertView = UIAlertView(title: "Congratulations!", message: "You complete a level\n\nYour score: \(score) points\n+\(livesCount) saved lives", delegate: self, cancelButtonTitle: "Ok")
        alertView.show()
    }
    
    private func gameLoseAlert() {
        breakoutBehavior.stopBall()
        let alertView = UIAlertView(title: "You lose", message: "Your score: \(score) points\n\nTry again?", delegate: self, cancelButtonTitle: "Ok")
        alertView.show()
    }
    
    private func resetGameObjects() {
        addGameViewBarriers()
        brickBuilder.placeBricks()
        resetPaddle()
        resetBall()
    }
    
    private func newGame() {
        if isPlayerLose {
            brickBuilder.buildBricks()
        } else {
            brickBuilder.buildBricksForNextLevel()
        }
        livesCount = Constants.LivesCount
        score = 0
        resetGameObjects()
    }
    
    // MARK: - UIAlertViewDelegate
    func alertView(alertView: UIAlertView, clickedButtonAtIndex buttonIndex: Int) {
        newGame()
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
        if breakoutBehavior.isBallInMotion() {
            pauseGame()
        } else {
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
    
    private func showComboLabel() {
        UIView.animateWithDuration(1.0, animations: { () -> Void in
            self.comboLabel.alpha = 1.0
        }) { (finished) -> Void in
            UIView.animateWithDuration(0.2, animations: { () -> Void in
                self.comboLabel.alpha = 0.0
            })
        }
    }
    
    private func addParallaxEffect(backgroundView: UIView, offset: Int) {
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
}