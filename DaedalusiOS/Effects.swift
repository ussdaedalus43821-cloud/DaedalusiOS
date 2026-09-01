//
//  Effects.swift
//  DaedalusiOS
//
//  Fire-and-forget particle bursts built from SKShapeNodes + SKActions, so no
//  .sks emitter files are needed. Mirrors the "grander" layered explosion from
//  the desktop build: core flash, shock ring, rolling fireball, ember streaks.
//

import SpriteKit

enum Effects {

    private static let fireColors: [SKColor] = [
        SKColor(red: 1.0, green: 0.92, blue: 0.55, alpha: 1),
        SKColor(red: 1.0, green: 0.58, blue: 0.24, alpha: 1),
        SKColor(red: 1.0, green: 0.35, blue: 0.16, alpha: 1)
    ]

    static func explosion(in parent: SKNode, at pos: CGPoint, scale: CGFloat) {
        let s = max(0.6, scale)

        // core flash
        let flash = SKShapeNode(circleOfRadius: 20 * s)
        flash.position = pos
        flash.fillColor = SKColor(white: 1, alpha: 0.95)
        flash.strokeColor = .clear
        flash.zPosition = 60
        flash.blendMode = .add
        parent.addChild(flash)
        flash.run(.sequence([
            .group([.scale(to: 0.2, duration: 0.16), .fadeOut(withDuration: 0.16)]),
            .removeFromParent()
        ]))

        // shock rings
        for i in 0..<(1 + Int(s)) {
            let ring = SKShapeNode(circleOfRadius: 8)
            ring.position = pos
            ring.strokeColor = i == 0
                ? SKColor(red: 0.82, green: 0.93, blue: 1, alpha: 1)
                : SKColor(red: 1, green: 0.78, blue: 0.5, alpha: 1)
            ring.lineWidth = 3
            ring.fillColor = .clear
            ring.zPosition = 59
            parent.addChild(ring)
            ring.run(.sequence([
                .wait(forDuration: Double(i) * 0.05),
                .group([.scale(to: 4 * s + CGFloat(i) * 2, duration: 0.36),
                        .fadeOut(withDuration: 0.36)]),
                .removeFromParent()
            ]))
        }

        // rolling fireball
        for _ in 0..<Int(14 * s) {
            let p = SKShapeNode(circleOfRadius: CGFloat.random(in: 3...8) * s)
            p.position = pos
            p.fillColor = fireColors.randomElement()!
            p.strokeColor = .clear
            p.zPosition = 58
            p.blendMode = .add
            parent.addChild(p)
            let dir = CGVector(angle: .random(in: 0...(2 * .pi))) * (CGFloat.random(in: 40...220) * s)
            p.run(.sequence([
                .group([.move(by: dir, duration: 0.7),
                        .scale(to: 0.1, duration: 0.7),
                        .fadeOut(withDuration: 0.7)]),
                .removeFromParent()
            ]))
        }

        // ember streaks
        for _ in 0..<Int(8 * s) {
            let e = SKShapeNode(rectOf: CGSize(width: 3, height: 12), cornerRadius: 1.5)
            e.position = pos
            e.fillColor = SKColor(red: 1, green: 0.9, blue: 0.7, alpha: 1)
            e.strokeColor = .clear
            e.zPosition = 58
            e.blendMode = .add
            let dir = CGVector(angle: .random(in: 0...(2 * .pi))) * (CGFloat.random(in: 220...520) * s)
            e.zRotation = dir.angle - .pi / 2
            parent.addChild(e)
            e.run(.sequence([
                .group([.move(by: dir, duration: 0.55), .fadeOut(withDuration: 0.55)]),
                .removeFromParent()
            ]))
        }
    }

    static func hitSpark(in parent: SKNode, at pos: CGPoint, shielded: Bool) {
        let colors: [SKColor] = shielded
            ? [SKColor(red: 0.6, green: 0.82, blue: 1, alpha: 1),
               SKColor(red: 0.82, green: 0.92, blue: 1, alpha: 1)]
            : [SKColor(red: 1, green: 0.45, blue: 0.25, alpha: 1),
               SKColor(red: 1, green: 0.72, blue: 0.36, alpha: 1)]
        for _ in 0..<6 {
            let p = SKShapeNode(circleOfRadius: CGFloat.random(in: 1.5...3))
            p.position = pos
            p.fillColor = colors.randomElement()!
            p.strokeColor = .clear
            p.zPosition = 57
            p.blendMode = .add
            parent.addChild(p)
            let dir = CGVector(angle: .random(in: 0...(2 * .pi))) * CGFloat.random(in: 30...110)
            p.run(.sequence([
                .group([.move(by: dir, duration: 0.3), .fadeOut(withDuration: 0.3)]),
                .removeFromParent()
            ]))
        }
    }
}
