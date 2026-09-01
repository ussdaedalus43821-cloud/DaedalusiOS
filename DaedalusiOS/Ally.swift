//
//  Ally.swift
//  DaedalusiOS
//
//  A friendly wingman: forms up on the player's flank, then peels off to
//  strafe the nearest hostile and put rounds on it.
//

import SpriteKit

final class Ally: Entity {

    let formSlot: Int
    private var fireTimer: CGFloat = 0
    private var strafeDir: CGFloat = Bool.random() ? 1 : -1
    private var strafeTimer: CGFloat = .random(in: 1...2.5)

    init(formSlot: Int) {
        self.formSlot = formSlot
        super.init()
        name = "ally"
        radius = 12
        bubbleRadius = 23
        shieldMax = GC.allyShieldMax; shield = shieldMax
        shieldRegen = 10
        shieldDelay = 3
        hullMax = GC.allyHullMax; hull = hullMax
        repairRate = GC.allyRepairRate
        repairDelay = 6
        zPosition = 8
        buildArt()
        installShieldBubble(color: SKColor(red: 0.45, green: 1, blue: 0.65, alpha: 1))
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private func buildArt() {
        let p = CGMutablePath()
        p.addLines(between: [CGPoint(x: 14, y: 0), CGPoint(x: -9, y: -8),
                             CGPoint(x: -4, y: 0), CGPoint(x: -9, y: 8)])
        p.closeSubpath()
        let body = SKShapeNode(path: p)
        body.fillColor = SKColor(red: 0.47, green: 1, blue: 0.6, alpha: 1)
        body.strokeColor = SKColor(red: 0.12, green: 0.4, blue: 0.22, alpha: 1)
        body.lineWidth = 1.5
        addChild(body)
        hullShape = body
        baseFill = body.fillColor
    }

    func update(dt: CGFloat, player: PlayerShip, scene: GameScene) {
        let enemy = scene.nearestEnemy(to: position)
        let engaging = enemy != nil &&
            position.distance(to: enemy!.position) < GC.allyEngageRange

        if let e = enemy, engaging {
            let to = e.position - position
            let dist = to.length
            if dist > 1 { zRotation = to.angle }
            let head = CGVector(angle: zRotation)
            let keep = GC.allyKeepDist + e.radius
            if dist > keep + 60 { velocity += head * GC.allyThrust * dt }
            else if dist < keep - 60 { velocity -= head * GC.allyThrust * dt }
            let perp = CGVector(angle: zRotation + .pi / 2) * strafeDir
            velocity += perp * (GC.allyThrust * 0.5) * dt
            strafeTimer -= dt
            if strafeTimer <= 0 { strafeDir *= -1; strafeTimer = .random(in: 1.2...3) }

            fireTimer -= dt
            if fireTimer <= 0 && dist < GC.allyEngageRange {
                fireTimer = GC.allyGunCooldown
                let aim = (e.position + e.velocity * 0.18 - position).normalized
                let shot = Projectile(kind: .gun, friendly: true,
                                      position: position + aim * radius,
                                      velocity: aim * GC.allyGunSpeed + velocity * 0.3,
                                      damage: GC.allyGunDamage, life: GC.gunLife)
                scene.add(projectile: shot)
            }
        } else {
            let slot = scene.formationOffset(formSlot)
            let seek = (player.position + slot) - position
            if seek.lengthSquared > 100 { velocity += seek.normalized * GC.allyThrust * dt }
            velocity += (player.velocity - velocity) * 0.9 * dt
            if seek.lengthSquared > 4 { zRotation = seek.angle }
        }

        velocity *= 0.99
        if velocity.lengthSquared > GC.allyMaxSpeed * GC.allyMaxSpeed {
            velocity = velocity.scaled(to: GC.allyMaxSpeed)
        }
        stepEntity(dt)
    }
}
