//
//  Entity.swift
//  DaedalusiOS
//
//  Base class for anything with a hull, a shield bubble and velocity. Carries
//  the strict shield-XOR-hull damage model, hardened (Ancient) shields, the
//  automatic hull-repair drones and the replicator infestation clock from the
//  desktop build.
//

import SpriteKit

class Entity: SKNode {

    var velocity = CGVector.zero
    var radius: CGFloat = 20
    var bubbleRadius: CGFloat = 32

    var shield: CGFloat = 0
    var shieldMax: CGFloat = 0
    var shieldRegen: CGFloat = 0
    var shieldDelay: CGFloat = GC.playerShieldDelay
    var shieldHardened = false
    private(set) var regenTimer: CGFloat = 0

    var hull: CGFloat = 1
    var hullMax: CGFloat = 1

    var isDead = false
    var invuln: CGFloat = 0
    var invincible = false                 // hard immunity (god mode / cloak)
    var isPlayerEntity = false

    // repair drones
    var repairRate: CGFloat = 0
    var repairDelay: CGFloat = 6
    private(set) var repairing = false
    private var repairTimer: CGFloat = 0

    // replicator infestation: 0 .. 1.6  (>= 1 == systems failed)
    var infested: CGFloat = 0

    private var hitFlash: CGFloat = 0
    private var shieldFlash: CGFloat = 0

    var hullShape: SKShapeNode?
    var baseFill: SKColor = .gray
    private var shieldNode: SKShapeNode?

    func installShieldBubble(color: SKColor) {
        let node = SKShapeNode(circleOfRadius: bubbleRadius)
        node.strokeColor = color
        node.lineWidth = shieldHardened ? 3.5 : 2.5
        node.fillColor = .clear
        node.glowWidth = 3
        node.alpha = 0
        node.zPosition = 6
        addChild(node)
        shieldNode = node
    }

    /// `from` points from this entity's centre toward the impact point.
    func takeDamage(_ amount: CGFloat, from dir: CGVector) {
        guard amount > 0, !isDead, invuln <= 0, !invincible else { return }
        regenTimer = shieldDelay

        if shield > 0 {
            // a hardened Ancient shield can't be cratered by any one hit
            let applied = shieldHardened ? min(amount, shieldMax * 0.12) : amount
            shield -= applied
            if shield < 0 { shield = 0 }
            shieldFlash = 0.24
            return
        }
        hull -= amount
        hitFlash = 0.2
        repairTimer = repairDelay
        if hull <= 0 { hull = 0; isDead = true }
    }

    /// Instantly destroy (ONE-SHOT-KILL cheat -- bypasses the shield gate).
    func kill() { shield = 0; hull = 0; isDead = true }

    /// Hold shield regen off for at least `t` seconds (used by the cloak).
    func bumpRegenDelay(_ t: CGFloat) { regenTimer = max(regenTimer, t) }

    /// Seed a replicator infestation (shields do nothing against it).
    func infect() {
        guard !isDead, !invincible, infested <= 0 else { return }
        infested = 0.02
    }

    /// Integrates velocity, advances every timer. Subclasses set `velocity`
    /// first, then call `super.stepEntity(dt)`.
    func stepEntity(_ dt: CGFloat) {
        position += velocity * dt

        invuln = max(0, invuln - dt)
        hitFlash = max(0, hitFlash - dt)
        shieldFlash = max(0, shieldFlash - dt)

        // infestation escalation
        if infested > 0 {
            if repairing && infested < GC.infestCureCeiling {
                infested -= GC.infestCureRate * dt / GC.infestDuration
            }
            infested = min(1.6, infested + dt / GC.infestDuration)
            let p = clampf(infested, 0, 1)
            var dps = GC.infestDpsStart + (GC.infestDpsEnd - GC.infestDpsStart) * p
            if infested >= 1 { dps += GC.infestFailureDps }
            if !invincible {
                hull -= dps * dt * (isPlayerEntity ? Settings.shared.damageMult : 1)
                hitFlash = max(hitFlash, 0.05)
                if hull <= 0 { hull = 0; isDead = true }
            }
        }

        // shield regen
        if regenTimer > 0 {
            regenTimer -= dt
        } else if shield < shieldMax {
            shield = min(shieldMax, shield + shieldRegen * dt)
        }

        // hull-repair drones
        repairing = false
        if repairTimer > 0 {
            repairTimer -= dt
        } else if repairRate > 0 && hull > 0 && hull < hullMax {
            hull = min(hullMax, hull + repairRate * dt)
            repairing = true
        }

        if let shape = hullShape {
            shape.fillColor = hitFlash > 0 ? .white : baseFill
        }
        if let bubble = shieldNode {
            let frac = shieldMax > 0 ? shield / shieldMax : 0
            let base: CGFloat = frac > 0.02 ? 0.10 + 0.30 * frac : 0
            bubble.alpha = max(base, shieldFlash * 3.0)
        }
    }
}
