//
//  GameConfig.swift
//  DaedalusiOS
//
//  All balance / feel knobs in one place, mirroring the CONFIG block of the
//  desktop Python build (tuned a little snappier for a touchscreen). Edit
//  freely -- nothing else hard-codes these numbers.
//

import CoreGraphics
import SpriteKit

enum GC {

    // ---- player ship ------------------------------------------------
    static let playerShieldMax: CGFloat  = 1500
    static let playerHullMax: CGFloat    = 1000
    static let playerShieldRegen: CGFloat = 90      // per second
    static let playerShieldDelay: CGFloat = 2.5     // quiet seconds before regen
    static let playerThrust: CGFloat     = 640      // px / s^2
    static let playerTurnRate: CGFloat   = 3.5      // rad / s  (~200 deg/s)
    static let playerMaxSpeed: CGFloat   = 640
    static let playerDamp: CGFloat       = 0.995    // velocity retained per 1/60 s
    static let ramDamage: CGFloat        = 40

    static let gunCooldown: CGFloat = 0.11
    static let gunDamage: CGFloat   = 26
    static let gunSpeed: CGFloat    = 940
    static let gunLife: CGFloat     = 1.15
    static let gunSpread: CGFloat   = 0.045         // radians

    static let rocketCooldown: CGFloat = 0.75
    static let rocketDamage: CGFloat   = 320
    static let rocketSpeed: CGFloat    = 640
    static let rocketLife: CGFloat     = 2.6
    static let rocketSplashRadius: CGFloat = 130
    static let rocketSplashDamage: CGFloat = 240
    static let rocketStartAmmo = 20

    // ---- enemy: mobile fighter ------------------------------------
    static let fighterShield: CGFloat = 150
    static let fighterHull: CGFloat   = 130
    static let fighterThrust: CGFloat = 340
    static let fighterMaxSpeed: CGFloat = 250
    static let fighterKeepDist: CGFloat = 320
    static let fighterEngage: CGFloat  = 780
    static let fighterFireCd: CGFloat  = 1.2
    static let fighterGunDamage: CGFloat = 10
    static let fighterGunSpeed: CGFloat = 620
    static let fighterScore = 100

    // ---- enemy: dart (fast, fragile, rams) -----------------------
    static let dartShield: CGFloat = 40
    static let dartHull: CGFloat   = 70
    static let dartThrust: CGFloat = 540
    static let dartMaxSpeed: CGFloat = 380
    static let dartKeepDist: CGFloat = 200
    static let dartEngage: CGFloat  = 760
    static let dartFireCd: CGFloat  = 0.7
    static let dartGunDamage: CGFloat = 7
    static let dartGunSpeed: CGFloat = 700
    static let dartRam: CGFloat     = 22
    static let dartScore = 140

    // ---- enemy: Capital Cruiser ---------------------------------
    static let capitalShield: CGFloat = 1500
    static let capitalHull: CGFloat   = 2800
    static let capitalMaxSpeed: CGFloat = 60
    static let capitalTurnRate: CGFloat = 0.42      // rad / s
    static let capitalKeepDist: CGFloat = 520
    static let capitalEngage: CGFloat  = 980
    static let capitalFireCd: CGFloat  = 2.0
    static let capitalGunDamage: CGFloat = 12
    static let capitalGunSpeed: CGFloat = 440
    static let capitalFlakDamage: CGFloat = 5
    static let capitalScore = 3000

    // ---- world / spawning --------------------------------------
    static let maxEnemies = 9
    static let maxCapitals = 1
    static let enemyLeash: CGFloat = 1700          // farther than this: break off
    static let shieldRegenDefault: CGFloat = 22

    // ---- colours ----------------------------------------------
    static let space   = SKColor(red: 0.03, green: 0.04, blue: 0.09, alpha: 1)
    static let hudGreen = SKColor(red: 0.47, green: 1.0, blue: 0.70, alpha: 1)
    static let shieldBlue = SKColor(red: 0.35, green: 0.66, blue: 1.0, alpha: 1)
    static let hullRed  = SKColor(red: 1.0, green: 0.35, blue: 0.35, alpha: 1)
}
