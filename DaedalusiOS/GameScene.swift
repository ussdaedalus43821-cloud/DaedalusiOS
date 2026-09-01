//
//  GameScene.swift
//  DaedalusiOS
//
//  The open-world combat sim. A camera follows the player through empty space;
//  fighters, darts and Capital Cruisers spawn in a ring around you, hunt, and
//  break off if you leave them far behind. Manual (deterministic) collision.
//

import SpriteKit

final class GameScene: SKScene {

    /// Set by GameContainerView -- pops back to the SwiftUI menu.
    var onReturnToMenu: (() -> Void)?

    private let cam = SKCameraNode()
    private let starfield = Starfield()
    private let hud = HUD()
    private let controls = TouchControls()
    private let player = PlayerShip()

    private var enemies: [Enemy] = []
    private var friendlyShots: [Projectile] = []
    private var enemyShots: [Projectile] = []

    private var lastTime: TimeInterval = 0
    private var spawnTimer: CGFloat = 2.5
    private var score = 0
    private var sectorIndex = 1
    private var sectorClock: CGFloat = 0
    private var shake: CGFloat = 0
    private var isGameOver = false
    private var didReportScore = false

    private let sectorNames = ["TERRA NOVA", "PEGASUS GATE", "DEEP VOID",
                               "ASURAN FRONTIER", "CHULAK APPROACH", "THE BLACK RIFT"]

    // MARK: Lifecycle

    override func didMove(to view: SKView) {
        backgroundColor = GC.space
        scaleMode = .resizeFill
        isUserInteractionEnabled = true

        camera = cam
        addChild(cam)
        cam.addChild(starfield)
        cam.addChild(hud)
        cam.addChild(controls)
        starfield.zPosition = -100

        addChild(player)
        player.resetForNewGame()

        layout(for: size)
        starfield.build(viewSize: size)
        showBanner("D A E D A L U S", sub: "open-world space combat")
    }

    override func didChangeSize(_ oldSize: CGSize) {
        guard size.width > 0, size.height > 0 else { return }
        layout(for: size)
        starfield.build(viewSize: size)
    }

    private func layout(for size: CGSize) {
        hud.layout(size: size)
        controls.layout(size: size)
    }

    // MARK: Scene-facing helpers (used by ships)

    func add(projectile: Projectile) {
        addChild(projectile)
        if projectile.friendly { friendlyShots.append(projectile) }
        else { enemyShots.append(projectile) }
    }

    func registerShake(_ amount: CGFloat) { shake = max(shake, amount) }

    // MARK: Main loop

    override func update(_ currentTime: TimeInterval) {
        if lastTime == 0 { lastTime = currentTime }
        var dt = CGFloat(currentTime - lastTime)
        lastTime = currentTime
        guard dt > 0 else { return }
        dt = min(dt, 1.0 / 20.0)              // clamp hitches

        if !isGameOver {
            sectorClock += dt
            advanceSectorIfNeeded()

            player.update(dt: dt, input: controls.state, scene: self)
            for e in enemies { e.update(dt: dt, player: player, scene: self) }
            for s in friendlyShots { s.step(dt) }
            for s in enemyShots { s.step(dt) }

            handleCollisions()
            cull()
            updateSpawning(dt)

            if player.hull <= 0 { triggerGameOver() }
        }

        // camera + shake
        shake *= 0.85
        let jitter = CGVector(dx: .random(in: -1...1), dy: .random(in: -1...1)) * shake
        cam.position = player.position + jitter
        starfield.update(cameraPos: cam.position)
        hud.update(player: player, score: score,
                   sector: sectorNames[(sectorIndex - 1) % sectorNames.count],
                   hostiles: enemies.count)
    }

    // MARK: Collisions

