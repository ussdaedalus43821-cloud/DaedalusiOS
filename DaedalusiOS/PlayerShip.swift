//
//  PlayerShip.swift
//  DaedalusiOS
//
//  The player's BC-304. Rotational-inertia flight: rotate left/right, thrust
//  along the nose, coast on light space drag. Vector art, no assets.
//

import SpriteKit

final class PlayerShip: Entity {

    private(set) var gunCooldown: CGFloat = 0
    private(set) var rocketCooldown: CGFloat = 0
    private(set) var rockets = GC.rocketStartAmmo
    private var thrusting = false
    private var plume: SKShapeNode!

    override init() {
        super.init()
        name = "player"
        radius = 20
        bubbleRadius = 34
        shieldMax = GC.playerShieldMax
        shield = shieldMax
        shieldRegen = GC.playerShieldRegen
        shieldDelay = GC.playerShieldDelay
        hullMax = GC.playerHullMax
        hull = hullMax
        zPosition = 10
        buildArt()
        installShieldBubble(color: GC.shieldBlue)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func resetForNewGame() {
        velocity = .zero
        position = .zero
        zRotation = .pi / 2                 // nose up
        shield = shieldMax
        hull = hullMax
        rockets = GC.rocketStartAmmo
        gunCooldown = 0
        rocketCooldown = 0
        isDead = false
        invuln = 1.0
        isHidden = false
        alpha = 1
    }

    private func buildArt() {
        let path = CGMutablePath()
        path.move(to: CGPoint(x: 26, y: 0))       // nose (+x local)
        path.addLine(to: CGPoint(x: 8, y: -13))
        path.addLine(to: CGPoint(x: -20, y: -13))
        path.addLine(to: CGPoint(x: -24, y: 0))
        path.addLine(to: CGPoint(x: -20, y: 13))
        path.addLine(to: CGPoint(x: 8, y: 13))
        path.closeSubpath()

        let hull = SKShapeNode(path: path)
        hull.fillColor = SKColor(red: 0.62, green: 0.70, blue: 0.85, alpha: 1)
        hull.strokeColor = SKColor(white: 0.14, alpha: 1)
        hull.lineWidth = 2
        addChild(hull)
        hullShape = hull
        baseFill = hull.fillColor

        // engine nacelles
        for sy in [CGFloat(1), CGFloat(-1)] {
            let n = SKShapeNode(rectOf: CGSize(width: 22, height: 7), cornerRadius: 2)
            n.fillColor = SKColor(white: 0.3, alpha: 1)
            n.strokeColor = SKColor(white: 0.12, alpha: 1)
            n.lineWidth = 1
            n.position = CGPoint(x: -22, y: sy * 13)
            addChild(n)
        }
        let bridge = SKShapeNode(circleOfRadius: 3)
        bridge.fillColor = SKColor(red: 0.6, green: 0.9, blue: 1, alpha: 1)
        bridge.strokeColor = .clear
        bridge.position = CGPoint(x: 12, y: 0)
        bridge.blendMode = .add
        addChild(bridge)

        let pp = CGMutablePath()
        pp.move(to: CGPoint(x: -24, y: -6))
        pp.addLine(to: CGPoint(x: -24, y: 6))
        pp.addLine(to: CGPoint(x: -44, y: 0))
        pp.closeSubpath()
        plume = SKShapeNode(path: pp)
        plume.fillColor = SKColor(red: 1, green: 0.6, blue: 0.2, alpha: 0.95)
        plume.strokeColor = .clear
        plume.blendMode = .add
        plume.alpha = 0
        addChild(plume)
    }

    // MARK: Per-frame

    func update(dt: CGFloat, input: InputState, scene: GameScene) {
        zRotation += input.turn * GC.playerTurnRate * dt

        thrusting = input.thrust
        if thrusting {
            velocity += CGVector(angle: zRotation) * GC.playerThrust * dt
        }
        plume.alpha = thrusting ? CGFloat.random(in: 0.5...1.0) : 0

        velocity *= vpow(GC.playerDamp, dt * 60)
        if velocity.lengthSquared > GC.playerMaxSpeed * GC.playerMaxSpeed {
            velocity = velocity.scaled(to: GC.playerMaxSpeed)
        }

        gunCooldown = max(0, gunCooldown - dt)
        rocketCooldown = max(0, rocketCooldown - dt)
        if input.fireGun { fireGun(into: scene) }
        if input.fireRocket { fireRocket(into: scene) }

        stepEntity(dt)
    }

    private func fireGun(into scene: GameScene) {
        guard gunCooldown <= 0 else { return }
        gunCooldown = GC.gunCooldown
        let head = CGVector(angle: zRotation)
        for side in [CGFloat(7), CGFloat(-7)] {
            let perp = CGVector(angle: zRotation + .pi / 2) * side
            let dir = head.rotated(by: .random(in: -GC.gunSpread...GC.gunSpread))
            let shot = Projectile(kind: .gun, friendly: true,
                                  position: position + head * radius + perp,
                                  velocity: dir * GC.gunSpeed + velocity * 0.4,
                                  damage: GC.gunDamage, life: GC.gunLife)
            scene.add(projectile: shot)
        }
    }

    private func fireRocket(into scene: GameScene) {
        guard rocketCooldown <= 0, rockets > 0 else { return }
        rocketCooldown = GC.rocketCooldown
        rockets -= 1
        let head = CGVector(angle: zRotation)
        let shot = Projectile(kind: .rocket, friendly: true,
                              position: position + head * radius,
                              velocity: head * GC.rocketSpeed + velocity * 0.5,
                              damage: GC.rocketDamage, life: GC.rocketLife)
        shot.splashRadius = GC.rocketSplashRadius
        shot.splashDamage = GC.rocketSplashDamage
        scene.add(projectile: shot)
    }
}
