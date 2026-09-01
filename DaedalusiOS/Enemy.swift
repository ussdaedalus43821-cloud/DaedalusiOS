//
//  Enemy.swift
//  DaedalusiOS
//
//  Spec-driven hostiles, ported from the desktop ENEMIES table:
//   fighter   – skirmisher (keeps distance, strafes, shoots)
//   dart      – Wraith Dart: fast, fragile, dive-bombs and rams
//   wcruiser  – Wraith cruiser: beefy skirmisher
//   capital   – Goa'uld Ha'tak: ponderous, 3-round bursts + flak
//   whive     – Wraith Hive: capital that spawns Darts
//   ori       – Ori mothership: capital with a charged GOLD beam
//   replicator– the ONE replicator ship: fires infestation bolts
//

import SpriteKit

enum EnemyKind: CaseIterable {
    case fighter, dart, wcruiser, capital, whive, ori, replicator

    var isCapital: Bool { self == .capital || self == .whive || self == .ori }
}

enum EnemyAI { case skirmish, dart, capital, replicator }

struct EnemySpec {
    var ai: EnemyAI
    var radius: CGFloat
    var bubblePad: CGFloat
    var shield: CGFloat
    var shieldRegen: CGFloat
    var hull: CGFloat
    var score: Int
    var thrust: CGFloat = 0
    var maxSpeed: CGFloat
    var turn: CGFloat = 6                 // rad/s (capitals slow)
    var keepDist: CGFloat = 320
    var engage: CGFloat = 820
    var fireCd: CGFloat = 1.1
    var gunDmg: CGFloat = 10
    var gunSpeed: CGFloat = 640
    var bolt: ProjectileKind = .enemyGun
    var burstN = 1
    var flak = false
    var flakDmg: CGFloat = 6
    var ram: CGFloat = 0
    var spawns: EnemyKind? = nil
    var spawnCd: ClosedRange<CGFloat> = 5...9
    // Ori beam
    var beam = false
    var beamDmg: CGFloat = 0
    var beamRange: CGFloat = 1000
    var beamCharge: CGFloat = 1.1
    var beamDur: CGFloat = 1.5
    var beamCd: ClosedRange<CGFloat> = 5.5...8.5
    var fill: SKColor = .gray
    var shieldColor: SKColor = SKColor(white: 0.7, alpha: 1)
    var hardened = false
}

