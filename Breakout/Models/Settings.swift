//
//  Settings.swift
//  Breakout
//
//  Created by Dmitry Terekhov on 21.08.15.
//  Copyright (c) 2015 Stanford University. All rights reserved.
//

import UIKit

class Settings {
    private struct UDKeys {
        static let BallRotation = "BallRotation"
        static let BallGravity = "BallGravity"
        static let DifficultyHard = "DifficultyHard"
        static let ScoreBest = "ScoreBest"
        static let ScoreLast = "ScoreLast"
        static let IsPlayerWithLastScoreWin = "IsPlayerWithLastScoreWin"
    }
    
    static let BallRotationDidChangedNotification = "BallRotationDidChangedNotification"
    static let BallGravityDidChangedNotification = "BallGravityDidChangedNotification"
    static let DifficultyHardDidChangedNotification = "DifficultyHardDidChangedNotification"
    static let ScoreBestDidChangedNotification = "ScoreBestDidChangedNotification"
    static let ScoreLastDidChangedNotification = "ScoreLastDidChangedNotification"
    static let IsPlayerWithLastScoreWinDidChangedNotification = "IsPlayerWithLastScoreWinDidChangedNotification"
    
    private static let userDefaults = NSUserDefaults.standardUserDefaults()
    private static let notificationCenter = NSNotificationCenter.defaultCenter()
    
    static var ballRotation: Bool {
        get { return userDefaults.boolForKey(UDKeys.BallRotation) }
        set {
            userDefaults.setBool(newValue, forKey: UDKeys.BallRotation)
            notificationCenter.postNotificationName(BallRotationDidChangedNotification, object: nil)
        }
    }
    
    static var ballGravity: Bool {
        get { return userDefaults.boolForKey(UDKeys.BallGravity) }
        set {
            userDefaults.setBool(newValue, forKey: UDKeys.BallGravity)
            notificationCenter.postNotificationName(BallGravityDidChangedNotification, object: nil)
        }
    }
    
    static var difficultyHard: Bool {
        get { return userDefaults.boolForKey(UDKeys.DifficultyHard) }
        set {
            userDefaults.setBool(newValue, forKey: UDKeys.DifficultyHard)
            notificationCenter.postNotificationName(DifficultyHardDidChangedNotification, object: nil)
        }
    }
    
    static var scoreBest: Int {
        get { return userDefaults.integerForKey(UDKeys.ScoreBest) }
        set {
            userDefaults.setInteger(newValue, forKey: UDKeys.ScoreBest)
            notificationCenter.postNotificationName(ScoreBestDidChangedNotification, object: nil)
        }
    }
    
    static var scoreLast: Int {
        get { return userDefaults.integerForKey(UDKeys.ScoreLast) }
        set {
            userDefaults.setInteger(newValue, forKey: UDKeys.ScoreLast)
            notificationCenter.postNotificationName(ScoreLastDidChangedNotification, object: nil)
        }
    }
    
    static var isPlayerWithLastScoreWin: Bool {
        get { return userDefaults.boolForKey(UDKeys.IsPlayerWithLastScoreWin) }
        set {
            userDefaults.setBool(newValue, forKey: UDKeys.IsPlayerWithLastScoreWin)
            notificationCenter.postNotificationName(IsPlayerWithLastScoreWinDidChangedNotification, object: nil)
        }
    }
    
    static func resetToDefaults() {
        ballRotation = false
        ballGravity = false
        difficultyHard = false
        scoreBest = 0
        scoreLast = 0
        isPlayerWithLastScoreWin = false
    }
}