    private func handleCollisions() {
        // friendly shots vs enemies
        for shot in friendlyShots where !shot.isDead {
            for enemy in enemies where !enemy.isDead {
                let surfR = (enemy.shield > 0 ? enemy.bubbleRadius : enemy.radius) + shot.hitRadius
                guard shot.position.distanceSquared(to: enemy.position) <= surfR * surfR else { continue }

                let dirOut = (shot.position - enemy.position).normalized
                let contact = enemy.position + dirOut * (enemy.shield > 0 ? enemy.bubbleRadius : enemy.radius)
                let shielded = enemy.shield > 0
                enemy.takeDamage(shot.damage, from: dirOut)

                if shot.splashRadius > 0 {
                    Effects.explosion(in: self, at: contact, scale: 1.4)
                    registerShake(8)
                    for other in enemies where !other.isDead {
                        if contact.distance(to: other.position) <= shot.splashRadius + other.radius {
                            other.takeDamage(shot.splashDamage, from: (other.position - contact).normalized)
                        }
                    }
                } else {
                    Effects.hitSpark(in: self, at: contact, shielded: shielded)
                }
                shot.isDead = true
                break
            }
        }

        // enemy shots vs player
        if player.invuln <= 0 && !player.isDead {
            for shot in enemyShots where !shot.isDead {
                let surfR = (player.shield > 0 ? player.bubbleRadius : player.radius) + shot.hitRadius
                guard shot.position.distanceSquared(to: player.position) <= surfR * surfR else { continue }
                let dirOut = (shot.position - player.position).normalized
                let contact = player.position + dirOut * (player.shield > 0 ? player.bubbleRadius : player.radius)
                Effects.hitSpark(in: self, at: contact, shielded: player.shield > 0)
                player.takeDamage(shot.damage, from: dirOut)
                registerShake(shot.kind == .enemyHeavy ? 7 : 4)
                shot.isDead = true
            }
        }

        // body ram: player vs enemy hull. Brief mutual i-frames so a lingering
        // overlap can't drain the hull frame-by-frame.
        if player.invuln <= 0 {
            for enemy in enemies where !enemy.isDead {
                guard player.position.distance(to: enemy.position) <= player.radius + enemy.radius
                else { continue }
                let d = (player.position - enemy.position).normalized
                player.takeDamage(GC.ramDamage, from: -d)
                enemy.takeDamage(GC.ramDamage * 1.5, from: d)
                player.velocity += d * 240
                enemy.velocity -= d * 180
                player.invuln = max(player.invuln, 0.6)
                registerShake(7)
                break
            }
        }
    }

    // MARK: Cull + score

    private func cull() {
        for enemy in enemies where enemy.isDead {
            score += enemy.scoreValue
            let big = enemy.kind.isCapital
            Effects.explosion(in: self, at: enemy.position, scale: big ? 3.1 : 1.3)
            registerShake(big ? 26 : 9)
            enemy.removeFromParent()
        }
        enemies.removeAll { $0.isDead }

        for s in friendlyShots where s.isDead { s.removeFromParent() }
        friendlyShots.removeAll { $0.isDead }
        for s in enemyShots where s.isDead { s.removeFromParent() }
        enemyShots.removeAll { $0.isDead }

        // leash: hostiles left far behind break off and jump out
        enemies.removeAll { enemy in
            if enemy.position.distanceSquared(to: player.position) > GC.enemyLeash * GC.enemyLeash {
                Effects.explosion(in: self, at: enemy.position, scale: 0.7)
                enemy.removeFromParent()
                return true
            }
            return false
        }

        // drop shots that have wandered way off
        let far: CGFloat = 1800 * 1800
        friendlyShots.removeAll { s in
            if s.position.distanceSquared(to: player.position) > far { s.removeFromParent(); return true }
            return false
        }
        enemyShots.removeAll { s in
            if s.position.distanceSquared(to: player.position) > far { s.removeFromParent(); return true }
            return false
        }
    }

    // MARK: Spawning

    private func updateSpawning(_ dt: CGFloat) {
        guard enemies.count < GC.maxEnemies else { return }
        spawnTimer -= dt
        guard spawnTimer <= 0 else { return }

        let danger = min(3, 1 + sectorIndex / 2)
        // only top up when the sky is fairly clear -- keeps the fight readable
        let target = 2 + danger
        guard enemies.count < target else {
            spawnTimer = 2.5
            return
        }
        spawnTimer = CGFloat.random(in: 5.0...8.5)
        let wave = min(target - enemies.count, Int.random(in: 1...2))
        for _ in 0..<wave {
            let roll = Int.random(in: 0..<12)
            let kind: EnemyKind
            if roll == 0 && sectorIndex >= 2 { kind = .capital }
            else if roll <= 3 { kind = .dart }
            else { kind = .fighter }
            spawn(kind)
        }
    }

    private func spawn(_ kind: EnemyKind) {
        if kind.isCapital,
           enemies.filter({ $0.kind.isCapital }).count >= GC.maxCapitals { return }
        let enemy = Enemy(kind: kind)
        let angle = CGFloat.random(in: 0...(2 * .pi))
        let dist: CGFloat = kind.isCapital ? .random(in: 720...1000) : .random(in: 480...760)
        enemy.position = player.position + CGVector(angle: angle) * dist
        enemy.zRotation = (player.position - enemy.position).angle
        addChild(enemy)
        enemies.append(enemy)
    }

    private func advanceSectorIfNeeded() {
        // every ~55s the sector "shifts" -- fresh backdrop tint + a spawn surge
        if sectorClock > 55 {
            sectorClock = 0
            sectorIndex += 1
            let tint = sectorTint(sectorIndex)
            run(.customAction(withDuration: 0.8) { [weak self] _, t in
                guard let self else { return }
                self.backgroundColor = self.lerpColor(GC.space, tint, clampf(t / 0.8, 0, 1))
            })
            showBanner("SECTOR \(sectorIndex)",
                       sub: sectorNames[(sectorIndex - 1) % sectorNames.count])
            spawnTimer = 1.0
        }
    }

