//
//  Landmark.swift
//  DaedalusiOS
//
//  World-anchored backdrop objects -- planets, moons, a Stargate, nebulae, a
//  black hole, debris fields. Heavy pieces are drawn once into an SKTexture at
//  load; the scene just re-anchors them on a hyperdrive jump.
//

import SpriteKit
import UIKit

struct LandmarkSpec {
    enum Kind { case planet, moon, nebula, stargate, blackhole, debris }
    var kind: Kind
    var seed: UInt64
    var offset: CGVector
    var radius: CGFloat
    var core: SKColor = SKColor(red: 0.15, green: 0.35, blue: 0.55, alpha: 1)
    var land: SKColor = SKColor(red: 0.30, green: 0.47, blue: 0.36, alpha: 1)
    var atmo: SKColor = SKColor(red: 0.47, green: 0.66, blue: 1, alpha: 1)
    var continents = false
    var nebulaColor: SKColor = SKColor(red: 0.31, green: 0.17, blue: 0.47, alpha: 1)
    var debrisCount = 40
}

final class Landmark: SKNode {

    let spec: LandmarkSpec
    private var rng: SeededRNG

    init(_ spec: LandmarkSpec) {
        self.spec = spec
        self.rng = SeededRNG(seed: spec.seed)
        super.init()
        zPosition = -80
        build()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    /// Re-anchor to a new arrival point without rebuilding textures.
    func reposition(around base: CGPoint) {
        position = base + spec.offset
    }

    private func build() {
        switch spec.kind {
        case .planet, .moon: buildPlanet()
        case .stargate:      buildStargate()
        case .blackhole:     buildBlackHole()
        case .nebula:        buildNebula()
        case .debris:        buildDebris()
        }
    }

    // MARK: Planet / moon

    private func buildPlanet() {
        let r = spec.radius
        let pad = r * 0.35
        let size = CGSize(width: (r + pad) * 2, height: (r + pad) * 2)
        let img = UIGraphicsImageRenderer(size: size).image { ctx in
            let c = CGContext.self
            _ = c
            let g = ctx.cgContext
            let center = CGPoint(x: size.width / 2, y: size.height / 2)

            // atmosphere glow
            for i in stride(from: Int(pad), to: 0, by: -2) {
                let a = 0.32 * pow(1 - CGFloat(i) / pad, 2.3)
                g.setFillColor(spec.atmo.withAlphaComponent(a).cgColor)
                g.fillEllipse(in: CGRect(x: center.x - r - CGFloat(i), y: center.y - r - CGFloat(i),
                                         width: (r + CGFloat(i)) * 2, height: (r + CGFloat(i)) * 2))
            }
            // ocean disc
            g.saveGState()
            g.addEllipse(in: CGRect(x: center.x - r, y: center.y - r, width: r * 2, height: r * 2))
            g.clip()
            g.setFillColor(spec.core.cgColor)
            g.fill(CGRect(origin: .zero, size: size))
            // mottled terrain: many small overlapping patches in a tight tonal
            // band so they read as surface texture, not distinct islands
            let blobs = spec.continents ? 90 : 34
            for _ in 0..<blobs {
                let ang = rng.cgFloat(0, .pi * 2)
                let rad = rng.cgFloat(0, r * 0.92)
                let br = rng.cgFloat(r * 0.05, r * 0.16)
                let land = rng.cgFloat(0, 1) < (spec.continents ? 0.55 : 0.35)
                let base = land ? blend(spec.land, spec.core, 0.5)
                                : spec.core.scaled(rng.cgFloat(0.78, 0.95))
                g.setFillColor(base.scaled(rng.cgFloat(0.92, 1.08))
                                   .withAlphaComponent(0.7).cgColor)
                g.fillEllipse(in: CGRect(x: center.x + cos(ang) * rad - br,
                                         y: center.y + sin(ang) * rad - br,
                                         width: br * 2, height: br * 2))
            }
            // terminator shadow
            let sd = CGVector(dx: -0.5, dy: -0.72).normalized
            for step in 0..<5 {
                let a = [0.18, 0.36, 0.57, 0.77, 0.92][step]
                let oc = CGPoint(x: center.x + sd.dx * r * (0.82 + 0.18 * CGFloat(step)),
                                 y: center.y + sd.dy * r * (0.82 + 0.18 * CGFloat(step)))
                g.setFillColor(UIColor(white: 0.02, alpha: CGFloat(a)).cgColor)
                g.fillEllipse(in: CGRect(x: oc.x - r - CGFloat(step) * 3, y: oc.y - r - CGFloat(step) * 3,
                                         width: (r + CGFloat(step) * 3) * 2, height: (r + CGFloat(step) * 3) * 2))
            }
            g.restoreGState()
            g.setStrokeColor(spec.atmo.withAlphaComponent(0.5).cgColor)
            g.setLineWidth(2)
            g.strokeEllipse(in: CGRect(x: center.x - r, y: center.y - r, width: r * 2, height: r * 2))
        }
        let sprite = SKSpriteNode(texture: SKTexture(image: img))
        addChild(sprite)
    }

    // MARK: Stargate

    private func buildStargate() {
        let r = spec.radius
        let size = CGSize(width: (r + 24) * 2, height: (r + 24) * 2)
        let inner = r * 0.76
        let img = UIGraphicsImageRenderer(size: size).image { ctx in
            let g = ctx.cgContext
            let c = CGPoint(x: size.width / 2, y: size.height / 2)
            g.setFillColor(UIColor(white: 0.29, alpha: 1).cgColor)
            g.fillEllipse(in: CGRect(x: c.x - r, y: c.y - r, width: r * 2, height: r * 2))
            g.setBlendMode(.clear)
            g.fillEllipse(in: CGRect(x: c.x - inner, y: c.y - inner, width: inner * 2, height: inner * 2))
            g.setBlendMode(.normal)
            for i in 0..<9 {
                let a = CGFloat(i) / 9 * .pi * 2
                g.setFillColor(GC.ancientGold.cgColor)
                let bx = c.x + cos(a) * (r - 4), by = c.y + sin(a) * (r - 4)
                g.fillEllipse(in: CGRect(x: bx - 4, y: by - 4, width: 8, height: 8))
            }
        }
        let sprite = SKSpriteNode(texture: SKTexture(image: img))
        addChild(sprite)
        // event-horizon shimmer
        let pool = SKShapeNode(circleOfRadius: inner)
        pool.fillColor = SKColor(red: 0.35, green: 0.6, blue: 0.95, alpha: 0.28)
        pool.strokeColor = SKColor(red: 0.7, green: 0.85, blue: 1, alpha: 0.5)
        pool.lineWidth = 2
        pool.blendMode = .add
        addChild(pool)
        pool.run(.repeatForever(.sequence([.fadeAlpha(to: 0.5, duration: 1.6),
                                           .fadeAlpha(to: 0.9, duration: 1.6)])))
    }

    // MARK: Black hole

    private func buildBlackHole() {
        let r = spec.radius
        let pad = r * 2.4
        let size = CGSize(width: (r + pad) * 2, height: (r + pad) * 2)
        let img = UIGraphicsImageRenderer(size: size).image { ctx in
            let g = ctx.cgContext
            let c = CGPoint(x: size.width / 2, y: size.height / 2)
            for i in stride(from: Int(pad), to: 0, by: -3) {
                let f = 1 - CGFloat(i) / pad
                let col = UIColor(red: 0.6 + 0.25 * f, green: 0.27 + 0.16 * f,
                                  blue: 0.12 + 0.08 * f, alpha: 0.18 * pow(f, 2.3))
                g.setFillColor(col.cgColor)
                g.fillEllipse(in: CGRect(x: c.x - r - CGFloat(i), y: c.y - r - CGFloat(i),
                                         width: (r + CGFloat(i)) * 2, height: (r + CGFloat(i)) * 2))
            }
            for (rw, rh, col) in [(r * 2.5, r * 0.85, UIColor(red: 1, green: 0.6, blue: 0.24, alpha: 0.25)),
                                  (r * 1.9, r * 0.55, UIColor(red: 1, green: 0.85, blue: 0.6, alpha: 0.4))] {
                g.setFillColor(col.cgColor)
                g.fillEllipse(in: CGRect(x: c.x - rw, y: c.y - rh, width: rw * 2, height: rh * 2))
            }
            g.setFillColor(UIColor.black.cgColor)
            g.fillEllipse(in: CGRect(x: c.x - r, y: c.y - r, width: r * 2, height: r * 2))
            g.setStrokeColor(UIColor(red: 1, green: 0.88, blue: 0.75, alpha: 0.8).cgColor)
            g.setLineWidth(2)
            g.strokeEllipse(in: CGRect(x: c.x - r, y: c.y - r, width: r * 2, height: r * 2))
        }
        addChild(SKSpriteNode(texture: SKTexture(image: img)))
    }

    // MARK: Nebula

    private func buildNebula() {
        let r = spec.radius
        for _ in 0..<Int(rng.cgFloat(24, 34)) {
            let ang = rng.cgFloat(0, .pi * 2)
            let rad = pow(rng.cgFloat(0, 1), 1.7) * r * 0.85
            let rr = rng.cgFloat(r * 0.16, r * 0.44)
            let puff = SKShapeNode(circleOfRadius: rr)
            puff.fillColor = spec.nebulaColor
                .scaled(rng.cgFloat(0.6, 1.4))
                .withAlphaComponent(rng.cgFloat(0.04, 0.12))
            puff.strokeColor = .clear
            puff.blendMode = .add
            puff.position = CGPoint(x: cos(ang) * rad, y: sin(ang) * rad)
            addChild(puff)
        }
    }

    // MARK: Debris

    private func buildDebris() {
        for _ in 0..<spec.debrisCount {
            let ang = rng.cgFloat(0, .pi * 2)
            let rad = rng.cgFloat(0, spec.radius)
            let sz = rng.cgFloat(3, 11)
            let chunk = SKShapeNode(rectOf: CGSize(width: sz, height: sz * rng.cgFloat(0.5, 1)),
                                    cornerRadius: 1)
            chunk.fillColor = [SKColor(white: 0.36, alpha: 1), SKColor(white: 0.28, alpha: 1),
                               SKColor(red: 0.42, green: 0.37, blue: 0.32, alpha: 1)]
                .randomElement()!
            chunk.strokeColor = .clear
            chunk.position = CGPoint(x: cos(ang) * rad, y: sin(ang) * rad)
            chunk.zRotation = rng.cgFloat(0, .pi * 2)
            chunk.run(.repeatForever(.rotate(byAngle: rng.cgFloat(-0.6, 0.6), duration: 3)))
            addChild(chunk)
        }
    }

    // MARK: helpers

    private func blend(_ a: SKColor, _ b: SKColor, _ t: CGFloat) -> SKColor {
        var ar: CGFloat = 0, ag: CGFloat = 0, ab: CGFloat = 0, aa: CGFloat = 0
        var br: CGFloat = 0, bg: CGFloat = 0, bb: CGFloat = 0, ba: CGFloat = 0
        _ = a.getRed(&ar, green: &ag, blue: &ab, alpha: &aa)
        _ = b.getRed(&br, green: &bg, blue: &bb, alpha: &ba)
        return SKColor(red: ar + (br - ar) * t, green: ag + (bg - ag) * t,
                       blue: ab + (bb - ab) * t, alpha: 1)
    }
}

extension SKColor {
    /// Multiply RGB by `f`, clamped.
    func scaled(_ f: CGFloat) -> SKColor {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        _ = getRed(&r, green: &g, blue: &b, alpha: &a)
        return SKColor(red: clampf(r * f, 0, 1), green: clampf(g * f, 0, 1),
                       blue: clampf(b * f, 0, 1), alpha: a)
    }
}

/// Small deterministic RNG so a given seed always draws the same landmark.
struct SeededRNG {
    private var state: UInt64
    init(seed: UInt64) { state = seed &* 2862933555777941757 &+ 3037000493 }
    mutating func next() -> UInt64 {
        state ^= state << 13; state ^= state >> 7; state ^= state << 17
        return state
    }
    mutating func cgFloat(_ lo: CGFloat, _ hi: CGFloat) -> CGFloat {
        let u = CGFloat(next() % 1_000_000) / 1_000_000
        return lo + (hi - lo) * u
    }
}