enum Enemies {
    static func spec(_ k: EnemyKind) -> EnemySpec {
        switch k {
        case .fighter:
            return EnemySpec(ai: .skirmish, radius: 14, bubblePad: 8,
                shield: 150, shieldRegen: 8, hull: 130, score: 100,
                thrust: 340, maxSpeed: 260, turn: 7, keepDist: 320, engage: 780,
                fireCd: 1.2, gunDmg: 10, gunSpeed: 620,
                fill: SKColor(red: 1, green: 0.43, blue: 0.32, alpha: 1),
                shieldColor: SKColor(red: 1, green: 0.55, blue: 0.4, alpha: 1))
        case .dart:
            return EnemySpec(ai: .dart, radius: 12, bubblePad: 7,
                shield: 40, shieldRegen: 6, hull: 70, score: 140,
                thrust: 540, maxSpeed: 380, turn: 9, keepDist: 200, engage: 760,
                fireCd: 0.7, gunDmg: 7, gunSpeed: 700, ram: 22,
                fill: SKColor(red: 0.47, green: 0.8, blue: 0.47, alpha: 1),
                shieldColor: SKColor(red: 0.6, green: 1, blue: 0.6, alpha: 1))
        case .wcruiser:
            return EnemySpec(ai: .skirmish, radius: 24, bubblePad: 10,
                shield: 620, shieldRegen: 12, hull: 520, score: 350,
                thrust: 210, maxSpeed: 210, turn: 4, keepDist: 430, engage: 880,
                fireCd: 1.35, gunDmg: 12, gunSpeed: 520,
                fill: SKColor(red: 0.42, green: 0.7, blue: 0.45, alpha: 1),
                shieldColor: SKColor(red: 0.55, green: 1, blue: 0.6, alpha: 1))
        case .capital:
            return EnemySpec(ai: .capital, radius: 88, bubblePad: 16,
                shield: 1500, shieldRegen: 40, hull: 2800, score: 3000,
                maxSpeed: 60, turn: 0.42, keepDist: 520, engage: 980,
                fireCd: 2.0, gunDmg: 12, gunSpeed: 440, bolt: .enemyHeavy,
                burstN: 3, flak: true, flakDmg: 5,
                fill: SKColor(red: 0.6, green: 0.6, blue: 0.72, alpha: 1),
                shieldColor: SKColor(red: 0.5, green: 0.6, blue: 1, alpha: 1))
        case .whive:
            return EnemySpec(ai: .capital, radius: 116, bubblePad: 18,
                shield: 2400, shieldRegen: 45, hull: 5000, score: 6000,
                maxSpeed: 44, turn: 0.28, keepDist: 560, engage: 1000,
                fireCd: 1.7, gunDmg: 15, gunSpeed: 430, bolt: .enemyHeavy,
                burstN: 3, flak: true, flakDmg: 7,
                spawns: .dart, spawnCd: 5...9,
                fill: SKColor(red: 0.42, green: 0.62, blue: 0.42, alpha: 1),
                shieldColor: SKColor(red: 0.55, green: 1, blue: 0.6, alpha: 1))
        case .ori:
            return EnemySpec(ai: .capital, radius: 100, bubblePad: 16,
                shield: 3400, shieldRegen: 55, hull: 3600, score: 5500,
                maxSpeed: 70, turn: 0.4, keepDist: 640, engage: 1050,
                fireCd: 2.4, gunDmg: 40, gunSpeed: 560, bolt: .enemyHeavy, burstN: 1,
                beam: true, beamDmg: 1500, beamRange: 1150,
                beamCharge: 1.15, beamDur: 1.5, beamCd: 5.5...8.5,
                fill: SKColor(red: 0.82, green: 0.68, blue: 0.42, alpha: 1),
                shieldColor: SKColor(red: 1, green: 0.82, blue: 0.45, alpha: 1))
        case .replicator:
            return EnemySpec(ai: .replicator, radius: 26, bubblePad: 10,
                shield: 850, shieldRegen: 18, hull: 950, score: 3000,
                thrust: 350, maxSpeed: 400, turn: 6, keepDist: 380, engage: 920,
                fireCd: GC.infestBoltCd, gunSpeed: GC.infestBoltSpeed, bolt: .infest,
                fill: SKColor(red: 0.78, green: 0.8, blue: 0.9, alpha: 1),
                shieldColor: SKColor(red: 0.8, green: 0.82, blue: 0.95, alpha: 1))
        }
    }
}

final class Enemy: Entity {

    let kind: EnemyKind
    let spec: EnemySpec
    let scoreValue: Int
    var blip: SKColor { spec.fill }

    private var fireTimer: CGFloat
    private var strafeDir: CGFloat = Bool.random() ? 1 : -1
    private var strafeTimer: CGFloat = .random(in: 1...3)
    private var burst = 0
    private var burstTimer: CGFloat = 0
    private var flakTimer: CGFloat = .random(in: 2...4)
    private var spawnTimer: CGFloat = .random(in: 3...7)
    private var diveTimer: CGFloat = .random(in: 1...3)
    private var diving: CGFloat = 0

    // Ori beam
    private enum BeamState { case idle, charge, fire }
    private var beamState: BeamState = .idle
    private var beamT: CGFloat = 0
    private var beamDir = CGVector(dx: 1, dy: 0)
    private var beamCdTimer: CGFloat
    private var beamNode: SKShapeNode?

