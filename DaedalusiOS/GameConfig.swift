//
//  GameConfig.swift
//  DaedalusiOS
//
//  All balance / feel knobs, mirroring the CONFIG block of the desktop Python
//  build (tuned a little snappier for a touchscreen). `GC` = fixed constants,
//  `Settings` = the live cheat/difficulty toggles the menu edits.
//

import CoreGraphics
import SpriteKit

// =====================================================================
// MARK: - Fixed constants
// =====================================================================
enum GC {

    // ---- player defaults (a ship spec overrides these) --------------
    static let playerShieldMax: CGFloat   = 1500
    static let playerHullMax: CGFloat     = 1000
    static let playerShieldRegen: CGFloat = 90
    static let playerShieldDelay: CGFloat = 2.5
    static let playerThrust: CGFloat      = 640
    static let playerTurnRate: CGFloat    = 3.5      // rad / s
    static let playerMaxSpeed: CGFloat    = 640
    static let playerDamp: CGFloat        = 0.995
    static let ramDamage: CGFloat         = 40

    static let gunCooldown: CGFloat = 0.11
    static let gunDamage: CGFloat   = 26
    static let gunSpeed: CGFloat    = 940
    static let gunLife: CGFloat     = 1.15
    static let gunSpread: CGFloat   = 0.045

    static let rocketCooldown: CGFloat = 0.75
    static let rocketDamage: CGFloat   = 320
    static let rocketSpeed: CGFloat    = 640
    static let rocketLife: CGFloat     = 2.6
    static let rocketSplashRadius: CGFloat = 130
    static let rocketSplashDamage: CGFloat = 240
    static let rocketStartAmmo = 20

    // ---- homing drones --------------------------------------------
    static let homingCooldown: CGFloat = 1.2
    static let homingDamage: CGFloat   = 90
    static let homingSpeed: CGFloat    = 470
    static let homingTurn: CGFloat     = 3.4          // rad / s steering
    static let homingLife: CGFloat     = 5.0
    static let homingStartAmmo = 16
    static let homingSplashRadius: CGFloat = 80
    static let homingSplashDamage: CGFloat = 45
    static let homingAcquireRange: CGFloat = 1500

    // ---- Asgard beam (BC-304 / BC-305 only) -----------------------
    static let beamDamage: CGFloat   = 2400           // per second
    static let beamRange: CGFloat    = 950
    static let beamWidth: CGFloat    = 6
    static let beamEnergyMax: CGFloat = 100
    static let beamDrain: CGFloat    = 26
    static let beamRecharge: CGFloat = 16
    static let beamMinToFire: CGFloat = 5

    // ---- invincibility cloak --------------------------------------
    static let cloakEnergyMax: CGFloat  = 100
    static let cloakDrain: CGFloat      = 20
    static let cloakRecharge: CGFloat   = 11
    static let cloakMinToEngage: CGFloat = 12
    static let cloakDecloakShieldDelay: CGFloat = 3.5

    // ---- automatic hull-repair drones ---------------------------
    static let hullRepairDelay: CGFloat = 5.0

    // ---- replicator infestation --------------------------------
    static let infestBoltSpeed: CGFloat   = 430
    static let infestBoltCd: CGFloat       = 1.6
    static let infestDuration: CGFloat     = 15        // infection -> catastrophic failure
    static let infestDpsStart: CGFloat     = 6
    static let infestDpsEnd: CGFloat       = 55
    static let infestFailureDps: CGFloat   = 160
    static let infestCureRate: CGFloat     = 0.4
    static let infestCureCeiling: CGFloat  = 0.5

    // ---- world / spawning --------------------------------------
    static let maxEnemies = 18       // BRUTAL / EXTREME headroom (see hostileTarget)
    static let maxCapitals = 2
    static let enemyLeash: CGFloat = 1900

    // ---- allied wingmen ---------------------------------------
    static let allyShieldMax: CGFloat = 90
    static let allyHullMax: CGFloat   = 70
    static let allyThrust: CGFloat    = 380
    static let allyMaxSpeed: CGFloat  = 480
    static let allyGunCooldown: CGFloat = 0.16
    static let allyGunDamage: CGFloat = 9
    static let allyGunSpeed: CGFloat  = 900
    static let allyEngageRange: CGFloat = 780
    static let allyKeepDist: CGFloat  = 300
    static let allyMaxWingmen = 6
    static let allyRepairRate: CGFloat = 2.0

