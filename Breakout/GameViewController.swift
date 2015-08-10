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
        static let BrickRowsCount = 1//3
        static let BrickColumnsCount = 1//5
        static let BrickInteritemSpacing: CGFloat = 4
        static let BrickHeight: CGFloat = 30
    }
    
    private struct Brick {
        var view: UIView
    }
    
    // MARK: - Members
    @IBOutlet private weak var gameView: BezierPathsView!
    
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
    
    private var ball: UIView?
    
    private lazy var paddle: UIView = {
        let paddle = UIView()
        paddle.layer.cornerRadius = Constants.PaddleCornerRadius
        paddle.backgroundColor = UIColor.darkGrayColor()
        self.gameView.addSubview(paddle)
        return paddle
    }()
    
    private var bricks = [Int:Brick]()
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        animator.addBehavior(breakoutBehavior)
        createBricks()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        resetGameState()
    }
    
    // MARK: - Gestures
    @IBAction private func gameViewTap(gesture: UITapGestureRecognizer) {
        breakoutBehavior.pushBall()
    }
    
    @IBAction private func gameViewSwipe(gesture: UIPanGestureRecognizer) {
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
    
    // MARK: - UIAlertViewDelegate
    func alertView(alertView: UIAlertView, clickedButtonAtIndex buttonIndex: Int) {
        createBricks()
        resetGameState()
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