    init(kind: EnemyKind) {
        self.kind = kind
        let s = Enemies.spec(kind)
        self.spec = s
        self.scoreValue = s.score
        self.fireTimer = .random(in: 0.3...max(0.4, s.fireCd))
        self.beamCdTimer = .random(in: s.beamCd)
        super.init()
        name = kind.isCapital ? "capital" : "enemy"
        configure()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private func configure() {
        radius = spec.radius
        bubbleRadius = spec.radius + spec.bubblePad
        shieldMax = spec.shield; shield = spec.shield
        shieldRegen = spec.shieldRegen
        shieldDelay = 3.2
        shieldHardened = spec.hardened
        hullMax = spec.hull; hull = spec.hull
        zPosition = kind.isCapital ? 4 : 6
        buildArt()
        installShieldBubble(color: spec.shieldColor)
        if spec.beam {
            let n = SKShapeNode()
            n.strokeColor = SKColor(red: 1, green: 0.82, blue: 0.4, alpha: 0.9)
            n.lineWidth = 4
            n.glowWidth = 10
            n.blendMode = .add
            n.zPosition = 9
            n.isHidden = true
            addChild(n)
            beamNode = n
        }
    }

    private func buildArt() {
        let p = CGMutablePath()
        switch kind {
        case .fighter:
            p.addLines(between: [CGPoint(x: 16, y: 0), CGPoint(x: -11, y: -10),
                                 CGPoint(x: -6, y: 0), CGPoint(x: -11, y: 10)])
        case .dart:
            p.addLines(between: [CGPoint(x: 18, y: 0), CGPoint(x: -6, y: -3),
                                 CGPoint(x: -14, y: -13), CGPoint(x: -10, y: 0),
                                 CGPoint(x: -14, y: 13), CGPoint(x: -6, y: 3)])
        case .wcruiser:
            p.addLines(between: [CGPoint(x: 28, y: 0), CGPoint(x: 12, y: -14),
                                 CGPoint(x: -24, y: -16), CGPoint(x: -28, y: 0),
                                 CGPoint(x: -24, y: 16), CGPoint(x: 12, y: 14)])
        case .capital:
            capitalHex(p, hl: 92, hw: 34)
        case .whive:
            capitalHex(p, hl: 116, hw: 58)
        case .ori:
            p.addLines(between: [CGPoint(x: 100, y: 0), CGPoint(x: 30, y: -26),
                                 CGPoint(x: -70, y: -30), CGPoint(x: -96, y: -16),
                                 CGPoint(x: -96, y: 16), CGPoint(x: -70, y: 30),
                                 CGPoint(x: 30, y: 26)])
        case .replicator:
            // blocky cluster
            break
        }

        if kind == .replicator {
            for (bx, by, bs) in [(0.0, 0.0, radius * 0.9),
                                 (radius * 0.6, radius * 0.4, radius * 0.5),
                                 (-radius * 0.55, radius * 0.55, radius * 0.5),
                                 (radius * 0.3, -radius * 0.7, radius * 0.45),
                                 (-radius * 0.6, -radius * 0.4, radius * 0.4)] {
                let b = SKShapeNode(rectOf: CGSize(width: bs, height: bs))
                b.fillColor = spec.fill
                b.strokeColor = SKColor(white: 0.28, alpha: 1); b.lineWidth = 1
                b.position = CGPoint(x: bx, y: by)
                addChild(b)
                if b.position == .zero { hullShape = b; baseFill = b.fillColor }
            }
            return
        }

        p.closeSubpath()
        let body = SKShapeNode(path: p)
        body.fillColor = spec.fill
        body.strokeColor = SKColor(white: 0.12, alpha: 1)
        body.lineWidth = kind.isCapital ? 3 : 1.5
        addChild(body)
        hullShape = body
        baseFill = body.fillColor

        if kind.isCapital {
            let engine = SKShapeNode(circleOfRadius: 9)
            engine.fillColor = kind == .ori
                ? SKColor(red: 1, green: 0.8, blue: 0.4, alpha: 1)
                : SKColor(red: 0.5, green: 0.7, blue: 1, alpha: 1)
            engine.strokeColor = .clear; engine.blendMode = .add
            engine.position = CGPoint(x: -radius, y: 0)
            addChild(engine)
        }
    }

    private func capitalHex(_ p: CGMutablePath, hl: CGFloat, hw: CGFloat) {
        p.addLines(between: [CGPoint(x: hl, y: 0), CGPoint(x: hl * 0.55, y: -hw),
                             CGPoint(x: -hl, y: -hw * 0.8), CGPoint(x: -hl, y: hw * 0.8),
                             CGPoint(x: hl * 0.55, y: hw)])
    }

    // MARK: Per-frame

    func update(dt: CGFloat, player: PlayerShip, scene: GameScene) {
        if spec.beam { updateBeam(dt: dt, player: player, scene: scene) }
        let firingBeam = spec.beam && beamState == .fire
        if !firingBeam {
            switch spec.ai {
            case .skirmish:   skirmish(dt: dt, player: player, scene: scene)
            case .dart:       dartAI(dt: dt, player: player, scene: scene)
            case .replicator: replicatorAI(dt: dt, player: player, scene: scene)
            case .capital:    capitalAI(dt: dt, player: player, scene: scene)
            }
        } else {
            velocity *= 0.92
        }
        stepEntity(dt)
    }

    private var canSee: (PlayerShip) -> Bool { { !$0.cloaked && !$0.isDead } }

    // ---- skirmisher ------------------------------------------------
    private func skirmish(dt: CGFloat, player: PlayerShip, scene: GameScene) {
        let to = player.position - position
        let dist = to.length
        if dist > 1 { zRotation = approachAngle(zRotation, to.angle, spec.turn * dt) }
        let head = CGVector(angle: zRotation)
        if dist > spec.keepDist + 60 { velocity += head * spec.thrust * dt }
        else if dist < spec.keepDist - 60 { velocity -= head * spec.thrust * dt }
        let perp = CGVector(angle: zRotation + .pi / 2) * strafeDir
        velocity += perp * (spec.thrust * 0.6) * dt
        strafeTimer -= dt
        if strafeTimer <= 0 { strafeDir *= -1; strafeTimer = .random(in: 1...3) }
        velocity *= 0.99
        if velocity.lengthSquared > spec.maxSpeed * spec.maxSpeed {
            velocity = velocity.scaled(to: spec.maxSpeed)
        }
        fireTimer -= dt
        if fireTimer <= 0 && dist < spec.engage && canSee(player) {
            fireTimer = spec.fireCd * .random(in: 0.8...1.3)
            shoot(at: player.position + player.velocity * 0.15, scene: scene, speed: spec.gunSpeed)
        }
    }

    // ---- Wraith Dart --------------------------------------------
    private func dartAI(dt: CGFloat, player: PlayerShip, scene: GameScene) {
        let to = player.position - position
        let dist = to.length
        zRotation = approachAngle(zRotation, to.angle, spec.turn * dt)
        let head = CGVector(angle: zRotation)
        diveTimer -= dt
        if diving > 0 {
            diving -= dt
            velocity += head * spec.thrust * 1.7 * dt
        } else if diveTimer <= 0 && dist < 720 {
            diving = 0.85; diveTimer = .random(in: 2.6...4.6)
        } else {
            if dist > spec.keepDist { velocity += head * spec.thrust * dt }
            let perp = CGVector(angle: zRotation + .pi / 2) * strafeDir
            velocity += perp * (spec.thrust * 0.8) * dt
            strafeTimer -= dt
            if strafeTimer <= 0 { strafeDir *= -1; strafeTimer = .random(in: 0.8...1.8) }
        }
        velocity *= 0.985
        if velocity.lengthSquared > spec.maxSpeed * spec.maxSpeed {
            velocity = velocity.scaled(to: spec.maxSpeed)
        }
        fireTimer -= dt
        if fireTimer <= 0 && dist < spec.engage && canSee(player) {
            fireTimer = spec.fireCd
            shoot(at: player.position + player.velocity * 0.12, scene: scene, speed: spec.gunSpeed)
        }
        if dist < radius + player.radius + 6 && canSee(player) {
            let d = (position - player.position).normalized
            player.takeDamage(spec.ram, from: -d)
            velocity = d * (spec.maxSpeed * 0.6)
            diving = 0
            scene.registerShake(6)
        }
    }

    // ---- replicator ---------------------------------------------
    private func replicatorAI(dt: CGFloat, player: PlayerShip, scene: GameScene) {
        let to = player.position - position
        let dist = to.length
        if dist > 1 { zRotation = approachAngle(zRotation, to.angle, spec.turn * dt) }
        let head = CGVector(angle: zRotation)
        if dist > spec.keepDist + 60 { velocity += head * spec.thrust * dt }
        else if dist < spec.keepDist - 60 { velocity -= head * spec.thrust * dt }
        let perp = CGVector(angle: zRotation + .pi / 2) * strafeDir
        velocity += perp * (spec.thrust * 0.75) * dt
        strafeTimer -= dt
        if strafeTimer <= 0 { strafeDir *= -1; strafeTimer = .random(in: 0.9...2.2) }
        velocity *= 0.98
        if velocity.lengthSquared > spec.maxSpeed * spec.maxSpeed {
            velocity = velocity.scaled(to: spec.maxSpeed)
        }
        fireTimer -= dt
        if fireTimer <= 0 && dist < spec.engage && canSee(player) {
            fireTimer = spec.fireCd
            let aim = (player.position + player.velocity * 0.2 - position).normalized
            let bolt = Projectile(kind: .infest, friendly: false,
                                  position: position + aim * radius,
                                  velocity: aim * GC.infestBoltSpeed,
                                  damage: 0, life: 3.2)
            scene.add(projectile: bolt)
        }
    }

    // ---- capital / hive / ori ---------------------------------
    private func capitalAI(dt: CGFloat, player: PlayerShip, scene: GameScene) {
        let to = player.position - position
        let dist = to.length
        zRotation = approachAngle(zRotation, to.angle, spec.turn * dt)
        let head = CGVector(angle: zRotation)
        if dist > spec.keepDist + 160 { velocity += head * 24 * dt }
        else if dist < spec.keepDist { velocity -= head * 24 * dt }
        velocity *= 0.98
        if velocity.lengthSquared > spec.maxSpeed * spec.maxSpeed {
            velocity = velocity.scaled(to: spec.maxSpeed)
        }

        let inRange = dist < spec.engage && canSee(player)
        let muzzle = radius + 6

        fireTimer -= dt
        if fireTimer <= 0 && burst == 0 && inRange {
            burst = spec.burstN; burstTimer = 0
            fireTimer = spec.fireCd + .random(in: 0...0.8)
        }
        if burst > 0 {
            burstTimer -= dt
            if burstTimer <= 0 {
                burst -= 1; burstTimer = 0.16
                let aim = (player.position + player.velocity * 0.25 - position)
                    .normalized.rotated(by: .random(in: -0.05...0.05))
                let shell = Projectile(kind: spec.bolt, friendly: false,
                                       position: position + aim * muzzle,
                                       velocity: aim * spec.gunSpeed,
                                       damage: spec.gunDmg, life: 2.6)
                scene.add(projectile: shell)
            }
        }

        if spec.flak {
            flakTimer -= dt
            if flakTimer <= 0 {
                flakTimer = .random(in: 2.4...4.2)
                if inRange {
                    for _ in 0..<10 {
                        let d = CGVector(angle: .random(in: 0...(2 * .pi)))
                        let f = Projectile(kind: .flak, friendly: false,
                                           position: position + d * muzzle,
                                           velocity: d * CGFloat.random(in: 240...380),
                                           damage: spec.flakDmg, life: 2.2)
                        scene.add(projectile: f)
                    }
                }
            }
        }

        if let child = spec.spawns {
            spawnTimer -= dt
            if spawnTimer <= 0 {
                spawnTimer = .random(in: spec.spawnCd)
                scene.enemyRequestsSpawn(child, near: position, radius: radius + 40)
            }
        }
    }

    // ---- Ori satellite beam -----------------------------------
    private func updateBeam(dt: CGFloat, player: PlayerShip, scene: GameScene) {
        let target = player.position
        let dist = (target - position).length
        switch beamState {
        case .idle:
            beamCdTimer -= dt
            if beamCdTimer <= 0 && dist < spec.beamRange && !player.cloaked {
                beamState = .charge
                beamT = spec.beamCharge
            }
        case .charge:
            beamDir = (target - position).normalized
            zRotation = beamDir.angle
            beamT -= dt
            drawBeam(charging: true)
            if beamT <= 0 { beamState = .fire; beamT = spec.beamDur }
        case .fire:
            beamT -= dt
            drawBeam(charging: false)
            let origin = position + beamDir * radius
            for tgt in scene.friendlies() where !tgt.isDead {
                if let pl = tgt as? PlayerShip, pl.cloaked { continue }
                let rel = tgt.position - origin
                let t = rel.dot(beamDir)
                if t > 0 && t < spec.beamRange &&
                    (rel - beamDir * t).length < tgt.radius + 12 {
                    tgt.takeDamage(spec.beamDmg * dt, from: (origin - tgt.position).normalized)
                }
            }
            if beamT <= 0 {
                beamState = .idle
                beamCdTimer = .random(in: spec.beamCd)
                beamNode?.isHidden = true
            }
        }
    }

    private func drawBeam(charging: Bool) {
        guard let n = beamNode else { return }
        n.isHidden = false
        let p = CGMutablePath()
        p.move(to: CGPoint(x: radius, y: 0))
        p.addLine(to: CGPoint(x: radius + spec.beamRange, y: 0))
        n.path = p
        n.zRotation = beamDir.angle - zRotation
        n.lineWidth = charging ? 2 : 6
        n.alpha = charging ? 0.5 : 1
    }

    // ---- shared ------------------------------------------------
    private func shoot(at aimPoint: CGPoint, scene: GameScene, speed: CGFloat) {
        let aim = (aimPoint - position).normalized
        let shot = Projectile(kind: spec.bolt == .infest ? .enemyGun : spec.bolt,
                              friendly: false,
                              position: position + aim * radius,
                              velocity: aim * speed,
                              damage: spec.gunDmg, life: 1.8)
        scene.add(projectile: shot)
    }
}
