//
//  PlayerShip.swift
//  DaedalusiOS
//
//  The player's ship. Data-driven from a ShipSpec: rotational-inertia flight,
//  rapid guns, splash rockets, homing drone salvos, the Asgard beam (BC-304 /
//  BC-305 only), the invincibility cloak, Destiny's AI turrets, and hull
//  repair drones.
//

import SpriteKit

final class PlayerShip: Entity {

    private(set) var shipID: ShipID = .daedalus
    private(set) var spec: ShipSpec = Ships.spec(.daedalus)

    private(set) var gunCd: CGFloat = 0
    private(set) var rocketCd: CGFloat = 0
    private(set) var homingCd: CGFloat = 0
    private(set) var turretCd: CGFloat = 0
    private(set) var rockets = 0
    private(set) var homing = 0

    private(set) var beamEnergy: CGFloat = 0
    private(set) var beamActive = false
    private(set) var cloaked = false
    private(set) var cloakEnergy = GC.cloakEnergyMax

    private var thrusting = false
    private var plume: SKShapeNode!
    private var ghost: SKShapeNode!         // shown while cloaked

    var hasBeam: Bool { spec.beamDmg > 0 }

    override init() {
        super.init()
        name = "player"
        isPlayerEntity = true
        zPosition = 10
        apply(PlayerLoadout.selected)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    // MARK: Ship application

    func apply(_ id: ShipID) {
        removeAllChildren()
        shipID = id
        let s = Ships.spec(id)
        spec = s
        PlayerLoadout.selected = id

        radius = s.radius
        bubbleRadius = s.radius + s.bubblePad
        shieldMax = s.shieldMax
        shieldRegen = s.shieldRegen
        shieldDelay = s.shieldDelay
        shieldHardened = s.hardened
        hullMax = s.hullMax
        repairRate = Settings.shared.autoRepair ? s.repairRate : 0
        repairDelay = GC.hullRepairDelay
        beamEnergy = s.beamMax
        rockets = s.rocketAmmo
        homing = s.homingAmmo

        buildArt()
        installShieldBubble(color: s.hardened
            ? SKColor(red: 0.55, green: 0.8, blue: 1, alpha: 1) : GC.shieldBlue)
    }

    func resetForNewGame() {
        apply(PlayerLoadout.selected)
        velocity = .zero
        position = .zero
        zRotation = .pi / 2
        shield = shieldMax
        hull = hullMax
        infested = 0
        cloaked = false
        invincible = Settings.shared.godMode
        cloakEnergy = GC.cloakEnergyMax
        beamEnergy = spec.beamMax
        gunCd = 0; rocketCd = 0; homingCd = 0; turretCd = 0
        isDead = false
        invuln = 1.0
        isHidden = false
        alpha = 1
        ghost.isHidden = true
    }

    private func buildArt() {
        let hull = Ships.buildArt(shipID, on: self)
        hullShape = hull
        baseFill = hull.fillColor

        let pp = CGMutablePath()
        pp.addLines(between: [CGPoint(x: -radius, y: -6), CGPoint(x: -radius, y: 6),
                              CGPoint(x: -radius - 22, y: 0)])
        pp.closeSubpath()
        plume = SKShapeNode(path: pp)
        plume.fillColor = SKColor(red: 1, green: 0.6, blue: 0.2, alpha: 0.95)
        plume.strokeColor = .clear
        plume.blendMode = .add
        plume.alpha = 0
        addChild(plume)

        ghost = SKShapeNode(circleOfRadius: bubbleRadius)
        ghost.strokeColor = SKColor(red: 0.5, green: 0.85, blue: 1, alpha: 0.5)
        ghost.fillColor = SKColor(red: 0.4, green: 0.75, blue: 1, alpha: 0.06)
        ghost.lineWidth = 1
        ghost.isHidden = true
        ghost.zPosition = 7
        addChild(ghost)
    }

    // MARK: Cloak

    func toggleCloak() {
        if !cloaked {
            guard Settings.shared.cloakEnabled, cloakEnergy >= GC.cloakMinToEngage else { return }
            cloaked = true
            invincible = true
            shield = 0
        } else {
            cloaked = false
            invincible = Settings.shared.godMode
            shield = 0
            bumpRegenDelay(GC.cloakDecloakShieldDelay)   // shields restart cold
        }
        updateCloakVisual()
    }

    func setCloakOff() { if cloaked { toggleCloak() } }

    private func updateCloakVisual() {
        ghost.isHidden = !cloaked
        for child in children where child !== ghost {
            child.alpha = cloaked ? 0.18 : 1
        }
        alpha = 1
    }

    /// Difficulty scales what the player takes (enemies use the base amount).
    override func takeDamage(_ amount: CGFloat, from dir: CGVector) {
        super.takeDamage(amount * Settings.shared.damageMult, from: dir)
    }

    // MARK: Per-frame

    func update(dt: CGFloat, input: InputState, scene: GameScene) {
        zRotation += input.turn * spec.turn * dt

        thrusting = input.thrust && !cloaked
        if thrusting {
            velocity += CGVector(angle: zRotation) * spec.thrust * dt
        }
        plume.alpha = thrusting ? CGFloat.random(in: 0.5...1.0) : 0

        velocity *= vpow(spec.damp, dt * 60)
        let maxV = spec.maxSpeed
        if velocity.lengthSquared > maxV * maxV { velocity = velocity.scaled(to: maxV) }

        gunCd = max(0, gunCd - dt)
        rocketCd = max(0, rocketCd - dt)
        homingCd = max(0, homingCd - dt)
        turretCd = max(0, turretCd - dt)

        // cloak energy
        if cloaked {
            cloakEnergy -= GC.cloakDrain * dt
            shield = 0
            bumpRegenDelay(GC.cloakDecloakShieldDelay)
            if cloakEnergy <= 0 { cloakEnergy = 0; toggleCloak() }
        } else {
            cloakEnergy = min(GC.cloakEnergyMax, cloakEnergy + GC.cloakRecharge * dt)
        }

        if !cloaked {
            if input.fireGun { fireGun(scene) }
            if input.fireRocket { fireRocket(scene) }
            if input.fireHoming { fireHoming(scene) }
            processBeam(dt: dt, want: input.fireBeam, scene: scene)
            if spec.turrets > 0 { runTurrets(dt: dt, scene: scene) }
        } else {
            beamActive = false
            beamEnergy = min(spec.beamMax, beamEnergy + GC.beamRecharge * dt)
        }

        stepEntity(dt)
        if repairing { spawnRepairSpark(scene) }
    }

    // MARK: Weapons

    private func fireGun(_ scene: GameScene) {
        guard gunCd <= 0 || Settings.shared.noCooldown else { return }
        gunCd = spec.gunCd

        // Atlantis: an omni-directional broadside -- twin bolts from every rim
        // port, so a full trigger pull is 16 rounds fanning out in all 8 axes
        if spec.gunPorts > 0 {
            for i in 0..<spec.gunPorts {
                let a = zRotation + CGFloat(i) / CGFloat(spec.gunPorts) * .pi * 2
                let outward = CGVector(angle: a)
                let perp = CGVector(dx: -outward.dy, dy: outward.dx)
                for side in [CGFloat(5), CGFloat(-5)] {
                    let dir = outward.rotated(by: .random(in: -spec.gunSpread...spec.gunSpread))
                    let shot = Projectile(kind: .gun, friendly: true,
                                          position: position + outward * radius + perp * side,
                                          velocity: dir * spec.gunSpeed + velocity * 0.4,
                                          damage: spec.gunDmg, life: GC.gunLife)
                    scene.add(projectile: shot)
                }
            }
            return
        }

        let head = CGVector(angle: zRotation)
        for side in [CGFloat(7), CGFloat(-7)] {
            let perp = CGVector(angle: zRotation + .pi / 2) * side
            let dir = head.rotated(by: .random(in: -spec.gunSpread...spec.gunSpread))
            let shot = Projectile(kind: .gun, friendly: true,
                                  position: position + head * radius + perp,
                                  velocity: dir * spec.gunSpeed + velocity * 0.4,
                                  damage: spec.gunDmg, life: GC.gunLife)
            scene.add(projectile: shot)
        }
    }

    private func fireRocket(_ scene: GameScene) {
        guard rocketCd <= 0 || Settings.shared.noCooldown else { return }
        guard rockets > 0 || Settings.shared.infiniteRockets else { return }
        rocketCd = spec.rocketCd
        if !Settings.shared.infiniteRockets { rockets -= 1 }
        let head = CGVector(angle: zRotation)
        let shot = Projectile(kind: .rocket, friendly: true,
                              position: position + head * radius,
                              velocity: head * GC.rocketSpeed + velocity * 0.5,
                              damage: spec.rocketDmg, life: GC.rocketLife)
        shot.splashRadius = GC.rocketSplashRadius
        shot.splashDamage = GC.rocketSplashDamage
        scene.add(projectile: shot)
    }

    private func fireHoming(_ scene: GameScene) {
        guard homingCd <= 0 || Settings.shared.noCooldown else { return }
        guard homing > 0 || Settings.shared.infiniteHoming else { return }
        let targets = scene.homingTargets(near: position, facing: CGVector(angle: zRotation),
                                          range: GC.homingAcquireRange)
        guard !targets.isEmpty else { return }
        homingCd = spec.homingCd

        var n = spec.homingSalvo
        if !Settings.shared.infiniteHoming { n = min(n, homing) }
        let head = CGVector(angle: zRotation)
        let perp = CGVector(dx: -head.dy, dy: head.dx)
        let rail = radius * 0.9
        for i in 0..<n {
            if !Settings.shared.infiniteHoming { homing -= 1 }
            let tgt = targets[i % targets.count]
            let f: CGFloat = n == 1 ? 0 : (CGFloat(i) - CGFloat(n - 1) / 2) / (CGFloat(n - 1) / 2)
            let origin = position
                + head * (radius * (0.55 + 0.35 * abs(f)))
                + perp * (f * rail + .random(in: -4...4))
            let launch = head.rotated(by: f * 0.28 + .random(in: -0.07...0.07))
            let drone = Projectile(kind: .homing, friendly: true,
                                   position: origin,
                                   velocity: launch * GC.homingSpeed + velocity * 0.4,
                                   damage: spec.homingDmg, life: GC.homingLife)
            drone.target = tgt
            drone.turnRate = spec.homingTurn
            drone.splashRadius = GC.homingSplashRadius
            drone.splashDamage = GC.homingSplashDamage
            drone.homeScene = scene
            scene.add(projectile: drone)
        }
    }

    private func processBeam(dt: CGFloat, want: Bool, scene: GameScene) {
        guard hasBeam else { beamActive = false; scene.setBeam(nil); return }
        let canFire = want && (Settings.shared.infiniteBeam || beamEnergy > GC.beamMinToFire)
        beamActive = canFire
        if !canFire {
            beamEnergy = min(spec.beamMax, beamEnergy + GC.beamRecharge * dt)
            scene.setBeam(nil)
            return
        }
        if !Settings.shared.infiniteBeam { beamEnergy = max(0, beamEnergy - GC.beamDrain * dt) }
        let origin = position + CGVector(angle: zRotation) * radius
        let dir = CGVector(angle: zRotation)
        let end = scene.applyBeam(origin: origin, dir: dir, dps: spec.beamDmg * dt)
        scene.setBeam((origin, end))
    }

    private func runTurrets(dt: CGFloat, scene: GameScene) {
        guard turretCd <= 0 else { return }
        turretCd = spec.turretCd
        let r2 = spec.turretRange * spec.turretRange
        let targets = scene.enemiesWithin(r2, of: position)
        guard !targets.isEmpty else { return }
        for i in 0..<spec.turrets {
            let e = targets[i % targets.count]
            let mx = -22 + CGFloat(i) * (44 / CGFloat(max(1, spec.turrets - 1)))
            let mount = position + CGVector(dx: mx, dy: -3).rotated(by: zRotation)
            let aim = (e.position + e.velocity * 0.15 - mount).normalized
            let shot = Projectile(kind: .gun, friendly: true, position: mount,
                                  velocity: aim * 940 + velocity * 0.3,
                                  damage: spec.turretDmg, life: 1.1)
            scene.add(projectile: shot)
        }
    }

    private func spawnRepairSpark(_ scene: GameScene) {
        guard Bool.random() else { return }
        scene.spawnTrailPuff(at: position + CGVector(angle: .random(in: 0...(2 * .pi)))
                                * .random(in: 3...radius),
                             color: SKColor(red: 1, green: 0.85, blue: 0.5, alpha: 1))
    }
}
