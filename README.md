# Breakout game
Simple Arkanoid game for iOS

**Features:**
* The ability to change the behavior of physical objects
* Multiple levels of game, multiple levels of difficulty
* Physics engine based on UIKit Dynamics
* Support iPhone, iPad

![alt tag][screenshot1]
[![Alt][screenshot2_thumb]][screenshot2]

[screenshot1]: https://raw.github.com/dterekhov/breakout-game-ios/master/Screenshots/Screenshot1.png
[screenshot2_thumb]: https://raw.github.com/dterekhov/breakout-game-ios/master/Screenshots/Screenshot2_thumb.png
[screenshot2]: https://raw.github.com/dterekhov/breakout-game-ios/master/Screenshots/Screenshot2.png

## Start game
To start the game, tap on the screen. Game paused manually by Pause button tap or automatically when you leave main game screen.

## Settings
* The changed settings are applied to the game immediately
* Gravity Ball is not supported if the device does not have an accelerometer
* Hard level of difficulty: less lives, higher ball speed, more bonus score for combo brick's destroy

## Brick's behavior
* Orange - normal brick, destroyed in one hit
* Black - strong brick, destroyed in two hits
* Blue - magic brick, destroyed in one hit but reduces the width of paddle

Project based on Stanford course ["Developing iOS 8 Apps with Swift"](https://itunes.apple.com/ru/course/developing-ios-8-apps-swift/id961180099) under the guidance of Professor Paul Hegarty
