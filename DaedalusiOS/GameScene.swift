//
//  GameScene.swift
//  DaedalusiOS
//
//  The open-world combat sim: camera-follow flight through ten hyperdrive
//  sectors, spec-driven hostiles, allied wingmen, the Asgard beam, the cloak,
//  homing salvos, the replicator infestation, and the tactical hyperdrive.
//  Collision + AI are deterministic (no physics bodies).
//

import SpriteKit

final class GameScene: SKScene {

    var onReturnToMenu: (() -> Void)?

    private let cam = SKCameraNode()
    private let starfield = Starfield()
    private let hud = HUD()
    private let controls = TouchControls()
    private let player = PlayerShip()
    private let hyperUI = HyperdriveOverlay()

    private var enemies: [Enemy] = []
    private var allies: [Ally] = []
    private var friendlyShots: [Projectile] = []
    private var enemyShots: [Projectile] = []
    private var landmarks: [Landmark] = []
    private var landmarkCache: [Int: [Landmark]] = [:]

    private var lastTime: TimeInterval = 0
    private var spawnTimer: CGFloat = 2.5
    private var score = 0
    private var shake: CGFloat = 0
    private var flash: CGFloat = 0
    private var isGameOver = false
    private var didReportScore = false
    private var replicatorDestroyed = false

    // sector / hyperdrive
    private var sectorIndex = 0
    private var sector: SectorSpec { Sectors.all[sectorIndex] }
    private enum Hyper { case idle, charging, travel }
    private var hyper: Hyper = .idle
    private var hyperTimer: CGFloat = 0
    private var hyperChargeDur: CGFloat = 2
    private var hyperTravelDur: CGFloat = 3.5
    private var hyperTarget = 0
    private var picking = false

    private var beamSeg: (CGPoint, CGPoint)?
    private var beamNode: SKShapeNode?
    private var beamCoreNode: SKShapeNode?
    private var flashNode: SKSpriteNode?

    // MARK: Lifecycle

    override func didMove(to view: SKView) {
        scaleMode = .resizeFill
        isUserInteractionEnabled = true
        view.isMultipleTouchEnabled = true    // rotate + fire at the same time

        camera = cam
        addChild(cam)
        cam.addChild(starfield)
        cam.addChild(hud)
        cam.addChild(controls)
        cam.addChild(hyperUI)
        starfield.zPosition = -100

        addChild(player)

        let beam = SKShapeNode()
        beam.strokeColor = SKColor(red: 0.85, green: 0.97, blue: 1, alpha: 1)
        beam.lineWidth = 14
        beam.glowWidth = 26
        beam.lineCap = .round
        beam.blendMode = .add
        beam.zPosition = 20
        beam.isHidden = true
        addChild(beam)

        let beamCore = SKShapeNode()
        beamCore.strokeColor = .white
        beamCore.lineWidth = 5
        beamCore.lineCap = .round
        beamCore.blendMode = .add
        beamCore.zPosition = 21
        beamCore.isHidden = true
        addChild(beamCore)
        beamCoreNode = beamCore
        beamNode = beam

        let fl = SKSpriteNode(color: SKColor(red: 1, green: 0.96, blue: 0.88, alpha: 1),
                              size: CGSize(width: 4000, height: 4000))
        fl.zPosition = 2500
        fl.alpha = 0
        cam.addChild(fl)
        flashNode = fl

        controls.onTap = { [weak self] pad in self?.handleTapPad(pad) }
        hyperUI.onPick = { [weak self] idx in self?.finishPicking(idx) }

        startNewGame()
    }

    override func didChangeSize(_ oldSize: CGSize) {
        guard size.width > 0, size.height > 0 else { return }
        hud.layout(size: size)
        controls.layout(size: size)
        starfield.build(viewSize: size)
    }

