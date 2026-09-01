//
//  MathHelpers.swift
//  DaedalusiOS
//
//  Vector / angle helpers. SpriteKit's coordinate space is +y up, angles in
//  radians with 0 == +x (pointing right), positive == counter-clockwise.
//

import CoreGraphics
import Foundation

@inline(__always)
func clampf(_ v: CGFloat, _ lo: CGFloat, _ hi: CGFloat) -> CGFloat {
    v < lo ? lo : (v > hi ? hi : v)
}

/// `pow` for CGFloat without tripping the CGFloat/Double overload ambiguity.
@inline(__always)
func vpow(_ base: CGFloat, _ exp: CGFloat) -> CGFloat {
    CGFloat(pow(Double(base), Double(exp)))
}

extension CGFloat {
    var radians: CGFloat { self * .pi / 180 }
    var degrees: CGFloat { self * 180 / .pi }
}

extension CGVector {
    init(angle: CGFloat) { self.init(dx: cos(angle), dy: sin(angle)) }

    var length: CGFloat { (dx * dx + dy * dy).squareRoot() }
    var lengthSquared: CGFloat { dx * dx + dy * dy }
    var angle: CGFloat { atan2(dy, dx) }

    var normalized: CGVector {
        let l = length
        return l > 1e-6 ? CGVector(dx: dx / l, dy: dy / l) : CGVector(dx: 1, dy: 0)
    }

    func scaled(to len: CGFloat) -> CGVector { normalized * len }

    func rotated(by a: CGFloat) -> CGVector {
        let c = cos(a), s = sin(a)
        return CGVector(dx: dx * c - dy * s, dy: dx * s + dy * c)
    }

    static func + (a: CGVector, b: CGVector) -> CGVector { CGVector(dx: a.dx + b.dx, dy: a.dy + b.dy) }
    static func - (a: CGVector, b: CGVector) -> CGVector { CGVector(dx: a.dx - b.dx, dy: a.dy - b.dy) }
    static func * (a: CGVector, s: CGFloat) -> CGVector { CGVector(dx: a.dx * s, dy: a.dy * s) }
    static prefix func - (a: CGVector) -> CGVector { CGVector(dx: -a.dx, dy: -a.dy) }
    static func += (a: inout CGVector, b: CGVector) { a = a + b }
    static func -= (a: inout CGVector, b: CGVector) { a = a - b }
    static func *= (a: inout CGVector, s: CGFloat) { a = a * s }
}

extension CGPoint {
    static func + (p: CGPoint, v: CGVector) -> CGPoint { CGPoint(x: p.x + v.dx, y: p.y + v.dy) }
    static func += (p: inout CGPoint, v: CGVector) { p = p + v }
    static func - (a: CGPoint, b: CGPoint) -> CGVector { CGVector(dx: a.x - b.x, dy: a.y - b.y) }

    func distance(to p: CGPoint) -> CGFloat { (self - p).length }
    func distanceSquared(to p: CGPoint) -> CGFloat { (self - p).lengthSquared }
}

/// Shortest signed angular difference `target - current`, wrapped to (-pi, pi].
func angleDelta(_ current: CGFloat, _ target: CGFloat) -> CGFloat {
    var d = (target - current).truncatingRemainder(dividingBy: 2 * .pi)
    if d > .pi { d -= 2 * .pi }
    if d < -.pi { d += 2 * .pi }
    return d
}

/// Rotate `current` toward `target` by at most `maxStep` radians.
func approachAngle(_ current: CGFloat, _ target: CGFloat, _ maxStep: CGFloat) -> CGFloat {
    let d = angleDelta(current, target)
    if abs(d) <= maxStep { return target }
    return current + (d > 0 ? maxStep : -maxStep)
}
