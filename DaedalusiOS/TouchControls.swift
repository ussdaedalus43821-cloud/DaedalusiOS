//
//  TouchControls.swift
//  DaedalusiOS
//
//  On-screen controls (the desktop build used the keyboard). Two rotate pads
//  bottom-left, thrust + fire + rocket bottom-right. Multi-touch: every active
//  finger is hit-tested against the pads each frame and folded into InputState.
//

import SpriteKit

struct InputState {
    var turn: CGFloat = 0        // -1 .. 1
    var thrust = false
    var fireGun = false
    var fireRocket = false
}

final class TouchControls: SKNode {

    enum Pad: CaseIterable { case left, right, thrust, gun, rocket }

    private var pads: [Pad: SKShapeNode] = [:]
    private var radii: [Pad: CGFloat] = [:]
    private var touches: [ObjectIdentifier: Pad] = [:]

    private(set) var state = InputState()

    override init() {
        super.init()
        zPosition = 1000
        for pad in Pad.allCases {
            let r: CGFloat = pad == .gun ? 46 : (pad == .rocket ? 32 : 38)
            radii[pad] = r
            let node = SKShapeNode(circleOfRadius: r)
            node.fillColor = SKColor(white: 0.65, alpha: 0.12)
            node.strokeColor = SKColor(white: 0.85, alpha: 0.28)
            node.lineWidth = 2
            let label = SKLabelNode(fontNamed: "Menlo-Bold")
            label.fontSize = pad == .left || pad == .right ? 20 : 13
            label.verticalAlignmentMode = .center
            label.fontColor = SKColor(white: 0.92, alpha: 0.8)
            label.text = title(pad)
            node.addChild(label)
            addChild(node)
            pads[pad] = node
        }
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private func title(_ pad: Pad) -> String {
        switch pad {
        case .left:   return "\u{00AB}"   // «
        case .right:  return "\u{00BB}"   // »
        case .thrust: return "THR"
        case .gun:    return "FIRE"
        case .rocket: return "RKT"
        }
    }

    func layout(size: CGSize) {
        let bx = -size.width / 2
        let by = -size.height / 2
        // keep every pad clear of the bottom ~120pt (home-indicator gesture zone)
        pads[.left]?.position   = CGPoint(x: bx + 72,   y: by + 156)
        pads[.right]?.position  = CGPoint(x: bx + 170,  y: by + 156)
        pads[.gun]?.position    = CGPoint(x: -bx - 80,  y: by + 148)
        pads[.rocket]?.position = CGPoint(x: -bx - 180, y: by + 176)
        pads[.thrust]?.position = CGPoint(x: -bx - 80,  y: by + 258)
    }

    /// Hidden at game over so the "tap to continue" tap isn't eaten by a pad.
    func setActiveInput(_ enabled: Bool) {
        isHidden = !enabled
        if !enabled {
            touches.removeAll()
            recompute()
        }
    }

    // MARK: Touch routing (called by GameScene, points already in this node's space)

    func touchDown(_ id: ObjectIdentifier, at p: CGPoint) {
        if let pad = hit(p) { touches[id] = pad; recompute() }
    }

    func touchMoved(_ id: ObjectIdentifier, at p: CGPoint) {
        let pad = hit(p)
        if touches[id] != pad {
            if let pad { touches[id] = pad } else { touches.removeValue(forKey: id) }
            recompute()
        }
    }

    func touchUp(_ id: ObjectIdentifier) {
        if touches.removeValue(forKey: id) != nil { recompute() }
    }

    private func hit(_ p: CGPoint) -> Pad? {
        for (pad, node) in pads {
            let r = (radii[pad] ?? 38) + 8
            if p.distanceSquared(to: node.position) <= r * r { return pad }
        }
        return nil
    }

    private func recompute() {
        let active = Set(touches.values)
        for (pad, node) in pads {
            node.fillColor = SKColor(white: 0.7, alpha: active.contains(pad) ? 0.34 : 0.12)
        }
        var s = InputState()
        s.turn = (active.contains(.right) ? 1 : 0) - (active.contains(.left) ? 1 : 0)
        s.thrust = active.contains(.thrust)
        s.fireGun = active.contains(.gun)
        s.fireRocket = active.contains(.rocket)
        state = s
    }
}
