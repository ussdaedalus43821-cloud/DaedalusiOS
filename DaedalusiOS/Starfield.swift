//
//  Starfield.swift
//  DaedalusiOS
//
//  Three parallax layers of stars. Added as a child of the camera so it stays
//  screen-locked; each star's apparent position is the camera position scaled
//  by the layer's parallax factor, wrapped over the view size.
//

import SpriteKit

final class Starfield: SKNode {

    private struct Layer {
        let parallax: CGFloat
        let nodes: [SKShapeNode]
        let anchors: [CGPoint]        // 0..viewSize, the "true" position
    }

    private var layers: [Layer] = []
    private var viewSize: CGSize = .zero

    func build(viewSize: CGSize) {
        removeAllChildren()
        layers.removeAll()
        self.viewSize = viewSize
        guard viewSize.width > 0, viewSize.height > 0 else { return }

        let specs: [(par: CGFloat, count: Int, size: CGFloat, bright: CGFloat)] = [
            (0.30, 70, 1.0, 0.35),
            (0.55, 55, 1.5, 0.60),
            (0.85, 40, 2.0, 0.95)
        ]
        for spec in specs {
            var nodes: [SKShapeNode] = []
            var anchors: [CGPoint] = []
            for _ in 0..<spec.count {
                let dot = SKShapeNode(circleOfRadius: spec.size)
                dot.fillColor = SKColor(white: spec.bright, alpha: 1)
                dot.strokeColor = .clear
                addChild(dot)
                nodes.append(dot)
                anchors.append(CGPoint(x: .random(in: 0...viewSize.width),
                                       y: .random(in: 0...viewSize.height)))
            }
            layers.append(Layer(parallax: spec.par, nodes: nodes, anchors: anchors))
        }
    }

    func update(cameraPos: CGPoint) {
        let w = viewSize.width, h = viewSize.height
        guard w > 0, h > 0 else { return }
        for layer in layers {
            for (i, node) in layer.nodes.enumerated() {
                let a = layer.anchors[i]
                var x = (a.x - cameraPos.x * layer.parallax).truncatingRemainder(dividingBy: w)
                var y = (a.y - cameraPos.y * layer.parallax).truncatingRemainder(dividingBy: h)
                if x < 0 { x += w }
                if y < 0 { y += h }
                node.position = CGPoint(x: x - w / 2, y: y - h / 2)
            }
        }
    }
}
