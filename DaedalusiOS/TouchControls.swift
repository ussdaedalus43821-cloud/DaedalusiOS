//
//  TouchControls.swift
//  DaedalusiOS
//
//  On-screen controls (the desktop build used the keyboard).
//   left cluster  : rotate  «  »
//   right cluster : THR (thrust)  ·  FIRE (guns)  ·  RKT  ·  HOM  ·  BEAM
//   left edge     : tap pads -- CLK (cloak)  WING (wingman)  JUMP (hyperdrive)
//  Multi-touch: every active finger is hit-tested against the pads and folded
//  into InputState; tap pads fire `onTap` once on press.
//

import SpriteKit

struct InputState {
    var turn: CGFloat = 0        // -1 .. 1
    var thrust = false
    var fireGun = false
    var fireRocket = false
    var fireHoming = false
    var fireBeam = false
}

final class TouchControls: SKNode {

    enum Pad: CaseIterable {
        case left, right, thrust, gun, rocket, homing, beam   // held
        case cloak, wing, jump, pause                         // tapped
        var isTap: Bool { self == .cloak || self == .wing || self == .jump || self == .pause }
    }

    var onTap: ((Pad) -> Void)?

    private var pads: [Pad: SKShapeNode] = [:]
    private var radii: [Pad: CGFloat] = [:]
    private var touches: [ObjectIdentifier: Pad] = [:]

    private(set) var state = InputState()
    private var hasBeam = true

    override init() {
        super.init()
        zPosition = 1000
        for pad in Pad.allCases {
            let r = radius(pad)
            radii[pad] = r
            let node = SKShapeNode(circleOfRadius: r)
            node.fillColor = SKColor(white: 0.65, alpha: 0.12)
            node.strokeColor = SKColor(white: 0.85, alpha: pad.isTap ? 0.35 : 0.28)
            node.lineWidth = 2
            let label = SKLabelNode(fontNamed: "Menlo-Bold")
            label.fontSize = (pad == .left || pad == .right) ? 20 : 12
            label.verticalAlignmentMode = .center
            label.fontColor = SKColor(white: 0.92, alpha: 0.82)
            label.text = title(pad)
            node.addChild(label)
            addChild(node)
            pads[pad] = node
        }
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private func radius(_ pad: Pad) -> CGFloat {
        switch pad {
        case .gun: return 44
        case .thrust: return 40
        case .left, .right: return 38
        case .rocket, .homing, .beam: return 28
        case .cloak, .wing, .jump: return 26
        case .pause: return 22
        }
    }

    private func title(_ pad: Pad) -> String {
        switch pad {
        case .left:   return "\u{00AB}"
        case .right:  return "\u{00BB}"
        case .thrust: return "THR"
        case .gun:    return "FIRE"
        case .rocket: return "RKT"
        case .homing: return "HOM"
        case .beam:   return "BEAM"
        case .cloak:  return "CLK"
        case .wing:   return "WING"
        case .jump:   return "JUMP"
        case .pause:  return "II"
        }
    }

    /// Beam-less hulls hide the BEAM pad entirely.
    func configure(hasBeam: Bool) {
        self.hasBeam = hasBeam
        pads[.beam]?.isHidden = !hasBeam
    }

    func layout(size: CGSize) {
        let bx = -size.width / 2, by = -size.height / 2
        let rx = -bx
        pads[.left]?.position   = CGPoint(x: bx + 74,  y: by + 150)
        pads[.right]?.position  = CGPoint(x: bx + 168, y: by + 150)

        pads[.gun]?.position    = CGPoint(x: rx - 78,  y: by + 138)
        pads[.thrust]?.position = CGPoint(x: rx - 78,  y: by + 248)
        pads[.rocket]?.position = CGPoint(x: rx - 158, y: by + 118)
        pads[.homing]?.position = CGPoint(x: rx - 158, y: by + 186)
        pads[.beam]?.position   = CGPoint(x: rx - 158, y: by + 254)

        // left-edge system tap strip, vertically centred
        pads[.cloak]?.position  = CGPoint(x: bx + 44, y: 84)
        pads[.wing]?.position   = CGPoint(x: bx + 44, y: 26)
        pads[.jump]?.position   = CGPoint(x: bx + 44, y: -32)
        pads[.pause]?.position  = CGPoint(x: bx + 44, y: -86)
    }

    /// Hidden at game over so a "tap to continue" isn't eaten by a pad.
    func setActiveInput(_ enabled: Bool) {
        isHidden = !enabled
        if !enabled { touches.removeAll(); recompute() }
    }

    // MARK: Touch routing (points already in this node's space)

    func touchDown(_ id: ObjectIdentifier, at p: CGPoint) {
        guard let pad = hit(p) else { return }
        if pad.isTap {
            flash(pad)
            onTap?(pad)
        } else {
            touches[id] = pad
            recompute()
        }
    }

    func touchMoved(_ id: ObjectIdentifier, at p: CGPoint) {
        guard touches[id] != nil else { return }        // taps don't drag
        let pad = hit(p)
        if pad?.isTap == true { return }
        if touches[id] != pad {
            if let pad { touches[id] = pad } else { touches.removeValue(forKey: id) }
            recompute()
        }
    }

    func touchUp(_ id: ObjectIdentifier) {
        if touches.removeValue(forKey: id) != nil { recompute() }
    }

    private func hit(_ p: CGPoint) -> Pad? {
        for (pad, node) in pads where !node.isHidden {
            let r = (radii[pad] ?? 38) + 8
            if p.distanceSquared(to: node.position) <= r * r { return pad }
        }
        return nil
    }

    private func flash(_ pad: Pad) {
        pads[pad]?.run(.sequence([
            .run { [weak self] in self?.pads[pad]?.fillColor = SKColor(white: 0.9, alpha: 0.5) },
            .wait(forDuration: 0.12),
            .run { [weak self] in self?.pads[pad]?.fillColor = SKColor(white: 0.65, alpha: 0.12) }
        ]))
    }

    private func recompute() {
        let active = Set(touches.values)
        for (pad, node) in pads where !pad.isTap {
            node.fillColor = SKColor(white: 0.7, alpha: active.contains(pad) ? 0.34 : 0.12)
        }
        var s = InputState()
        s.turn = (active.contains(.right) ? 1 : 0) - (active.contains(.left) ? 1 : 0)
        s.thrust = active.contains(.thrust)
        s.fireGun = active.contains(.gun)
        s.fireRocket = active.contains(.rocket)
        s.fireHoming = active.contains(.homing)
        s.fireBeam = active.contains(.beam)
        state = s
    }
}
