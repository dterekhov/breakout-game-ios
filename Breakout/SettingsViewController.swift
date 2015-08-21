//
//  SecondViewController.swift
//  Breakout
//
//  Created by Dmitry Terekhov on 01.08.15.
//  Copyright (c) 2015 Stanford University. All rights reserved.
//

import UIKit

class SettingsViewController: UITableViewController {
    // MARK: - Members
    @IBOutlet weak var ballRotationSwitch: UISwitch!
    @IBOutlet weak var ballGravitySwitch: UISwitch!
    @IBOutlet weak var difficultySegmentedControl: UISegmentedControl!
    @IBOutlet weak var scoreBestLabel: UILabel!
    @IBOutlet weak var scoreLastLabel: UILabel!
    @IBOutlet weak var lastResultLabel: UILabel!
    
    private var gameViewController: GameViewController? {
        return self.tabBarController?.viewControllers?.first as? GameViewController
    }
    
    private let notificationCenter = NSNotificationCenter.defaultCenter()
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if !AppDelegate.Motion.Manager.accelerometerAvailable {
            ballGravitySwitch.enabled = false
        }
        
        notificationCenter.addObserver(self, selector: "scoreBestDidChanged", name: Settings.ScoreBestDidChangedNotification, object: nil)
        notificationCenter.addObserver(self, selector: "scoreLastDidChanged", name: Settings.ScoreLastDidChangedNotification, object: nil)
        notificationCenter.addObserver(self, selector: "isPlayerWithLastScoreWinDidChanged", name: Settings.IsPlayerWithLastScoreWinDidChangedNotification, object: nil)
    }
    
    deinit {
        notificationCenter.removeObserver(self)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        refreshUI()
    }
    
    // MARK: - Notification handlers
    @objc private func scoreBestDidChanged() {
        scoreBestLabel.text = "\(Settings.scoreBest)"
    }
    
    @objc private func scoreLastDidChanged() {
        scoreLastLabel.text = "\(Settings.scoreLast)"
    }
    
    @objc private func isPlayerWithLastScoreWinDidChanged() {
        refreshLastResultLabel()
    }
    
    private func refreshLastResultLabel() {
        let winningStatus = String(format: " (%@)", Settings.isPlayerWithLastScoreWin ? "winning" : "losing")
        lastResultLabel.text = "Last result" + winningStatus
    }
    
    // MARK: - User interaction
    @IBAction func ballRotationValueChanged() {
        Settings.ballRotation = !Settings.ballRotation
    }
    
    @IBAction func ballGravityValueChanged() {
        Settings.ballGravity = !Settings.ballGravity
    }
    
    @IBAction func difficultyValueChanged() {
        Settings.difficultyHard = !Settings.difficultyHard
    }
    
    @IBAction func startNewGameButtonTap() {
        gameViewController?.newGame(gameLevel: .GameLevelFirst)
    }
    
    @IBAction func resetSettingsButtonTap() {
        Settings.resetToDefaults()
        refreshUI()
    }
    
    private func refreshUI() {
        ballRotationSwitch.on = Settings.ballRotation
        ballGravitySwitch.on = Settings.ballGravity
        difficultySegmentedControl.selectedSegmentIndex = Settings.difficultyHard ? 1 : 0
        scoreBestLabel.text = "\(Settings.scoreBest)"
        scoreLastLabel.text = "\(Settings.scoreLast)"
        refreshLastResultLabel()
    }
}