    // MARK: Game over

    private func triggerGameOver() {
        guard !isGameOver else { return }
        isGameOver = true
        Effects.explosion(in: self, at: player.position, scale: 4.4)
        registerShake(36)
        player.isHidden = true
        controls.setActiveInput(false)

        if !didReportScore {
            didReportScore = true
            HighScoreStore.shared.submit(score)
        }

        let dim = SKSpriteNode(color: SKColor(red: 0.12, green: 0, blue: 0, alpha: 0.55),
                               size: CGSize(width: size.width * 2, height: size.height * 2))
        dim.zPosition = 2000
        cam.addChild(dim)

        let title = bannerLabel("DAEDALUS DESTROYED", size: 30,
                                color: SKColor(red: 1, green: 0.4, blue: 0.4, alpha: 1))
        title.position = CGPoint(x: 0, y: 40)
        title.zPosition = 2001
        cam.addChild(title)

        let record = HighScoreStore.shared.highScore
        let sub = bannerLabel("FINAL SCORE \(score)      BEST \(record)", size: 16,
                              color: .white)
        sub.position = CGPoint(x: 0, y: 2)
        sub.zPosition = 2001
        cam.addChild(sub)

        let hint = bannerLabel("TAP TO RETURN TO MENU", size: 14,
                               color: SKColor(white: 0.8, alpha: 1))
        hint.position = CGPoint(x: 0, y: -40)
        hint.zPosition = 2001
        hint.run(.repeatForever(.sequence([.fadeAlpha(to: 0.3, duration: 0.6),
                                           .fadeAlpha(to: 1, duration: 0.6)])))
        cam.addChild(hint)
    }

    // MARK: Banners

    private func bannerLabel(_ text: String, size: CGFloat, color: SKColor) -> SKLabelNode {
        let l = SKLabelNode(fontNamed: "Menlo-Bold")
        l.text = text
        l.fontSize = size
        l.fontColor = color
        l.horizontalAlignmentMode = .center
        l.verticalAlignmentMode = .center
        return l
    }

    private func showBanner(_ text: String, sub: String) {
        let container = SKNode()
        container.zPosition = 1500
        let main = bannerLabel(text, size: 34,
                               color: SKColor(red: 0.5, green: 0.85, blue: 1, alpha: 1))
        let subtitle = bannerLabel(sub, size: 14, color: SKColor(white: 0.75, alpha: 1))
        subtitle.position = CGPoint(x: 0, y: -34)
        container.addChild(main)
        container.addChild(subtitle)
        cam.addChild(container)
        container.run(.sequence([.wait(forDuration: 2.2),
                                 .fadeOut(withDuration: 0.8),
                                 .removeFromParent()]))
    }

    // MARK: Colour helpers

    private func sectorTint(_ index: Int) -> SKColor {
        let tints: [SKColor] = [
            GC.space,
            SKColor(red: 0.08, green: 0.04, blue: 0.11, alpha: 1),
            SKColor(red: 0.02, green: 0.02, blue: 0.05, alpha: 1),
            SKColor(red: 0.10, green: 0.04, blue: 0.03, alpha: 1),
            SKColor(red: 0.09, green: 0.06, blue: 0.03, alpha: 1),
            SKColor(red: 0.02, green: 0.02, blue: 0.04, alpha: 1)
        ]
        return tints[(index - 1) % tints.count]
    }

    private func lerpColor(_ a: SKColor, _ b: SKColor, _ t: CGFloat) -> SKColor {
        var ar: CGFloat = 0, ag: CGFloat = 0, ab: CGFloat = 0, aa: CGFloat = 0
        var br: CGFloat = 0, bg: CGFloat = 0, bb: CGFloat = 0, ba: CGFloat = 0
        _ = a.getRed(&ar, green: &ag, blue: &ab, alpha: &aa)
        _ = b.getRed(&br, green: &bg, blue: &bb, alpha: &ba)
        return SKColor(red: ar + (br - ar) * t,
                       green: ag + (bg - ag) * t,
                       blue: ab + (bb - ab) * t,
                       alpha: aa + (ba - aa) * t)
    }

    // MARK: Touch input

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if isGameOver {
            onReturnToMenu?()
            return
        }
        for t in touches {
            controls.touchDown(ObjectIdentifier(t), at: t.location(in: cam))
        }
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        for t in touches {
            controls.touchMoved(ObjectIdentifier(t), at: t.location(in: cam))
        }
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        for t in touches { controls.touchUp(ObjectIdentifier(t)) }
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        for t in touches { controls.touchUp(ObjectIdentifier(t)) }
    }
}
