//
//  HUD.swift
//  DaedalusiOS
//
//  Retro readout pinned to the camera: shield + hull bars, score, sector,
//  rocket count, speed. Laid out from the current view size each time the
//  scene resizes (iPad rotation).
//

import SpriteKit

final class HUD: SKNode {

    private let shieldBack = SKSpriteNode(color: SKColor(white: 0.08, alpha: 0.7),
                                          size: CGSize(width: 210, height: 13))
    private let shieldFill = SKSpriteNode(color: GC.shieldBlue,
                                          size: CGSize(width: 210, height: 13))
    private let hullBack = SKSpriteNode(color: SKColor(white: 0.08, alpha: 0.7),
                                        size: CGSize(width: 210, height: 13))
    private let hullFill = SKSpriteNode(color: GC.hullRed,
                                        size: CGSize(width: 210, height: 13))

    private let shipLabel = HUD.label(size: 13, bold: true)
    private let statusLabel = HUD.label(size: 12)
    private let scoreLabel = HUD.label(size: 15, bold: true)
    private let sectorLabel = HUD.label(size: 12)
    private let hostilesLabel = HUD.label(size: 12)

    private let barWidth: CGFloat = 210

    override init() {
        super.init()
        zPosition = 1000
        for n in [shieldBack, shieldFill, hullBack, hullFill] {
            n.anchorPoint = CGPoint(x: 0, y: 0.5)
            addChild(n)
        }
        for l in [shipLabel, statusLabel, scoreLabel, sectorLabel, hostilesLabel] {
            addChild(l)
        }
        shipLabel.text = "BC-304  DAEDALUS"
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private static func label(size: CGFloat, bold: Bool = false) -> SKLabelNode {
        let l = SKLabelNode(fontNamed: bold ? "Menlo-Bold" : "Menlo-Regular")
        l.fontSize = size
        l.fontColor = GC.hudGreen
        l.horizontalAlignmentMode = .left
        l.verticalAlignmentMode = .center
        return l
    }

    func layout(size: CGSize) {
        let left = -size.width / 2 + 16
        let top = size.height / 2 - 34          // clear of the notch / status area

        shipLabel.position = CGPoint(x: left, y: top)
        for (i, pair) in [(shieldBack, shieldFill), (hullBack, hullFill)].enumerated() {
            let y = top - 22 - CGFloat(i) * 20
            pair.0.position = CGPoint(x: left, y: y)
            pair.1.position = CGPoint(x: left, y: y)
        }
        statusLabel.position = CGPoint(x: left, y: top - 22 - 2 * 20 - 4)

        let right = size.width / 2 - 16
        scoreLabel.horizontalAlignmentMode = .right
        sectorLabel.horizontalAlignmentMode = .right
        hostilesLabel.horizontalAlignmentMode = .right
        scoreLabel.position = CGPoint(x: right, y: top)
        sectorLabel.position = CGPoint(x: right, y: top - 20)
        hostilesLabel.position = CGPoint(x: right, y: top - 38)
        sectorLabel.fontColor = SKColor(red: 0.7, green: 0.82, blue: 1, alpha: 1)
        hostilesLabel.fontColor = SKColor(white: 0.6, alpha: 1)
    }

    func update(player: PlayerShip, score: Int, sector: String, hostiles: Int) {
        let sFrac = player.shieldMax > 0 ? player.shield / player.shieldMax : 0
        let hFrac = player.hullMax > 0 ? player.hull / player.hullMax : 0
        shieldFill.xScale = max(0.0001, clampf(sFrac, 0, 1))
        hullFill.xScale = max(0.0001, clampf(hFrac, 0, 1))

        scoreLabel.text = "SCORE  \(score)"
        sectorLabel.text = "SECTOR  \(sector)"
        hostilesLabel.text = "HOSTILES  \(hostiles)"

        let spd = Int(player.velocity.length)
        statusLabel.text = "ROCKETS \(player.rockets)   SPEED \(spd) u/s"

        if player.shield <= 1 && !player.isDead {
            statusLabel.fontColor = SKColor(red: 1, green: 0.55, blue: 0.55, alpha: 1)
        } else {
            statusLabel.fontColor = GC.hudGreen
        }
    }
}
