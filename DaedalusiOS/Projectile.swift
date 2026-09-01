//
//  Projectile.swift
//  DaedalusiOS
//
//  Guns, rockets, homing drones and enemy fire. Movement + collision are
//  handled manually in GameScene (deterministic) -- no physics bodies.
//

import SpriteKit

enum ProjectileKind {
    case gun          // player / ally rapid cannon
    case rocket       // player splash rocket
    case homing       // steered drone, splash
    case enemyGun     // fighter / dart bolt
    case enemyHeavy   // capital shell
    case flak         // capital area burst
    case infest       // replicator infestation bolt
}

final class Projectile: SKNode {

    let kind: ProjectileKind
    let friendly: Bool
    var velocity: CGVector
    var damage: CGFloat
    var life: CGFloat
    var isDead = false

    let hitRadius: CGFloat
    var splashRadius: CGFloat = 0
    var splashDamage: CGFloat = 0

    // homing
    weak var target: Entity?
    var turnRate: CGFloat = 0
    private var trailTimer: CGFloat = 0
    weak var homeScene: GameScene?

    init(kind: ProjectileKind,
         friendly: Bool,
         position: CGPoint,
         velocity: CGVector,
         damage: CGFloat,
         life: CGFloat) {
        self.kind = kind
        self.friendly = friendly
        self.velocity = velocity
        self.damage = damage
        self.life = life

        switch kind {
        case .gun, .enemyGun: hitRadius = 3
        case .rocket:         hitRadius = 5
        case .homing:         hitRadius = 4
        case .enemyHeavy:     hitRadius = 6
        case .flak:           hitRadius = 4
        case .infest:         hitRadius = 5
        }

        super.init()
        self.position = position
        self.zPosition = 3
        buildArt()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private func buildArt() {
        switch kind {
        case .gun, .enemyGun:
            let bolt = SKShapeNode(rectOf: CGSize(width: 3, height: 14), cornerRadius: 1.5)
            bolt.fillColor = friendly
                ? SKColor(red: 0.55, green: 0.95, blue: 1, alpha: 1)
                : SKColor(red: 1, green: 0.4, blue: 0.4, alpha: 1)
            bolt.strokeColor = .clear
            bolt.glowWidth = 3
            bolt.blendMode = .add
            bolt.zRotation = velocity.angle - .pi / 2
            addChild(bolt)

        case .rocket, .homing:
            let body = SKShapeNode(rectOf: CGSize(width: 6, height: 15), cornerRadius: 3)
            body.fillColor = kind == .homing
                ? SKColor(red: 0.7, green: 0.95, blue: 1, alpha: 1)
                : SKColor(red: 1, green: 0.8, blue: 0.5, alpha: 1)
            body.strokeColor = SKColor(white: 0.2, alpha: 1)
            body.lineWidth = 1
            body.zRotation = velocity.angle - .pi / 2
            addChild(body)
            let tip = SKShapeNode(circleOfRadius: 3)
            tip.fillColor = SKColor(red: 1, green: 0.97, blue: 0.85, alpha: 1)
            tip.strokeColor = .clear; tip.blendMode = .add
            addChild(tip)

        case .enemyHeavy:
            let shell = SKShapeNode(circleOfRadius: 6)
            shell.fillColor = SKColor(red: 1, green: 0.5, blue: 0.7, alpha: 1)
            shell.strokeColor = SKColor(red: 1, green: 0.85, blue: 0.9, alpha: 1)
            shell.lineWidth = 1; shell.glowWidth = 3; shell.blendMode = .add
            addChild(shell)

        case .flak:
            let f = SKShapeNode(circleOfRadius: 3)
            f.fillColor = SKColor(red: 1, green: 0.66, blue: 0.35, alpha: 1)
            f.strokeColor = .clear; f.blendMode = .add
            addChild(f)

        case .infest:
            let core = SKShapeNode(circleOfRadius: 5)
            core.fillColor = SKColor(red: 0.8, green: 0.82, blue: 0.92, alpha: 1)
            core.strokeColor = SKColor(white: 0.35, alpha: 1); core.lineWidth = 1
            addChild(core)
            core.run(.repeatForever(.rotate(byAngle: .pi, duration: 0.4)))
        }
    }

    func step(_ dt: CGFloat) {
        if kind == .homing {
            if let t = target, t.isDead || t.parent == nil { target = nil }
            if let t = target {
                let want = (t.position - position).angle
                let cur = velocity.angle
                let spd = max(velocity.length, GC.homingSpeed)
                let next = approachAngle(cur, want, turnRate * dt)
                velocity = CGVector(angle: next) * spd
                zRotation = next - .pi / 2
            }
            trailTimer -= dt
            if trailTimer <= 0, let sc = homeScene {
                trailTimer = 0.03
                sc.spawnTrailPuff(at: position,
                                  color: SKColor(red: 0.6, green: 0.85, blue: 1, alpha: 1))
            }
        }
        position += velocity * dt
        life -= dt
        if life <= 0 { isDead = true }
    }
}
