//
//  Entity.swift
//  DaedalusiOS
//
//  Base class for anything with a hull, a shield bubble and velocity. Carries
//  the strict shield-XOR-hull damage model from the desktop build: a hit lands
//  on the shield OR the hull, never both in one frame.
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
    private var regenTimer: CGFloat = 0

    var hull: CGFloat = 1
    var hullMax: CGFloat = 1

    var isDead = false
    var invuln: CGFloat = 0

    private var hitFlash: CGFloat = 0
    private var shieldFlash: CGFloat = 0

    /// The drawn hull shape; subclasses assign this so the base can flash it.
    var hullShape: SKShapeNode?
    var baseFill: SKColor = .gray
    private var shieldNode: SKShapeNode?

    func installShieldBubble(color: SKColor) {
        let node = SKShapeNode(circleOfRadius: bubbleRadius)
        node.strokeColor = color
        node.lineWidth = 2.5
        node.fillColor = .clear
        node.glowWidth = 3
        node.alpha = 0
        node.zPosition = 6
        addChild(node)
        shieldNode = node
    }

    /// `from` points from this entity's centre toward the impact point.
    func takeDamage(_ amount: CGFloat, from dir: CGVector) {
        guard amount > 0, !isDead, invuln <= 0 else { return }
        regenTimer = shieldDelay

        if shield > 0 {
            shield -= amount
            if shield < 0 { shield = 0 }
            shieldFlash = 0.24
            return
        }
        hull -= amount
        hitFlash = 0.2
        if hull <= 0 {
            hull = 0
            isDead = true
        }
    }

    /// Integrates velocity into position and advances all the timers. Subclasses
    /// set `velocity` in their own update, then call `super.stepEntity(dt)`.
    func stepEntity(_ dt: CGFloat) {
        position += velocity * dt

        invuln = max(0, invuln - dt)
        hitFlash = max(0, hitFlash - dt)
        shieldFlash = max(0, shieldFlash - dt)

        if regenTimer > 0 {
            regenTimer -= dt
        } else if shield < shieldMax {
            shield = min(shieldMax, shield + shieldRegen * dt)
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