    private func startNewGame() {
        enemies.forEach { $0.removeFromParent() }; enemies.removeAll()
        allies.forEach { $0.removeFromParent() }; allies.removeAll()
        friendlyShots.forEach { $0.removeFromParent() }; friendlyShots.removeAll()
        enemyShots.forEach { $0.removeFromParent() }; enemyShots.removeAll()
        cam.children.filter { $0.name == "over" }.forEach { $0.removeFromParent() }

        score = 0
        isGameOver = false
        didReportScore = false
        replicatorDestroyed = false
        hyper = .idle
        sectorIndex = min(max(0, Settings.shared.startSector), Sectors.all.count - 1)

        player.resetForNewGame()
        player.position = .zero
        controls.configure(hasBeam: player.hasBeam)
        controls.setActiveInput(true)

        hud.layout(size: size)
        controls.layout(size: size)
        starfield.build(viewSize: size)
        loadSectorScenery()
        backgroundColor = sector.tint
        spawnTimer = 2.5

        for i in 0..<min(Settings.shared.startWingmen, GC.allyMaxWingmen) { spawnAlly(slot: i) }
        banner(sector.name.components(separatedBy: "//").first!.uppercased(),
               sub: "open-world space combat")
    }

    // MARK: Scenery

    private func loadSectorScenery() {
        landmarks.forEach { $0.removeFromParent() }
        let marks = landmarkCache[sectorIndex] ?? {
            let built = sector.scenery.map { Landmark($0) }
            landmarkCache[sectorIndex] = built
            return built
        }()
        landmarks = marks
        for m in marks {
            m.reposition(around: player.position)
            addChild(m)
        }
    }

    // MARK: Scene-facing helpers

    func add(projectile p: Projectile) {
        addChild(p)
        if p.friendly { friendlyShots.append(p) } else { enemyShots.append(p) }
    }
    func registerShake(_ a: CGFloat) { shake = max(shake, a) }

    func spawnTrailPuff(at pos: CGPoint, color: SKColor) {
        let d = SKShapeNode(circleOfRadius: .random(in: 2...4))
        d.position = pos
        d.fillColor = color; d.strokeColor = .clear; d.blendMode = .add
        d.zPosition = 2
        addChild(d)
        d.run(.sequence([.group([.fadeOut(withDuration: 0.4),
                                 .scale(to: 0.2, duration: 0.4)]), .removeFromParent()]))
    }

    func nearestEnemy(to pos: CGPoint) -> Enemy? {
        enemies.filter { !$0.isDead }.min { $0.position.distanceSquared(to: pos) < $1.position.distanceSquared(to: pos) }
    }

    func enemiesWithin(_ r2: CGFloat, of pos: CGPoint) -> [Enemy] {
        enemies.filter { !$0.isDead && $0.position.distanceSquared(to: pos) < r2 }
            .sorted { $0.position.distanceSquared(to: pos) < $1.position.distanceSquared(to: pos) }
    }

    func homingTargets(near pos: CGPoint, facing head: CGVector, range: CGFloat) -> [Entity] {
        var scored: [(CGFloat, Enemy)] = []
        for e in enemies where !e.isDead {
            let rel = e.position - pos
            let d = rel.length
            if d > range { continue }
            scored.append((d * (rel.dot(head) > 0 ? 1 : 1.8), e))
        }
        return scored.sorted { $0.0 < $1.0 }.map { $0.1 }
    }

    func friendlies() -> [Entity] { [player] + allies }

    func formationOffset(_ slot: Int) -> CGVector {
        let side: CGFloat = slot % 2 == 0 ? 1 : -1
        let rank = CGFloat(slot / 2 + 1)
        let back = -CGVector(angle: player.zRotation)
        let perp = CGVector(dx: -back.dy, dy: back.dx)
        return back * (40 * rank) + perp * (side * 46 * rank)
    }

    func enemyRequestsSpawn(_ kind: EnemyKind, near pos: CGPoint, radius: CGFloat) {
        guard enemies.count < GC.maxEnemies else { return }
        let e = Enemy(kind: kind)
        e.position = pos + CGVector(angle: .random(in: 0...(2 * .pi))) * radius
        addChild(e); enemies.append(e)
    }

    // ---- beam ----
    func setBeam(_ seg: (CGPoint, CGPoint)?) { beamSeg = seg }

