//
//  HUD.swift
//  DaedalusiOS
//
//  Retro readout pinned to the camera: ship name, shield / hull / beam / cloak
//  bars, speed, ammo, score, sector, hostiles, wingmen, plus centre-screen
//  warnings (shields rebuilding, infestation, hull critical, hyperdrive).
//

import SpriteKit

final class HUD: SKNode {

    private let barW: CGFloat = 200

    private let shieldBack = HUD.bar(SKColor(white: 0.08, alpha: 0.7), 200, 13)
    private let shieldFill = HUD.bar(GC.shieldBlue, 200, 13)
    private let hullBack   = HUD.bar(SKColor(white: 0.08, alpha: 0.7), 200, 13)
    private let hullFill    = HUD.bar(GC.hullRed, 200, 13)
    private let beamBack   = HUD.bar(SKColor(white: 0.08, alpha: 0.7), 200, 8)
    private let beamFill    = HUD.bar(SKColor(red: 0.5, green: 0.95, blue: 1, alpha: 1), 200, 8)
    private let cloakBack  = HUD.bar(SKColor(white: 0.08, alpha: 0.7), 200, 8)
    private let cloakFill   = HUD.bar(SKColor(red: 0.75, green: 0.5, blue: 1, alpha: 1), 200, 8)

    private let shipLabel   = HUD.label(13, bold: true)
    private let statusLabel = HUD.label(11)
    private let scoreLabel  = HUD.label(15, bold: true)
    private let sectorLabel = HUD.label(11)
    private let hostLabel   = HUD.label(11)
    private let wingLabel   = HUD.label(11)
    private let warnLabel   = HUD.label(13, bold: true)

    override init() {
        super.init()
        zPosition = 1000
        for n in [shieldBack, shieldFill, hullBack, hullFill, beamBack, beamFill, cloakBack, cloakFill] {
            n.anchorPoint = CGPoint(x: 0, y: 0.5); addChild(n)
        }
        for l in [shipLabel, statusLabel, scoreLabel, sectorLabel, hostLabel, wingLabel, warnLabel] {
            addChild(l)
        }
        warnLabel.horizontalAlignmentMode = .center
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private static func bar(_ c: SKColor, _ w: CGFloat, _ h: CGFloat) -> SKSpriteNode {
        SKSpriteNode(color: c, size: CGSize(width: w, height: h))
    }
    private static func label(_ sz: CGFloat, bold: Bool = false) -> SKLabelNode {
        let l = SKLabelNode(fontNamed: bold ? "Menlo-Bold" : "Menlo-Regular")
        l.fontSize = sz; l.fontColor = GC.hudGreen
        l.horizontalAlignmentMode = .left; l.verticalAlignmentMode = .center
        return l
    }

    func layout(size: CGSize) {
        let left = -size.width / 2 + 16
        let top = size.height / 2 - 34

        shipLabel.position = CGPoint(x: left, y: top)
        var y = top - 22
        for pair in [(shieldBack, shieldFill), (hullBack, hullFill)] {
            pair.0.position = CGPoint(x: left, y: y); pair.1.position = CGPoint(x: left, y: y); y -= 19
        }
        for pair in [(beamBack, beamFill), (cloakBack, cloakFill)] {
            pair.0.position = CGPoint(x: left, y: y); pair.1.position = CGPoint(x: left, y: y); y -= 13
        }
        statusLabel.position = CGPoint(x: left, y: y - 4)

        let right = size.width / 2 - 16
        for l in [scoreLabel, sectorLabel, hostLabel, wingLabel] { l.horizontalAlignmentMode = .right }
        scoreLabel.position  = CGPoint(x: right, y: top)
        sectorLabel.position = CGPoint(x: right, y: top - 20)
        hostLabel.position   = CGPoint(x: right, y: top - 38)
        wingLabel.position   = CGPoint(x: right, y: top - 56)
        sectorLabel.fontColor = SKColor(red: 0.7, green: 0.82, blue: 1, alpha: 1)
        hostLabel.fontColor = SKColor(white: 0.6, alpha: 1)
        wingLabel.fontColor = SKColor(red: 0.5, green: 1, blue: 0.65, alpha: 1)

        warnLabel.position = CGPoint(x: 0, y: top - 6)
    }

    func update(player: PlayerShip, score: Int, sector: String,
                hostiles: Int, wingmen: Int, hyper: String?) {
        shipLabel.text = player.spec.name.uppercased()

        shieldFill.xScale = frac(player.shield, player.shieldMax)
        hullFill.xScale = frac(player.hull, player.hullMax)
        shieldFill.color = player.shieldHardened
            ? SKColor(red: 0.55, green: 0.85, blue: 1, alpha: 1) : GC.shieldBlue

        let showBeam = player.hasBeam
        beamBack.isHidden = !showBeam; beamFill.isHidden = !showBeam
        if showBeam { beamFill.xScale = frac(player.beamEnergy, player.spec.beamMax) }
        cloakFill.xScale = frac(player.cloakEnergy, GC.cloakEnergyMax)
        cloakFill.color = player.cloaked
            ? SKColor(red: 0.9, green: 0.5, blue: 1, alpha: 1)
            : SKColor(red: 0.55, green: 0.4, blue: 0.8, alpha: 1)

        let spd = Int(player.velocity.length)
        let rk = Settings.shared.infiniteRockets ? "INF" : "\(player.rockets)"
        let hm = Settings.shared.infiniteHoming ? "INF" : "\(player.homing)"
        statusLabel.text = "SPD \(spd)   RKT \(rk)   HOM \(hm)"

        scoreLabel.text = "SCORE  \(score)"
        sectorLabel.text = "SECTOR  \(sector)"
        hostLabel.text = "HOSTILES  \(hostiles)"
        wingLabel.text = "WINGMEN  \(wingmen)"

        var warn: (String, SKColor)?
        if let hyper { warn = (hyper, SKColor(red: 0.7, green: 0.9, blue: 1, alpha: 1)) }
        else if player.cloaked { warn = ("CLOAKED  --  SHIELDS OFFLINE", SKColor(red: 0.85, green: 0.6, blue: 1, alpha: 1)) }
        else if player.infested > 0 {
            let pct = Int(min(1, player.infested) * 100)
            warn = player.infested >= 1
                ? ("!! SYSTEMS FAILING -- HULL COLLAPSE !!", SKColor(red: 0.9, green: 0.5, blue: 0.9, alpha: 1))
                : ("REPLICATOR INFESTATION \(pct)%  --  KILL THE SOURCE", SKColor(red: 0.82, green: 0.82, blue: 0.92, alpha: 1))
        } else if player.hull / player.hullMax < 0.3 && !player.isDead {
            warn = ("!! HULL CRITICAL !!", SKColor(red: 1, green: 0.35, blue: 0.35, alpha: 1))
        }
        if let (t, c) = warn { warnLabel.text = t; warnLabel.fontColor = c; warnLabel.isHidden = false }
        else { warnLabel.isHidden = true }
    }

    private func frac(_ v: CGFloat, _ m: CGFloat) -> CGFloat {
        max(0.0001, clampf(m > 0 ? v / m : 0, 0, 1))
    }
}
