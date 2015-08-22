//
//  SecondViewController.swift
//  Breakout
//
//  Created by Dmitry Terekhov on 01.08.15.
//  Copyright (c) 2015 Stanford University. All rights reserved.
//

import UIKit

class SettingsViewController: UITableViewController, UIActionSheetDelegate {
    private struct Constants {
        static let ActionSheetTagStartNewGame = 1
        static let ActionSheetTagResetSettings = 2
        static let CancelString = NSLocalizedString("Cancel", comment: "")
    }
    
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
        let winningString = NSLocalizedString("Winning", comment: "")
        let losingString = NSLocalizedString("Losing", comment: "")
        let lastResultString = NSLocalizedString("LastResult", comment: "")
        
        let winningStatus = String(format: " (%@)", Settings.isPlayerWithLastScoreWin ? winningString : losingString)
        lastResultLabel.text = lastResultString + winningStatus
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
        let startNewGameString = NSLocalizedString("StartNewGame", comment: "")
        let startString = NSLocalizedString("Start", comment: "")
        let actionSheet = UIActionSheet(title: startNewGameString, delegate: self, cancelButtonTitle: Constants.CancelString, destructiveButtonTitle: nil, otherButtonTitles: startString)
        actionSheet.tag = Constants.ActionSheetTagStartNewGame
        actionSheet.showInView(view)
    }
    
    @IBAction func resetSettingsButtonTap() {
        let resetSettingsString = NSLocalizedString("ResetSettings", comment: "")
        let resetString = NSLocalizedString("Reset", comment: "")
        let actionSheet = UIActionSheet(title: resetSettingsString, delegate: self, cancelButtonTitle: Constants.CancelString, destructiveButtonTitle: resetString)
        actionSheet.tag = Constants.ActionSheetTagResetSettings
        actionSheet.showInView(view)
    }
    
    // MARK: - Helpers
    private func refreshUI() {
        ballRotationSwitch.on = Settings.ballRotation
        ballGravitySwitch.on = Settings.ballGravity
        difficultySegmentedControl.selectedSegmentIndex = Settings.difficultyHard ? 1 : 0
        scoreBestLabel.text = "\(Settings.scoreBest)"
        scoreLastLabel.text = "\(Settings.scoreLast)"
        refreshLastResultLabel()
    }
    
    // MARK: - UIActionSheetDelegate
    func actionSheet(actionSheet: UIActionSheet, clickedButtonAtIndex buttonIndex: Int) {
        if actionSheet.tag == Constants.ActionSheetTagStartNewGame && buttonIndex == 1 {
            gameViewController?.newGame(gameLevel: .GameLevelFirst)
            self.tabBarController?.selectedIndex = 0
        } else if actionSheet.tag == Constants.ActionSheetTagResetSettings && buttonIndex == 0 {
            Settings.resetToDefaults()
            refreshUI()
        }
    }
}