    func applyBeam(origin: CGPoint, dir: CGVector, dps: CGFloat) -> CGPoint {
        // A wide piercing swath -- it damages EVERY enemy whose centre is within
        // `swath` of the ray, near and far alike (touch aim is coarse, so the
        // damage zone matches the glow instead of a hairline).
        let swath: CGFloat = 30
        var farthest: CGFloat = 320                       // min visible length
        for e in enemies where !e.isDead {
            let rel = e.position - origin
            let t = rel.dot(dir)
            if t < -e.radius || t > GC.beamRange { continue }
            let perp = (rel - dir * t).length
            guard perp <= e.radius + swath else { continue }
            if Settings.shared.oneShotKill { e.kill() }
            else { e.takeDamage(dps, from: -dir) }
            farthest = max(farthest, min(GC.beamRange, t + e.radius))
            if Bool.random() {
                spawnTrailPuff(at: origin + dir * max(0, t),
                               color: SKColor(red: 0.6, green: 0.95, blue: 1, alpha: 1))
            }
        }
        return origin + dir * farthest
    }

    // MARK: Main loop

    override func update(_ currentTime: TimeInterval) {
        if lastTime == 0 { lastTime = currentTime }
        var dt = CGFloat(currentTime - lastTime)
        lastTime = currentTime
        guard dt > 0 else { return }
        dt = min(dt, 1.0 / 20.0)

        let frozen = isGameOver || picking || hyper != .idle

        updateHyperdrive(dt)

        if !frozen {
            player.update(dt: dt, input: controls.state, scene: self)
            for a in allies { a.update(dt: dt, player: player, scene: self) }
            for e in enemies { e.update(dt: dt, player: player, scene: self) }
            for s in friendlyShots { s.step(dt) }
            for s in enemyShots { s.step(dt) }
            handleCollisions()
            cull()
            updateSpawning(dt)
            if player.hull <= 0 && !Settings.shared.godMode { triggerGameOver() }
        } else if isGameOver {
            beamSeg = nil
        }

        // camera + shake + flash
        shake *= 0.85
        flash = max(0, flash - dt * 1.6)
        let jitter = CGVector(dx: .random(in: -1...1), dy: .random(in: -1...1)) * shake
        cam.position = player.position + jitter
        starfield.update(cameraPos: cam.position, streak: starfieldStreak(),
                         facing: CGVector(angle: player.zRotation))
        flashNode?.alpha = clampf(flash * 0.9, 0, 0.85)

        drawBeamVisual()

        hud.update(player: player, score: score, sector: Sectors.shortName(sectorIndex),
                   hostiles: enemies.count, wingmen: allies.count,
                   hyper: hyperStatusText())
    }

    private func starfieldStreak() -> CGFloat {
        switch hyper {
        case .charging: return 1 - clampf(hyperTimer / max(0.01, hyperChargeDur), 0, 1)
        case .travel:   return 1
        case .idle:     return 0
        }
    }

    private func drawBeamVisual() {
        guard let (o, e) = beamSeg, let n = beamNode else {
            beamNode?.isHidden = true; beamCoreNode?.isHidden = true; return
        }
        n.isHidden = false
        beamCoreNode?.isHidden = false
        let jit = CGVector(dx: .random(in: -2...2), dy: .random(in: -2...2))
        let p = CGMutablePath()
        p.move(to: o)
        p.addLine(to: e + jit)
        n.path = p
        beamCoreNode?.path = p
    }

    // MARK: Collisions

