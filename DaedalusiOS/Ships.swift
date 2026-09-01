//
//  Ships.swift
//  DaedalusiOS
//
//  Data-driven player ship roster, ported from the desktop _SHIP_BASE + SHIPS
//  tables. Add a ship = one ShipSpec + one art builder + an entry in `all`.
//

import SpriteKit

enum ShipID: String, CaseIterable, Identifiable {
    case x302, daedalus, phoenix, aurora, destiny, atlantis
    var id: String { rawValue }
}

struct ShipSpec {
    var name: String
    var role: String
    var radius: CGFloat
    var bubblePad: CGFloat

    var shieldMax: CGFloat
    var shieldRegen: CGFloat
    var shieldDelay: CGFloat
    var hullMax: CGFloat
    var hardened: Bool = false          // Ancient shield: caps any single hit

    var thrust: CGFloat
    var turn: CGFloat                   // rad / s
    var maxSpeed: CGFloat
    var damp: CGFloat
    var repairRate: CGFloat

    var gunCd: CGFloat = GC.gunCooldown
    var gunDmg: CGFloat = GC.gunDamage
    var gunSpeed: CGFloat = GC.gunSpeed
    var gunSpread: CGFloat = GC.gunSpread

    var rocketCd: CGFloat = GC.rocketCooldown
    var rocketDmg: CGFloat = GC.rocketDamage
    var rocketAmmo: Int = GC.rocketStartAmmo

    var homingCd: CGFloat = GC.homingCooldown
    var homingDmg: CGFloat = GC.homingDamage
    var homingAmmo: Int = GC.homingStartAmmo
    var homingTurn: CGFloat = GC.homingTurn
    var homingSalvo: Int = 1            // drones launched per volley

    var beamDmg: CGFloat = 0           // 0 == no Asgard beam tech
    var beamMax: CGFloat = GC.beamEnergyMax

    var turrets: Int = 0              // Destiny's AI dorsal cannons
    var turretCd: CGFloat = 0.45
    var turretDmg: CGFloat = 15
    var turretRange: CGFloat = 640

    /// >0 == an omni-directional broadside: this many gun ports evenly around
    /// the rim, each firing outward on every trigger (Atlantis). 0 == the
    /// default forward twin cannon.
    var gunPorts: Int = 0

    var bodyColor: SKColor = SKColor(red: 0.62, green: 0.70, blue: 0.85, alpha: 1)
}

enum Ships {

