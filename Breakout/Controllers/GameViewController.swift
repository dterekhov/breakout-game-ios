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
        static let BallSize = CGSize(width: 32, height: 32)
        static let BallSpeedDifficultyEasy: CGFloat = 0.3
        static let BallSpeedDifficultyHard: CGFloat = 0.5
        static let GameView4InchScreenHeight: CGFloat = 519
        static let LivesDifficultyEasyCount = 5
        static let LivesDifficultyHardCount = 3
        static let ParallaxOffset = 50
        static let ComboBrickCollisionBonusPointsDifficultyEasy = 2
        static let ComboBrickCollisionBonusPointsDifficultyHard = 3
        static let ComboLabelIPadFontSize: CGFloat = 80
        
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
    
    private struct Localized {
        static let PlayerScoreString = NSLocalizedString("PlayerScore", comment: "")
        static let PointsString = NSLocalizedString("Points", comment: "")
        static let OkString = NSLocalizedString("Ok", comment: "")
    }
    
    enum GameLevel {
        case GameLevelFirst
        case GameLevelCurrent
        case GameLevelNext
    }
    
    // MARK: - Members
    @IBOutlet private weak var gameView: BezierPathsView!
    @IBOutlet weak var settingsButton: UIButton!
    @IBOutlet weak var pauseButton: UIButton!
    @IBOutlet weak var livesLabel: UILabel!
    @IBOutlet weak var scoreLabel: UILabel!
    @IBOutlet weak var comboLabel: UILabel!
    @IBOutlet weak var backgroundImageView: UIImageView!
    
    private lazy var breakoutBehavior: BreakoutBehavior = {
        let lazilyCreatedBreakoutBehavior = BreakoutBehavior()
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
            livesLabel.text = NSLocalizedString("BallsCapital", comment: "") + ": " + livesString
            
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
            scoreLabel.text = "\(score) " + NSLocalizedString("PointsCapital", comment: "")
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
        
        if BreakoutUIHelper.isIPad {
            tabBarController?.tabBar.hidden = true
            comboLabel.font = UIFont.systemFontOfSize(Constants.ComboLabelIPadFontSize)
        } else {
            settingsButton.hidden = true
        }
        
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
            refreshSpeedInBallBehavior()
            resetGameObjects()
        }
    }
    
    // MARK: - Notification handlers
    @objc private func ballRotationDidChanged() {
        breakoutBehavior.allowBallRotation = Settings.ballRotation
    }
    
    @objc private func difficultyHardDidChanged() {
        fullLivesCount = Settings.difficultyHard ? Constants.LivesDifficultyHardCount : Constants.LivesDifficultyEasyCount
        refreshSpeedInBallBehavior()
        comboBrickCollisionBonusPoints = Settings.difficultyHard ? Constants.ComboBrickCollisionBonusPointsDifficultyHard : Constants.ComboBrickCollisionBonusPointsDifficultyEasy
        newGame()
    }
    
    // MARK: - Ball
    private func resetBall() {
        let ball = UIImageView(frame: CGRect(origin: CGPoint(x: gameView.bounds.midX - Constants.BallSize.width / 2, y: paddle.frame.origin.y - Constants.BallSize.height), size: Constants.BallSize))
        ball.layer.cornerRadius = Constants.BallSize.width / 2
        ball.image = Constants.BallImage
        breakoutBehavior.addBallBehavior(ball)
        
        isGameStarted = false
    }
    
    private func refreshSpeedInBallBehavior() {
        let ballSpeed = Settings.difficultyHard ? Constants.BallSpeedDifficultyHard : Constants.BallSpeedDifficultyEasy
        let speedCoefficient = gameView.bounds.height / Constants.GameView4InchScreenHeight
        breakoutBehavior.ballSpeed = ballSpeed * speedCoefficient
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
            comboBrickCollisionsCount++ // Several collisions in sequence
            handleBrickCollisionActionAtIndex(brickIndex)
        } else if identifier as? String == Constants.PaddleBoundaryIdentifier {
            comboBrickCollisionsCount = 0
        }
    }
    
    private func handleBrickCollisionActionAtIndex(index: Int) {
        if let brick = brickBuilder.bricks[index] {
            // Second collision and further give you more points
            let test1 = comboBrickCollisionsCount > 1 ? comboBrickCollisionBonusPoints : 1
            score += test1
            
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
        
        let playerSetNewScoreRecordString = score > Settings.scoreBest && Settings.scoreBest > 0 && !isPlayerLose ? "\n+" + NSLocalizedString("PlayerSetNewScoreRecord", comment: "") : ""
        let congratulationsString = NSLocalizedString("Congratulations", comment: "")
        let playerCompleteLevelString = NSLocalizedString("PlayerCompleteLevel", comment: "")
        let savedLivesString = NSLocalizedString("SavedLives", comment: "")
        
        let alertView = UIAlertView(title: congratulationsString, message: playerCompleteLevelString + "\n\n" + Localized.PlayerScoreString + ": \(score) " + Localized.PointsString + "\n+\(livesCount) " + savedLivesString + playerSetNewScoreRecordString, delegate: self, cancelButtonTitle: Localized.OkString)
        alertView.show()
    }
    
    private func gameLoseAlert() {
        breakoutBehavior.stopBall()
        
        let playerLoseString = NSLocalizedString("PlayerLose", comment: "")
        let tryAgainString = NSLocalizedString("TryAgain", comment: "")
        
        let alertView = UIAlertView(title: playerLoseString, message: Localized.PlayerScoreString + ": \(score) " + Localized.PointsString + "\n\n" + tryAgainString, delegate: self, cancelButtonTitle: Localized.OkString)
        alertView.show()
    }
    
    private func resetGameObjects() {
        pauseButton.setImage(Constants.PauseImage, forState: UIControlState.Normal)
        addGameViewBarriers()
        brickBuilder.placeBricks()
        resetPaddle()
        resetBall()
    }
    
    func newGame(gameLevel: GameLevel = .GameLevelCurrent) {
        switch gameLevel {
        case .GameLevelFirst:
            brickBuilder.buildBricksForFirstLevel()
        case .GameLevelCurrent:
            brickBuilder.buildBricks()
        case .GameLevelNext:
            brickBuilder.buildBricksForNextLevel()
        }
        
        // Save last score
        if score > 0 {
            Settings.isPlayerWithLastScoreWin = !isPlayerLose
            Settings.scoreLast = score
            
            // Save best score
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
        newGame(gameLevel: isPlayerLose ? .GameLevelCurrent : .GameLevelNext)
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
    
    @IBAction func settingsButtonTap() {
        pauseGame()
    }

    // MARK: - Helpers
    private var paddleSize: CGSize {
        let width = gameView.bounds.size.width / 5
        return CGSize(width: width, height: Constants.PaddleHeight)
    }
    
    private func addGameViewBarriers() {
        var rect = gameView.bounds;
        rect.size.height *= 2
        breakoutBehavior.addBarrier(UIBezierPath(rect: rect), named: Constants.GameViewBoundaryIdentifier)
    }
}