//
//  Enemy.swift
//  DaedalusiOS
//
//  Spec-driven hostiles ported from the desktop roster:
//   - fighter  : skirmisher, keeps distance, strafes, shoots
//   - dart     : fast + fragile, dive-bombs and rams
//   - capital  : ponderous cruiser, 3-round bursts + flak, very tanky
//

import SpriteKit

enum EnemyKind {
    case fighter, dart, capital

    var isCapital: Bool { self == .capital }
}

final class Enemy: Entity {

    let kind: EnemyKind
    let scoreValue: Int

    private var fireTimer: CGFloat
    private var strafeDir: CGFloat = Bool.random() ? 1 : -1
    private var strafeTimer: CGFloat = .random(in: 1...3)
    private var burst = 0
    private var burstTimer: CGFloat = 0
    private var flakTimer: CGFloat = .random(in: 2...4)

    init(kind: EnemyKind) {
        self.kind = kind
        switch kind {
        case .fighter:
            scoreValue = GC.fighterScore
            fireTimer = .random(in: 0.3...GC.fighterFireCd)
        case .dart:
            scoreValue = GC.dartScore
            fireTimer = .random(in: 0.2...GC.dartFireCd)
        case .capital:
            scoreValue = GC.capitalScore
            fireTimer = .random(in: 0.5...GC.capitalFireCd)
        }
        super.init()
        name = kind.isCapital ? "capital" : "enemy"
        configure()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    // MARK: Setup

    private func configure() {
        switch kind {
        case .fighter:
            radius = 14; bubbleRadius = 22
            shieldMax = GC.fighterShield; hullMax = GC.fighterHull
            shieldRegen = 8
        case .dart:
            radius = 12; bubbleRadius = 19
            shieldMax = GC.dartShield; hullMax = GC.dartHull
            shieldRegen = 6
        case .capital:
            radius = 88; bubbleRadius = 104
            shieldMax = GC.capitalShield; hullMax = GC.capitalHull
            shieldRegen = 40
        }
        shield = shieldMax
        hull = hullMax
        shieldDelay = 3.2
        zPosition = kind.isCapital ? 4 : 6
        buildArt()
        installShieldBubble(color: kind.isCapital
            ? SKColor(red: 0.5, green: 0.6, blue: 1, alpha: 1)
            : (kind == .dart ? SKColor(red: 0.6, green: 1, blue: 0.6, alpha: 1)
                             : SKColor(red: 1, green: 0.55, blue: 0.4, alpha: 1)))
    }

    private func buildArt() {
        let path = CGMutablePath()
        switch kind {
        case .fighter:
            path.move(to: CGPoint(x: 16, y: 0))
            path.addLine(to: CGPoint(x: -11, y: -10))
            path.addLine(to: CGPoint(x: -6, y: 0))
            path.addLine(to: CGPoint(x: -11, y: 10))
            path.closeSubpath()
        case .dart:
            path.move(to: CGPoint(x: 18, y: 0))
            path.addLine(to: CGPoint(x: -6, y: -3))
            path.addLine(to: CGPoint(x: -14, y: -13))
            path.addLine(to: CGPoint(x: -10, y: 0))
            path.addLine(to: CGPoint(x: -14, y: 13))
            path.addLine(to: CGPoint(x: -6, y: 3))
            path.closeSubpath()
        case .capital:
            let hl: CGFloat = 92, hw: CGFloat = 34
            path.move(to: CGPoint(x: hl, y: 0))
            path.addLine(to: CGPoint(x: hl * 0.55, y: -hw))
            path.addLine(to: CGPoint(x: -hl, y: -hw * 0.8))
            path.addLine(to: CGPoint(x: -hl, y: hw * 0.8))
            path.addLine(to: CGPoint(x: hl * 0.55, y: hw))
            path.closeSubpath()
        }

        let body = SKShapeNode(path: path)
        switch kind {
        case .fighter: body.fillColor = SKColor(red: 1, green: 0.43, blue: 0.32, alpha: 1)
        case .dart:    body.fillColor = SKColor(red: 0.47, green: 0.8, blue: 0.47, alpha: 1)
        case .capital: body.fillColor = SKColor(red: 0.6, green: 0.6, blue: 0.72, alpha: 1)
        }
        body.strokeColor = SKColor(white: 0.12, alpha: 1)
        body.lineWidth = kind.isCapital ? 3 : 1.5
        addChild(body)
        hullShape = body
        baseFill = body.fillColor

        if kind.isCapital {
            let engine = SKShapeNode(circleOfRadius: 9)
            engine.fillColor = SKColor(red: 0.5, green: 0.7, blue: 1, alpha: 1)
            engine.strokeColor = .clear
            engine.blendMode = .add
            engine.position = CGPoint(x: -92, y: 0)
            addChild(engine)
        }
    }

    // MARK: Per-frame

    func update(dt: CGFloat, player: PlayerShip, scene: GameScene) {
        switch kind {
        case .fighter, .dart: skirmish(dt: dt, player: player, scene: scene)
        case .capital:        capital(dt: dt, player: player, scene: scene)
        }
        stepEntity(dt)
    }

    private func skirmish(dt: CGFloat, player: PlayerShip, scene: GameScene) {
        let toPlayer = player.position - position
        let dist = toPlayer.length
        if dist > 1 { zRotation = approachAngle(zRotation, toPlayer.angle, 7 * dt) }

        let head = CGVector(angle: zRotation)
        let keep = kind == .dart ? GC.dartKeepDist : GC.fighterKeepDist
        let thrust = kind == .dart ? GC.dartThrust : GC.fighterThrust
        if dist > keep + 60 { velocity += head * thrust * dt }
        else if dist < keep - 60 { velocity -= head * thrust * dt }

        let perp = CGVector(angle: zRotation + .pi / 2) * strafeDir
        velocity += perp * (thrust * 0.6) * dt
        strafeTimer -= dt
        if strafeTimer <= 0 { strafeDir *= -1; strafeTimer = .random(in: 1...3) }

        velocity *= 0.99
        let cap = kind == .dart ? GC.dartMaxSpeed : GC.fighterMaxSpeed
        if velocity.lengthSquared > cap * cap { velocity = velocity.scaled(to: cap) }

        let engage = kind == .dart ? GC.dartEngage : GC.fighterEngage
        fireTimer -= dt
        if fireTimer <= 0 && dist < engage {
            fireTimer = (kind == .dart ? GC.dartFireCd : GC.fighterFireCd) * .random(in: 0.8...1.3)
            let lead = player.position + player.velocity * 0.15
            let aim = (lead - position).normalized
            let shot = Projectile(kind: .enemyGun, friendly: false,
                                  position: position + aim * radius,
                                  velocity: aim * (kind == .dart ? GC.dartGunSpeed : GC.fighterGunSpeed),
                                  damage: kind == .dart ? GC.dartGunDamage : GC.fighterGunDamage,
                                  life: 1.8)
            scene.add(projectile: shot)
        }

        // dart ram
        if kind == .dart, dist < radius + player.radius + 6 {
            let d = (position - player.position).normalized
            player.takeDamage(GC.dartRam, from: -d)
            velocity = d * (GC.dartMaxSpeed * 0.6)
            scene.registerShake(6)
        }
    }

    private func capital(dt: CGFloat, player: PlayerShip, scene: GameScene) {
        let toPlayer = player.position - position
        let dist = toPlayer.length
        zRotation = approachAngle(zRotation, toPlayer.angle, GC.capitalTurnRate * dt)

        let head = CGVector(angle: zRotation)
        if dist > GC.capitalKeepDist + 160 { velocity += head * 24 * dt }
        else if dist < GC.capitalKeepDist { velocity -= head * 24 * dt }
        velocity *= 0.98
        if velocity.lengthSquared > GC.capitalMaxSpeed * GC.capitalMaxSpeed {
            velocity = velocity.scaled(to: GC.capitalMaxSpeed)
        }

        let inRange = dist < GC.capitalEngage
        let muzzle = radius + 6

        fireTimer -= dt
        if fireTimer <= 0 && burst == 0 && inRange {
            burst = 3
            burstTimer = 0
            fireTimer = GC.capitalFireCd + .random(in: 0...0.8)
        }
        if burst > 0 {
            burstTimer -= dt
            if burstTimer <= 0 {
                burst -= 1
                burstTimer = 0.16
                let aim = (player.position + player.velocity * 0.25 - position)
                    .normalized
                    .rotated(by: .random(in: -0.05...0.05))
                let shell = Projectile(kind: .enemyHeavy, friendly: false,
                                       position: position + aim * muzzle,
                                       velocity: aim * GC.capitalGunSpeed,
                                       damage: GC.capitalGunDamage, life: 2.6)
                scene.add(projectile: shell)
            }
        }

        flakTimer -= dt
        if flakTimer <= 0 {
            flakTimer = .random(in: 2.4...4.2)
            if inRange {
                for _ in 0..<10 {
                    let d = CGVector(angle: .random(in: 0...(2 * .pi)))
                    let f = Projectile(kind: .flak, friendly: false,
                                       position: position + d * muzzle,
                                       velocity: d * CGFloat.random(in: 240...380),
                                       damage: GC.capitalFlakDamage, life: 2.2)
                    scene.add(projectile: f)
                }
            }
        }
    }
}