    static func spec(_ id: ShipID) -> ShipSpec {
        switch id {

        case .daedalus:
            return ShipSpec(
                name: "Daedalus (BC-304)", role: "BATTLECRUISER",
                radius: 20, bubblePad: 14,
                shieldMax: GC.playerShieldMax, shieldRegen: GC.playerShieldRegen,
                shieldDelay: GC.playerShieldDelay, hullMax: GC.playerHullMax,
                thrust: GC.playerThrust, turn: GC.playerTurnRate,
                maxSpeed: GC.playerMaxSpeed, damp: GC.playerDamp, repairRate: 3.5,
                beamDmg: GC.beamDamage)

        case .x302:
            return ShipSpec(
                name: "F-302 Fighter", role: "STRIKE FIGHTER",
                radius: 13, bubblePad: 12,
                shieldMax: 380, shieldRegen: 26, shieldDelay: 1.8, hullMax: 240,
                thrust: 1050, turn: 5.6, maxSpeed: 720, damp: 0.985, repairRate: 1.5,
                gunCd: 0.06, gunDmg: 20, gunSpeed: 1000, gunSpread: 0.03,
                rocketCd: 0.6, rocketDmg: 220, rocketAmmo: 16,
                homingCd: 1.3, homingDmg: 68, homingAmmo: 12, homingSalvo: 1,
                bodyColor: SKColor(red: 0.72, green: 0.78, blue: 0.9, alpha: 1))

        case .phoenix:
            return ShipSpec(
                name: "Phoenix (BC-305)", role: "BATTLECRUISER MK II",
                radius: 24, bubblePad: 16,
                shieldMax: 2400, shieldRegen: 100, shieldDelay: 2.3, hullMax: 1600,
                thrust: 560, turn: 3.7, maxSpeed: 660, damp: 0.995, repairRate: 5.0,
                gunCd: 0.075, gunDmg: 28,
                rocketCd: 0.65, rocketDmg: 260, rocketAmmo: 48,
                homingCd: 0.95, homingDmg: 110, homingAmmo: 32,
                beamDmg: 3400, beamMax: 130,
                bodyColor: SKColor(red: 0.58, green: 0.66, blue: 0.82, alpha: 1))

        case .aurora:
            return ShipSpec(
                name: "Aurora-class Warship", role: "ANCIENT WARSHIP",
                radius: 30, bubblePad: 18,
                shieldMax: 3600, shieldRegen: 2000, shieldDelay: 0, hullMax: 2100,
                hardened: true,
                thrust: 430, turn: 3.1, maxSpeed: 620, damp: 0.996, repairRate: 6.0,
                gunCd: 0.10, gunDmg: 22,
                rocketCd: 0.85, rocketDmg: 240, rocketAmmo: 30,
                homingCd: 0.55, homingDmg: 115, homingAmmo: 2000, homingTurn: 4.6,
                homingSalvo: 3,
                bodyColor: SKColor(red: 0.75, green: 0.75, blue: 0.82, alpha: 1))

        case .destiny:
            return ShipSpec(
                name: "Destiny", role: "LEGACY EXPLORER",
                radius: 34, bubblePad: 14,
                shieldMax: 1800, shieldRegen: 60, shieldDelay: 2.8, hullMax: 3400,
                thrust: 340, turn: 2.2, maxSpeed: 520, damp: 0.997, repairRate: 7.5,
                gunCd: 0.10, gunDmg: 22,
                rocketCd: 0.9, rocketDmg: 210, rocketAmmo: 26,
                homingCd: 2.2, homingDmg: 90, homingAmmo: 40, homingSalvo: 5,
                turrets: 5, turretCd: 0.45, turretDmg: 15, turretRange: 640,
                bodyColor: SKColor(red: 0.68, green: 0.66, blue: 0.62, alpha: 1))

        case .atlantis:
            return ShipSpec(
                name: "Atlantis (City-Ship)", role: "CITY-SHIP",
                radius: 44, bubblePad: 22,
                shieldMax: 7000, shieldRegen: 2800, shieldDelay: 0, hullMax: 5600,
                hardened: true,
                thrust: 290, turn: 1.9, maxSpeed: 480, damp: 0.998, repairRate: 11.0,
                gunCd: 0.12, gunDmg: 24,
                rocketCd: 0.75, rocketDmg: 300, rocketAmmo: 80,
                homingCd: 1.0, homingDmg: 125, homingAmmo: 3200, homingTurn: 4.7,
                homingSalvo: 6,
                gunPorts: 8,
                bodyColor: SKColor(red: 0.68, green: 0.76, blue: 0.86, alpha: 1))
        }
    }

    /// Builds the vector hull for `id` as children of `node` (local coords,
    /// +x == nose). Returns the shape used as the flashing hull.
    @discardableResult
    static func buildArt(_ id: ShipID, on node: SKNode) -> SKShapeNode {
        let s = spec(id)
        let hull = SKShapeNode(path: hullPath(id))
        hull.fillColor = s.bodyColor
        hull.strokeColor = SKColor(white: 0.13, alpha: 1)
        hull.lineWidth = 2
        node.addChild(hull)

        switch id {
        case .daedalus, .phoenix:
            for sy in [CGFloat(1), CGFloat(-1)] {
                let n = SKShapeNode(rectOf: CGSize(width: 22, height: 7), cornerRadius: 2)
                n.fillColor = SKColor(white: 0.3, alpha: 1)
                n.strokeColor = SKColor(white: 0.12, alpha: 1); n.lineWidth = 1
                n.position = CGPoint(x: -s.radius * 1.1, y: sy * (s.radius * 0.6))
                node.addChild(n)
            }
            dot(node, at: CGPoint(x: s.radius * 0.5, y: 0), r: 3,
                color: SKColor(red: 0.6, green: 0.9, blue: 1, alpha: 1))
        case .x302:
            dot(node, at: CGPoint(x: 2, y: 0), r: 2,
                color: SKColor(red: 0.7, green: 0.95, blue: 1, alpha: 1))
        case .aurora:
            for lx in stride(from: -22, through: 22, by: 11) {
                dot(node, at: CGPoint(x: CGFloat(lx), y: 0), r: 1.4, color: GC.ancientGold)
            }
        case .destiny:
            for i in 0..<5 {
                dot(node, at: CGPoint(x: -22 + CGFloat(i) * 11, y: -3), r: 2.4,
                    color: SKColor(white: 0.85, alpha: 1))
            }
        case .atlantis:
            dot(node, at: .zero, r: 4, color: SKColor(red: 0.6, green: 0.95, blue: 1, alpha: 1))
            // eight gun ports around the rim -- the bolts come out of these
            let ports = max(1, s.gunPorts)
            for i in 0..<ports {
                let a = CGFloat(i) / CGFloat(ports) * .pi * 2
                let muzzle = dot(node, at: CGPoint(x: cos(a) * s.radius, y: sin(a) * s.radius),
                                 r: 2.6, color: SKColor(red: 0.6, green: 0.95, blue: 1, alpha: 1))
                muzzle.run(.repeatForever(.sequence([
                    .fadeAlpha(to: 0.35, duration: 0.5), .fadeAlpha(to: 1, duration: 0.5)])))
            }
            // gold thruster marker so the facing vector is obvious on a round hull
            dot(node, at: CGPoint(x: -s.radius - 6, y: 0), r: 3.5, color: GC.ancientGold)
        }
        return hull
    }

