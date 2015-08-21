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
    
    private lazy var brickBuilder: BrickBuilder? = {
        if let lazilyCreatedBrickBuilder = (self.tabBarController?.viewControllers?.first as? SettingsViewController)?.brickBuilder {
            return lazilyCreatedBrickBuilder
        }
        return nil
    }()
    
    private let notificationCenter = NSNotificationCenter.defaultCenter()
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        notificationCenter.addObserver(self, selector: "scoreBestDidChanged", name: Settings.ScoreBestDidChangedNotification, object: nil)
        notificationCenter.addObserver(self, selector: "scoreLastDidChanged", name: Settings.ScoreLastDidChangedNotification, object: nil)
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
    
    // MARK: - User interaction
    @IBAction func ballRotationValueChanged() {
        Settings.ballRotation = !Settings.ballRotation
    }
    
    @IBAction func ballGravityValueChanged() {
        Settings.ballGravity = !Settings.ballGravity
    }
    
    @IBAction func DifficultyValueChanged() {
        Settings.difficultyHard = !Settings.difficultyHard
    }
    
    @IBAction func simpleBricksButtonTap() {
        brickBuilder?.buildBricksForFirstLevel()
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
    }
}