    private func handleCollisions() {
        for shot in friendlyShots where !shot.isDead {
            for e in enemies where !e.isDead {
                let surfR = (e.shield > 0 ? e.bubbleRadius : e.radius) + shot.hitRadius
                guard shot.position.distanceSquared(to: e.position) <= surfR * surfR else { continue }
                let dirOut = (shot.position - e.position).normalized
                let contact = e.position + dirOut * (e.shield > 0 ? e.bubbleRadius : e.radius)
                let shielded = e.shield > 0
                if Settings.shared.oneShotKill { e.kill() }
                else { e.takeDamage(shot.damage, from: dirOut) }

                if shot.splashRadius > 0 {
                    Effects.explosion(in: self, at: contact, scale: shot.kind == .rocket ? 1.5 : 1.2)
                    registerShake(shot.kind == .rocket ? 9 : 6)
                    for o in enemies where !o.isDead {
                        if contact.distance(to: o.position) <= shot.splashRadius + o.radius {
                            o.takeDamage(shot.splashDamage, from: (o.position - contact).normalized)
                        }
                    }
                } else {
                    Effects.hitSpark(in: self, at: contact, shielded: shielded)
                }
                shot.isDead = true
                break
            }
        }

        // enemy shots vs player + allies
        for shot in enemyShots where !shot.isDead {
            for target in friendlies() where !target.isDead {
                if let pl = target as? PlayerShip, pl.cloaked || pl.invuln > 0 { continue }
                let surfR = (target.shield > 0 ? target.bubbleRadius : target.radius) + shot.hitRadius
                guard shot.position.distanceSquared(to: target.position) <= surfR * surfR else { continue }
                let dirOut = (shot.position - target.position).normalized
                let contact = target.position + dirOut * (target.shield > 0 ? target.bubbleRadius : target.radius)

                if shot.kind == .infest {
                    if target.shieldHardened && target.shield > 0 {
                        Effects.hitSpark(in: self, at: contact, shielded: true)
                    } else {
                        target.infect()
                        Effects.hitSpark(in: self, at: contact, shielded: false)
                    }
                } else {
                    Effects.hitSpark(in: self, at: contact, shielded: target.shield > 0)
                    target.takeDamage(shot.damage, from: dirOut)
                    if target is PlayerShip { registerShake(shot.kind == .enemyHeavy ? 7 : 4) }
                }
                shot.isDead = true
                break
            }
        }

        // body ram
        if player.invuln <= 0 && !player.cloaked {
            for e in enemies where !e.isDead {
                guard player.position.distance(to: e.position) <= player.radius + e.radius else { continue }
                let d = (player.position - e.position).normalized
                player.takeDamage(GC.ramDamage, from: -d)
                e.takeDamage(GC.ramDamage * 1.5, from: d)
                player.velocity += d * 240
                e.velocity -= d * 180
                player.invuln = max(player.invuln, 0.6)
                registerShake(7)
                break
            }
        }
        for a in allies where !a.isDead {
            for e in enemies where !e.isDead {
                if a.position.distance(to: e.position) <= a.radius + e.radius {
                    let d = (a.position - e.position).normalized
                    a.takeDamage(GC.ramDamage * 0.6, from: -d)
                    e.takeDamage(GC.ramDamage, from: d)
                    a.velocity += d * 200
                }
            }
        }
    }

    // MARK: Cull