    // ---- hyperdrive -----------------------------------------
    static let hyperChargeDefault: CGFloat = 2.0
    static let hyperTravelDefault: CGFloat = 3.5
    static let hyperInvuln: CGFloat = 2.0

    // ---- colours -------------------------------------------
    static let space     = SKColor(red: 0.03, green: 0.04, blue: 0.09, alpha: 1)
    static let hudGreen   = SKColor(red: 0.47, green: 1.0, blue: 0.70, alpha: 1)
    static let shieldBlue = SKColor(red: 0.35, green: 0.66, blue: 1.0, alpha: 1)
    static let hullRed    = SKColor(red: 1.0, green: 0.35, blue: 0.35, alpha: 1)
    static let ancientGold = SKColor(red: 0.85, green: 0.72, blue: 0.35, alpha: 1)
}

// =====================================================================
// MARK: - Difficulty
// =====================================================================
enum Difficulty: Int, CaseIterable, Identifiable {
    case casual, normal, hard, brutal
    var id: Int { rawValue }

    var name: String {
        switch self {
        case .casual: return "CASUAL"
        case .normal: return "NORMAL"
        case .hard:   return "HARD"
        case .brutal: return "BRUTAL"
        }
    }
    /// spawn-rate multiplier
    var spawnMult: CGFloat {
        switch self { case .casual: return 0.55; case .normal: return 1.0
                      case .hard: return 1.45; case .brutal: return 2.1 }
    }
    /// damage-taken multiplier (applied to the player only)
    var damageMult: CGFloat {
        switch self { case .casual: return 0.55; case .normal: return 1.0
                      case .hard: return 1.30; case .brutal: return 1.75 }
    }
}

// =====================================================================
// MARK: - Live settings (the menu edits these; game reads them at call time)
// =====================================================================
final class Settings {
    static let shared = Settings()

    private let d = UserDefaults.standard
    private init() {
        difficulty      = Difficulty(rawValue: d.object(forKey: "daed.difficulty") as? Int ?? 1) ?? .normal
        startSector     = d.object(forKey: "daed.startSector") as? Int ?? 0
        startWingmen    = d.object(forKey: "daed.startWingmen") as? Int ?? 1
        godMode         = d.bool(forKey: "daed.god")
        infiniteRockets = d.object(forKey: "daed.infRockets") as? Bool ?? true
        infiniteHoming  = d.bool(forKey: "daed.infHoming")
        infiniteBeam    = d.bool(forKey: "daed.infBeam")
        noCooldown      = d.bool(forKey: "daed.noCd")
        oneShotKill     = d.bool(forKey: "daed.oneShot")
        autoRepair      = d.object(forKey: "daed.autoRepair") as? Bool ?? true
        cloakEnabled    = d.object(forKey: "daed.cloak") as? Bool ?? true
    }

    var difficulty: Difficulty      { didSet { d.set(difficulty.rawValue, forKey: "daed.difficulty") } }
    var startSector: Int            { didSet { d.set(startSector, forKey: "daed.startSector") } }
    var startWingmen: Int           { didSet { d.set(startWingmen, forKey: "daed.startWingmen") } }
    var godMode: Bool               { didSet { d.set(godMode, forKey: "daed.god") } }
    var infiniteRockets: Bool       { didSet { d.set(infiniteRockets, forKey: "daed.infRockets") } }
    var infiniteHoming: Bool        { didSet { d.set(infiniteHoming, forKey: "daed.infHoming") } }
    var infiniteBeam: Bool          { didSet { d.set(infiniteBeam, forKey: "daed.infBeam") } }
    var noCooldown: Bool            { didSet { d.set(noCooldown, forKey: "daed.noCd") } }
    var oneShotKill: Bool           { didSet { d.set(oneShotKill, forKey: "daed.oneShot") } }
    var autoRepair: Bool            { didSet { d.set(autoRepair, forKey: "daed.autoRepair") } }
    var cloakEnabled: Bool          { didSet { d.set(cloakEnabled, forKey: "daed.cloak") } }

    var spawnMult: CGFloat { difficulty.spawnMult }
    var damageMult: CGFloat { difficulty.damageMult }
}
