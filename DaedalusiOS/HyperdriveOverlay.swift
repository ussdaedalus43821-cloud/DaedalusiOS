//
//  HyperdriveOverlay.swift
//  DaedalusiOS
//
//  The tactical hyperdrive UI: a tap grid of the ten sectors (JUMP button
//  opens it), plus the spool / transit visuals the scene drives.
//

import SpriteKit

final class HyperdriveOverlay: SKNode {

    /// Called with the chosen sector index, or nil for cancel.
    var onPick: ((Int?) -> Void)?

    private var cells: [(rect: CGRect, index: Int)] = []
    private let panel = SKShapeNode()
    private let dim = SKSpriteNode(color: SKColor(red: 0.02, green: 0.03, blue: 0.06, alpha: 0.82),
                                  size: .zero)

    override init() {
        super.init()
        zPosition = 3000
        isHidden = true
        addChild(dim)
        panel.strokeColor = SKColor(red: 0.4, green: 0.7, blue: 1, alpha: 0.6)
        panel.lineWidth = 1
        panel.fillColor = SKColor(red: 0.03, green: 0.05, blue: 0.09, alpha: 0.95)
        addChild(panel)
        isUserInteractionEnabled = false     // GameScene forwards touches
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func present(size: CGSize, currentIndex: Int) {
        isHidden = false
        removeChildCells()
        cells.removeAll()
        dim.size = CGSize(width: size.width * 2, height: size.height * 2)

        let cols = 2
        let cw: CGFloat = min(260, (size.width - 60) / CGFloat(cols))
        let ch: CGFloat = 52
        let rows = (Sectors.all.count + cols - 1) / cols
        let gridW = CGFloat(cols) * cw
        let gridH = CGFloat(rows) * ch
        let pad: CGFloat = 26

        panel.path = CGPath(roundedRect: CGRect(x: -gridW / 2 - pad, y: -gridH / 2 - pad - 20,
                                                width: gridW + pad * 2, height: gridH + pad * 2 + 44),
                            cornerWidth: 14, cornerHeight: 14, transform: nil)

        let title = SKLabelNode(fontNamed: "Menlo-Bold")
        title.text = "SELECT  JUMP  DESTINATION"
        title.fontSize = 15
        title.fontColor = SKColor(red: 0.6, green: 0.85, blue: 1, alpha: 1)
        title.position = CGPoint(x: 0, y: gridH / 2 + 8)
        title.name = "cell"
        addChild(title)

        for i in 0..<Sectors.all.count {
            let r = i / cols, c = i % cols
            let x = -gridW / 2 + CGFloat(c) * cw + cw / 2
            let y = gridH / 2 - CGFloat(r) * ch - ch / 2 - 22
            let rect = CGRect(x: x - cw / 2 + 4, y: y - ch / 2 + 3, width: cw - 8, height: ch - 6)
            cells.append((rect, i))

            let box = SKShapeNode(rect: rect, cornerRadius: 8)
            box.fillColor = i == currentIndex
                ? SKColor(red: 0.12, green: 0.2, blue: 0.32, alpha: 1)
                : SKColor(white: 0.1, alpha: 0.9)
            box.strokeColor = SKColor(red: 0.35, green: 0.6, blue: 0.95, alpha: 0.7)
            box.lineWidth = 1
            box.name = "cell"
            addChild(box)

            let key = SKLabelNode(fontNamed: "Menlo-Bold")
            key.text = "\(i + 1)".replacingOccurrences(of: "10", with: "0")
            key.fontSize = 16
            key.fontColor = SKColor(red: 0.55, green: 0.8, blue: 1, alpha: 1)
            key.horizontalAlignmentMode = .left
            key.verticalAlignmentMode = .center
            key.position = CGPoint(x: rect.minX + 10, y: y)
            key.name = "cell"
            addChild(key)

            let name = SKLabelNode(fontNamed: "Menlo-Regular")
            name.text = Sectors.shortName(i)
            name.fontSize = 11
            name.fontColor = .white
            name.horizontalAlignmentMode = .left
            name.verticalAlignmentMode = .center
            name.position = CGPoint(x: rect.minX + 34, y: y + 7)
            name.name = "cell"
            addChild(name)

            let dgr = SKLabelNode(fontNamed: "Menlo-Regular")
            let s = Sectors.all[i]
            dgr.text = "danger \(s.danger)   charge \(String(format: "%.1f", s.charge))s / \(Int(s.travel))s"
            dgr.fontSize = 8.5
            dgr.fontColor = SKColor(white: 0.55, alpha: 1)
            dgr.horizontalAlignmentMode = .left
            dgr.verticalAlignmentMode = .center
            dgr.position = CGPoint(x: rect.minX + 34, y: y - 8)
            dgr.name = "cell"
            addChild(dgr)
        }

        let cancel = SKLabelNode(fontNamed: "Menlo-Bold")
        cancel.text = "TAP OUTSIDE TO CANCEL"
        cancel.fontSize = 10
        cancel.fontColor = SKColor(white: 0.5, alpha: 1)
        cancel.position = CGPoint(x: 0, y: -gridH / 2 - 34)
        cancel.name = "cell"
        addChild(cancel)
    }

    /// `p` is in this node's coordinate space.
    func handleTap(_ p: CGPoint) {
        for cell in cells where cell.rect.contains(p) {
            dismiss()
            onPick?(cell.index)
            return
        }
        dismiss()
        onPick?(nil)
    }

    func dismiss() {
        isHidden = true
        removeChildCells()
    }

    private func removeChildCells() {
        for c in children where c.name == "cell" { c.removeFromParent() }
    }
}
