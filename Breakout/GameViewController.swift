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
        static let BallSpeedDifficultyEasy: CGFloat = 0.3
        static let BallSpeedDifficultyHard: CGFloat = 0.5
        static let LivesDifficultyEasyCount = 5
        static let LivesDifficultyHardCount = 3
        static let ParallaxOffset = 50
        static let ComboBrickCollisionBonusPointsDifficultyEasy = 1
        static let ComboBrickCollisionBonusPointsDifficultyHard = 2
        
        static let PaddleGradientColors = [
            UIColor(red:0.74, green:0.74, blue:0.76, alpha:1).CGColor,
            UIColor(red:0.9, green:0.9, blue:0.9, alpha:1).CGColor,
            UIColor(red:0.34, green:0.34, blue:0.34, alpha:1).CGColor
        ]
        static let PaddleGradientStops = [0.0, 0.2, 0.6, 1.0]
        
        static let PlayImage = UIImage(named: "ico_play")
        static let PauseImage = UIImage(named: "ico_pause")
        static let BallImage = UIImage(named: "img_ball")
    }
    
    // MARK: - Members
    @IBOutlet private weak var gameView: BezierPathsView!
    @IBOutlet weak var pauseButton: UIButton!
    @IBOutlet weak var livesLabel: UILabel!
    @IBOutlet weak var scoreLabel: UILabel!
    @IBOutlet weak var comboLabel: UILabel!
    @IBOutlet weak var backgroundImageView: UIImageView!
    
    private lazy var breakoutBehavior: BreakoutBehavior = {
        let lazilyCreatedBreakoutBehavior = BreakoutBehavior()
        lazilyCreatedBreakoutBehavior.ballSpeed = Settings.difficultyHard ? Constants.BallSpeedDifficultyHard : Constants.BallSpeedDifficultyEasy
        lazilyCreatedBreakoutBehavior.allowBallRotation = Settings.ballRotation
        lazilyCreatedBreakoutBehavior.collisionDelegate = self
        lazilyCreatedBreakoutBehavior.ballOutOfGameViewBoundsHandler = { [weak lazilyCreatedBreakoutBehavior] in
            lazilyCreatedBreakoutBehavior!.allowBallGravity = false
            self.livesCount--
            if self.livesCount > 0 {
                self.resetBall()
            }
        }
        
        self.animator = UIDynamicAnimator(referenceView: self.gameView)
        self.animator!.addBehavior(lazilyCreatedBreakoutBehavior)
        
        return lazilyCreatedBreakoutBehavior
    }()
    
    var animator: UIDynamicAnimator?
    
    private lazy var paddle: UIView = {
        let lazilyCreatedPaddle = UIView()
        self.gameView.addSubview(lazilyCreatedPaddle)
        return lazilyCreatedPaddle
    }()
    
    // Game started when ball pushing
    private var isGameStarted = false
    
    private var isGamePaused: Bool {
        // Pause state:
        // Ball was pushed but ball now not in motion
        return isGameStarted && !breakoutBehavior.isBallInMotion()
    }
    
    private lazy var brickBuilder: BrickBuilder = {
        var lazilyCreatedBrickBuilder = BrickBuilder(parentView: self.gameView, breakoutBehavior: self.breakoutBehavior)
        lazilyCreatedBrickBuilder.allBricksDestroyedHandler = {
            self.score += self.livesCount // Score for saved lives
            self.completeLevelAlert()
        }
        return lazilyCreatedBrickBuilder
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
    
    var fullLivesCount = Settings.difficultyHard ? Constants.LivesDifficultyHardCount : Constants.LivesDifficultyEasyCount
    
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
                BreakoutUIHelper.fadeInOutAnimation(comboLabel)
            }
        }
    }
    
    var comboBrickCollisionBonusPoints = Settings.difficultyHard ? Constants.ComboBrickCollisionBonusPointsDifficultyHard : Constants.ComboBrickCollisionBonusPointsDifficultyEasy
    
    private let notificationCenter = NSNotificationCenter.defaultCenter()
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tabBarController?.viewControllers?.first as? SettingsViewController
        BreakoutUIHelper.addParallaxEffect(backgroundImageView, offset: Constants.ParallaxOffset)
        
        notificationCenter.addObserver(self, selector: "pauseGame", name: UIApplicationWillResignActiveNotification, object: nil)
        notificationCenter.addObserver(self, selector: "ballRotationDidChanged", name: Settings.BallRotationDidChangedNotification, object: nil)
        notificationCenter.addObserver(self, selector: "difficultyHardDidChanged", name: Settings.DifficultyHardDidChangedNotification, object: nil)
        
        newGame()
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        pauseGame()
    }
    
    deinit {
        notificationCenter.removeObserver(self)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        if !isGameStarted && livesCount > 0 {
            resetGameObjects()
        }
    }
    
    // MARK: - Notification handlers
    @objc private func ballRotationDidChanged() {
        breakoutBehavior.allowBallRotation = Settings.ballRotation
    }
    
    @objc private func difficultyHardDidChanged() {
        fullLivesCount = Settings.difficultyHard ? Constants.LivesDifficultyHardCount : Constants.LivesDifficultyEasyCount
        breakoutBehavior.ballSpeed = Settings.difficultyHard ? Constants.BallSpeedDifficultyHard : Constants.BallSpeedDifficultyEasy
        comboBrickCollisionBonusPoints = Settings.difficultyHard ? Constants.ComboBrickCollisionBonusPointsDifficultyHard : Constants.ComboBrickCollisionBonusPointsDifficultyEasy
        newGame()
    }
    
    // MARK: - Ball
    private func resetBall() {
        let ball = UIImageView()
        ball.frame = CGRect(origin: CGPoint(x: gameView.bounds.midX - ballSize.width / 2, y: paddle.frame.origin.y - ballSize.height), size: ballSize)
        ball.layer.cornerRadius = ballSize.width / 2
        ball.image = Constants.BallImage
        breakoutBehavior.addBallBehavior(ball)
        
        isGameStarted = false
    }
    
    // MARK: - Paddle
    private func resetPaddle() {
        paddle.frame = CGRect(origin: CGPoint(x: gameView.bounds.midX - paddleSize.width / 2, y: gameView.bounds.height - paddleSize.height - Constants.PaddleBottomIndent), size: paddleSize)
        
        BreakoutUIHelper.addGradientColors(paddle, cornerRadius: Constants.PaddleCornerRadius, gradientColors: Constants.PaddleGradientColors, gradientStops: Constants.PaddleGradientStops)
        
        refreshBarrierInPaddle()
    }
    
    private func placePaddle(#deltaOriginX: CGFloat) {
        let newPaddleOriginX = paddle.frame.origin.x + deltaOriginX
        let maxPossiblePaddleOriginX = gameView.bounds.maxX - paddle.frame.width
        
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
            comboBrickCollisionsCount += comboBrickCollisionBonusPoints // Several collisions in sequence
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
        BreakoutUIHelper.addGradientColors(paddle, cornerRadius: Constants.PaddleCornerRadius, gradientColors: Constants.PaddleGradientColors, gradientStops: Constants.PaddleGradientStops)
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
        breakoutBehavior.allowBallGravity = Settings.ballGravity
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
        pauseButton.setImage(Constants.PauseImage, forState: UIControlState.Normal)
        addGameViewBarriers()
        brickBuilder.placeBricks()
        resetPaddle()
        resetBall()
    }
    
    private func newGame(nextLevel: Bool = false) {
        if nextLevel {
            brickBuilder.buildBricksForNextLevel()
        } else {
            brickBuilder.buildBricks()
        }
        
        // Save score
        if score > 0 {
            Settings.scoreLast = score
            
            if Settings.scoreLast > Settings.scoreBest && !isPlayerLose {
                Settings.scoreBest = Settings.scoreLast
            }
        }
        
        // Reset
        score = 0
        livesCount = fullLivesCount
        resetGameObjects()
    }
    
    // MARK: - UIAlertViewDelegate
    func alertView(alertView: UIAlertView, clickedButtonAtIndex buttonIndex: Int) {
        newGame(nextLevel: !isPlayerLose)
    }
    
    // MARK: - User interaction
    @IBAction private func gameViewTap(gesture: UITapGestureRecognizer) {
        // On pause can't push the ball
        if isGamePaused {
            continueGame()
        } else {
            breakoutBehavior.pushBall()
            breakoutBehavior.allowBallGravity = Settings.ballGravity
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
}