    private func cull() {
        for e in enemies where e.isDead {
            score += e.scoreValue
            let big = e.kind.isCapital
            Effects.explosion(in: self, at: e.position, scale: big ? 3.1 : 1.3)
            registerShake(big ? 28 : 9)
            if big { flash = max(flash, 0.12) }
            if e.kind == .replicator {
                replicatorDestroyed = true
                player.infested = 0
                allies.forEach { $0.infested = 0 }
                Effects.explosion(in: self, at: e.position, scale: 3.4)
                flash = max(flash, 0.18)
                banner("REPLICATOR SHIP DESTROYED", sub: "infestation severed")
            }
            e.removeFromParent()
        }
        enemies.removeAll { $0.isDead }

        for a in allies where a.isDead {
            Effects.explosion(in: self, at: a.position, scale: 1.1)
            registerShake(8)
            a.removeFromParent()
        }
        allies.removeAll { $0.isDead }

        for s in friendlyShots where s.isDead { s.removeFromParent() }
        friendlyShots.removeAll { $0.isDead }
        for s in enemyShots where s.isDead { s.removeFromParent() }
        enemyShots.removeAll { $0.isDead }

        enemies.removeAll { e in
            if e.position.distanceSquared(to: player.position) > GC.enemyLeash * GC.enemyLeash {
                Effects.explosion(in: self, at: e.position, scale: 0.7)
                e.removeFromParent(); return true
            }
            return false
        }
        let far: CGFloat = 2000 * 2000
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

    /// Concurrent-hostile budget: sector danger scaled by difficulty. On
    /// BRUTAL an EXTREME sector fills right up to the hard cap.
    private var hostileTarget: Int {
        let base = CGFloat(3 + sector.danger * 2)          // 3 (safe) .. 9 (EXTREME)
        return min(GC.maxEnemies, max(2, Int((base * Settings.shared.spawnMult).rounded())))
    }
    private var capitalCap: Int {
        let d = Settings.shared.difficulty
        let bonus = (d == .brutal ? 2 : d == .hard ? 1 : 0)
        return min(GC.maxEnemies, GC.maxCapitals + (sector.danger >= 2 ? bonus : 0))
    }

    private func updateSpawning(_ dt: CGFloat) {
        guard sector.spawns, enemies.count < GC.maxEnemies else { return }
        spawnTimer -= dt
        guard spawnTimer <= 0 else { return }

        let target = hostileTarget
        if enemies.count >= target { spawnTimer = 1.5; return }

        let lo = sector.fighterCd.lowerBound, hi = sector.fighterCd.upperBound
        spawnTimer = CGFloat.random(in: lo...hi) / Settings.shared.spawnMult
        let pool: [EnemyKind] = sector.mix.flatMap { Array(repeating: $0.0, count: $0.1) }
        let wave = max(1, Int((CGFloat(1 + sector.danger / 2 + Int.random(in: 0...sector.danger))
                               * Settings.shared.spawnMult).rounded()))
        for _ in 0..<min(wave, target - enemies.count) {
            spawnRing(pool.randomElement() ?? .fighter)
        }
    }

    private func spawnRing(_ kind: EnemyKind) {
        if kind.isCapital, enemies.filter({ $0.kind.isCapital }).count >= capitalCap { return }
        if kind == .replicator {
            if replicatorDestroyed || enemies.contains(where: { $0.kind == .replicator }) { return }
        }
        let e = Enemy(kind: kind)
        let d: CGFloat = kind.isCapital ? .random(in: 760...1050) : .random(in: 500...820)
        e.position = player.position + CGVector(angle: .random(in: 0...(2 * .pi))) * d
        e.zRotation = (player.position - e.position).angle
        addChild(e); enemies.append(e)
    }

    private func spawnAlly(slot: Int? = nil) {
        guard allies.count < GC.allyMaxWingmen else { return }
        let s: Int
        if let slot { s = slot } else {
            let used = Set(allies.map { $0.formSlot })
            var n = 0; while used.contains(n) { n += 1 }; s = n
        }
        let a = Ally(formSlot: s)
        a.position = player.position + formationOffset(s)
        a.zRotation = player.zRotation
        a.velocity = player.velocity
        a.invuln = 0.6
        addChild(a); allies.append(a)
        Effects.hitSpark(in: self, at: a.position, shielded: true)
    }

    // MARK: Hyperdrive

    private func handleTapPad(_ pad: TouchControls.Pad) {
        guard !isGameOver else { return }
        switch pad {
        case .cloak: player.toggleCloak()
        case .wing:  spawnAlly()
        case .jump:
            guard hyper == .idle, !picking else { return }
            picking = true
            player.setCloakOff()
            hyperUI.present(size: size, currentIndex: sectorIndex)
        default: break
        }
    }

    private func finishPicking(_ idx: Int?) {
        picking = false
        guard let idx, idx != sectorIndex else { return }
        hyperTarget = idx
        let dst = Sectors.all[idx]
        hyperChargeDur = dst.charge
        hyperTravelDur = dst.travel
        hyperTimer = hyperChargeDur
        hyper = .charging
    }

    private func updateHyperdrive(_ dt: CGFloat) {
        switch hyper {
        case .idle: break
        case .charging:
            hyperTimer -= dt
            if hyperTimer <= 0 { hyper = .travel; hyperTimer = hyperTravelDur; completeJump() }
        case .travel:
            hyperTimer -= dt
            if hyperTimer <= 0 { hyper = .idle }
        }
    }

    private func completeJump() {
        enemies.forEach { $0.removeFromParent() }; enemies.removeAll()
        friendlyShots.forEach { $0.removeFromParent() }; friendlyShots.removeAll()
        enemyShots.forEach { $0.removeFromParent() }; enemyShots.removeAll()

        sectorIndex = hyperTarget
        player.velocity *= 0.15
        player.invuln = GC.hyperInvuln
        player.infested = 0
        allies.forEach { $0.infested = 0; $0.invuln = GC.hyperInvuln }
        spawnTimer = 2.5

        loadSectorScenery()
        run(.customAction(withDuration: 0.6) { [weak self] _, t in
            guard let self else { return }
            self.backgroundColor = self.sector.tint
            _ = t
        })
        backgroundColor = sector.tint
        flash = 0.4
        Effects.explosion(in: self, at: player.position, scale: 2.2)

        for (i, a) in allies.enumerated() {
            a.position = player.position + CGVector(dx: -60 - 24 * CGFloat(i),
                                                    dy: (i % 2 == 0 ? 1 : -1) * 55)
            a.velocity = player.velocity
        }

        if sector.uniqueSpawn == .replicator && !replicatorDestroyed {
            spawnRing(.replicator)
            banner("REPLICATOR SHIP DETECTED", sub: "destroy it before it infests you")
        } else {
            banner("SECTOR  \(sectorIndex + 1)", sub: Sectors.shortName(sectorIndex))
        }
    }

    private func hyperStatusText() -> String? {
        switch hyper {
        case .idle: return nil
        case .charging:
            return "HYPERDRIVE SPOOLING  \(String(format: "%.1f", max(0, hyperTimer)))s"
        case .travel:
            return "IN TRANSIT  ->  \(Sectors.shortName(hyperTarget))   ETA \(String(format: "%04.1f", max(0, hyperTimer)))s"
        }
    }

    // MARK: Game over

    private func triggerGameOver() {
        guard !isGameOver else { return }
        isGameOver = true
        Effects.explosion(in: self, at: player.position, scale: 4.4)
        registerShake(38); flash = 0.5
        player.isHidden = true
        controls.setActiveInput(false)
        beamSeg = nil

        if !didReportScore { didReportScore = true; HighScoreStore.shared.submit(score) }

        let dim = SKSpriteNode(color: SKColor(red: 0.12, green: 0, blue: 0, alpha: 0.6),
                               size: CGSize(width: size.width * 2, height: size.height * 2))
        dim.zPosition = 2600; dim.name = "over"; cam.addChild(dim)
        addOver("DAEDALUS DESTROYED", 30, SKColor(red: 1, green: 0.4, blue: 0.4, alpha: 1), y: 40)
        addOver("FINAL SCORE \(score)     BEST \(HighScoreStore.shared.highScore)", 16, .white, y: 2)
        let hint = addOver("TAP TO RETURN TO MENU", 14, SKColor(white: 0.8, alpha: 1), y: -40)
        hint.run(.repeatForever(.sequence([.fadeAlpha(to: 0.3, duration: 0.6),
                                           .fadeAlpha(to: 1, duration: 0.6)])))
    }

    @discardableResult
    private func addOver(_ text: String, _ sz: CGFloat, _ col: SKColor, y: CGFloat) -> SKLabelNode {
        let l = label(text, sz, col); l.position = CGPoint(x: 0, y: y)
        l.zPosition = 2601; l.name = "over"; cam.addChild(l); return l
    }

    // MARK: Banners

    private func label(_ text: String, _ sz: CGFloat, _ col: SKColor) -> SKLabelNode {
        let l = SKLabelNode(fontNamed: "Menlo-Bold")
        l.text = text; l.fontSize = sz; l.fontColor = col
        l.horizontalAlignmentMode = .center; l.verticalAlignmentMode = .center
        return l
    }

    private func banner(_ text: String, sub: String) {
        let c = SKNode(); c.zPosition = 1500
        let m = label(text, 30, SKColor(red: 0.5, green: 0.85, blue: 1, alpha: 1))
        let s = label(sub, 13, SKColor(white: 0.75, alpha: 1)); s.position.y = -30
        c.addChild(m); c.addChild(s)
        cam.addChild(c)
        c.run(.sequence([.wait(forDuration: 2.2), .fadeOut(withDuration: 0.8), .removeFromParent()]))
    }

    // MARK: Touch input

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if isGameOver { onReturnToMenu?(); return }
        for t in touches {
            let p = t.location(in: cam)
            if picking { hyperUI.handleTap(t.location(in: hyperUI)); continue }
            controls.touchDown(ObjectIdentifier(t), at: p)
        }
    }
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard !picking else { return }
        for t in touches { controls.touchMoved(ObjectIdentifier(t), at: t.location(in: cam)) }
    }
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        for t in touches { controls.touchUp(ObjectIdentifier(t)) }
    }
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        for t in touches { controls.touchUp(ObjectIdentifier(t)) }
    }
}