    @discardableResult
    private static func dot(_ node: SKNode, at p: CGPoint, r: CGFloat, color: SKColor) -> SKShapeNode {
        let d = SKShapeNode(circleOfRadius: r)
        d.fillColor = color; d.strokeColor = .clear; d.blendMode = .add
        d.position = p
        node.addChild(d)
        return d
    }

    private static func hullPath(_ id: ShipID) -> CGPath {
        let p = CGMutablePath()
        switch id {
        case .daedalus:
            p.addLines(between: [CGPoint(x: 26, y: 0), CGPoint(x: 8, y: -13),
                                 CGPoint(x: -20, y: -13), CGPoint(x: -24, y: 0),
                                 CGPoint(x: -20, y: 13), CGPoint(x: 8, y: 13)])
        case .x302:
            p.addLines(between: [CGPoint(x: 18, y: 0), CGPoint(x: 2, y: -5),
                                 CGPoint(x: -14, y: -14), CGPoint(x: -10, y: -4),
                                 CGPoint(x: -16, y: 0), CGPoint(x: -10, y: 4),
                                 CGPoint(x: -14, y: 14), CGPoint(x: 2, y: 5)])
        case .phoenix:
            p.addLines(between: [CGPoint(x: 30, y: 0), CGPoint(x: 12, y: -16),
                                 CGPoint(x: -24, y: -16), CGPoint(x: -30, y: 0),
                                 CGPoint(x: -24, y: 16), CGPoint(x: 12, y: 16)])
        case .aurora:
            p.addLines(between: [CGPoint(x: 34, y: 0), CGPoint(x: 22, y: -8),
                                 CGPoint(x: -6, y: -13), CGPoint(x: -28, y: -9),
                                 CGPoint(x: -32, y: 0), CGPoint(x: -28, y: 9),
                                 CGPoint(x: -6, y: 13), CGPoint(x: 22, y: 8)])
        case .destiny:
            p.addLines(between: [CGPoint(x: 40, y: -5), CGPoint(x: 44, y: 5),
                                 CGPoint(x: 20, y: 12), CGPoint(x: -34, y: 15),
                                 CGPoint(x: -40, y: 0), CGPoint(x: -34, y: -15),
                                 CGPoint(x: 20, y: -12)])
        case .atlantis:
            for i in 0..<6 {
                let a = CGFloat(i) / 6 * .pi * 2
                let outer = CGPoint(x: cos(a) * 42, y: sin(a) * 42)
                if i == 0 { p.move(to: outer) } else { p.addLine(to: outer) }
            }
        }
        p.closeSubpath()
        return p
    }
}

/// Persisted ship choice (survives relaunch, like `Player.selected`).
enum PlayerLoadout {
    private static let key = "daed.ship"
    static var selected: ShipID {
        get { ShipID(rawValue: UserDefaults.standard.string(forKey: key) ?? "") ?? .daedalus }
        set { UserDefaults.standard.set(newValue.rawValue, forKey: key) }
    }
}
