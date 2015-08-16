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
        static let BrickRowsCount = 3//3
        static let BrickColumnsCount = 5//5
        static let BrickInteritemSpacing: CGFloat = 4
        static let BrickHeight: CGFloat = 30
        
        static let PlayImage = UIImage(named: "ico_play")
        static let PauseImage = UIImage(named: "ico_pause")
    }
    
    private struct Brick {
        var view: UIView
    }
    
    private struct GameState {
        var paddleOriginY: CGFloat
        var ballSpeed: CGFloat
        var ballLinearVelocityX: CGFloat
        var ballLinearVelocityY: CGFloat
        var ballOriginX: CGFloat
        var ballOriginY: CGFloat
        var remainingBricks: [Int]
    }
    
    // MARK: - Members
    @IBOutlet private weak var gameView: BezierPathsView!
    @IBOutlet weak var pauseButton: UIButton!
    
    private lazy var breakoutBehavior: BreakoutBehavior = {
        let breakoutBehavior = BreakoutBehavior()
        breakoutBehavior.collisionDelegate = self
        breakoutBehavior.ballOutOfGameViewBoundsHandler = {
            self.resetBall()
        }
        return breakoutBehavior
    }()
    
    private lazy var animator: UIDynamicAnimator = {
        let lazilyCreatedDynamicAnimator = UIDynamicAnimator(referenceView: self.gameView)
        return lazilyCreatedDynamicAnimator
    }()
    
    private lazy var paddle: UIView = {
        let paddle = UIView()
        paddle.layer.cornerRadius = Constants.PaddleCornerRadius
        paddle.backgroundColor = UIColor.darkGrayColor()
        self.gameView.addSubview(paddle)
        return paddle
    }()
    
    private var bricks = [Int:Brick]()
    
    private var currentGameState: GameState {
        get {
            var currentGameState = GameState(
                paddleOriginY: paddle.frame.origin.y,
                ballSpeed: BreakoutBehavior.Constants.BallSpeed,
                ballLinearVelocityX: breakoutBehavior.ballLinearVelocity.x,
                ballLinearVelocityY: breakoutBehavior.ballLinearVelocity.y,
                ballOriginX: breakoutBehavior.ball?.frame.origin.x ?? 0,
                ballOriginY: breakoutBehavior.ball?.frame.origin.y ?? 0,
                remainingBricks: bricks.keys.array)
            return currentGameState
        }
    }
    
    // Game started when ball pushing
    private var isGameStarted = false
    
    private var isGamePaused: Bool {
        // Pause state:
        // Ball was pushed but ball now not in motion
        return isGameStarted && !breakoutBehavior.isBallInMotion()
    }
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        animator.addBehavior(breakoutBehavior)
        createBricks()
        
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
            resetGameState()
        }
    }
    
    // MARK: - Gestures
    @IBAction private func gameViewTap(gesture: UITapGestureRecognizer) {
        if isGamePaused { return } // On pause can't push the ball
        breakoutBehavior.pushBall()
        isGameStarted = true
    }
    
    @IBAction private func gameViewSwipe(gesture: UIPanGestureRecognizer) {
        if isGamePaused { return } // On pause can't move the paddle
        if gesture.state == .Changed {
            placePaddle(deltaOriginX: gesture.translationInView(gameView).x)
            gesture.setTranslation(CGPointZero, inView: gameView)
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
        breakoutBehavior.addBarrier(UIBezierPath(roundedRect: paddle.frame, cornerRadius: Constants.PaddleCornerRadius), named: Constants.PaddleBoundaryIdentifier)
    }
    
    // MARK: - Bricks
    private func createBricks() {
        for index in 1...Constants.BrickRowsCount * Constants.BrickColumnsCount {
            var brickView = UIView()
            brickView.backgroundColor = UIColor.brownColor()
            gameView.addSubview(brickView)
            bricks[index] = Brick(view: brickView)
        }
    }
    
    private func placeBricks() {
        let totalSpaceItemsWidth = CGFloat(Constants.BrickColumnsCount + 1) * Constants.BrickInteritemSpacing
        let brickWidth = (gameView.bounds.width - totalSpaceItemsWidth) / CGFloat(Constants.BrickColumnsCount)
        let brickSize = CGSize(width: brickWidth, height: Constants.BrickHeight)
        
        var origin = CGPoint(x: Constants.BrickInteritemSpacing, y: Constants.BrickInteritemSpacing)
        for row in 1...Constants.BrickRowsCount {
            for column in 1...Constants.BrickColumnsCount {
                let index = (row - 1) * Constants.BrickColumnsCount + column
                if let brick = bricks[index] {
                    brick.view.frame = CGRect(origin: origin, size: brickSize)
                    addBrickBarrier(brick.view, index: index)
                }
                origin.x += brickWidth + Constants.BrickInteritemSpacing
            }
            origin = CGPoint(x: Constants.BrickInteritemSpacing, y: origin.y + Constants.BrickHeight + Constants.BrickInteritemSpacing)
        }
    }
    
    private func addBrickBarrier(brickView: UIView, index: Int) {
        breakoutBehavior.addBarrier(UIBezierPath(rect: brickView.frame), named: index)
    }
    
    private func destroyBrickAtIndex(index: Int) {
        self.breakoutBehavior.removeBarrier(index)
        
        if let brickView = bricks[index]?.view {
            UIView.transitionWithView(brickView, duration:1.0, options: UIViewAnimationOptions.TransitionFlipFromTop, animations: { () -> Void in
                brickView.alpha = 0.5
                }, completion: {
                    (success) -> Void in
                    brickView.removeFromSuperview()
                    self.bricks[index] = nil
                    
                    if self.bricks.count == 0 {
                        self.allBricksDestroyedHandler()
                    }
            })
        }
    }
    
    // MARK: - UICollisionBehaviorDelegate
    func collisionBehavior(behavior: UICollisionBehavior, beganContactForItem item: UIDynamicItem, withBoundaryIdentifier identifier: NSCopying, atPoint p: CGPoint) {
        if let brickIndex = identifier as? Int {
            destroyBrickAtIndex(brickIndex)
        }
    }
    
    // MARK: - Game
    private func allBricksDestroyedHandler() {
        breakoutBehavior.stopBall()
        let alertView = UIAlertView(title: "Congratulations!", message: "You completed level. Play again?", delegate: self, cancelButtonTitle: "Ok")
        alertView.show()
    }
    
    private func resetGameState() {
        addGameViewBarriers()
        placeBricks()
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
    
    // MARK: - UIAlertViewDelegate
    func alertView(alertView: UIAlertView, clickedButtonAtIndex buttonIndex: Int) {
        createBricks()
        resetGameState()
    }
    
    // MARK: - User interaction
    @IBAction private func pauseButtonTap() {
        // Pause or resume the game
        if !pauseGame() {
            breakoutBehavior.continueBall()
            pauseButton.setImage(Constants.PauseImage, forState: UIControlState.Normal)
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