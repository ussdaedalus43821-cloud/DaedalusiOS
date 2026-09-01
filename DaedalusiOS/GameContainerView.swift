//
//  GameContainerView.swift
//  DaedalusiOS
//
//  SwiftUI host for the SpriteKit game scene. Shown as a full-screen overlay
//  (no NavigationStack) so the SpriteView -- and its on-screen controls --
//  own every pixel including the very bottom edge. `.resizeFill` keeps the
//  scene matched to the view for iPad rotation.
//

import SwiftUI
import SpriteKit

struct GameContainerView: View {
    /// Called by the scene when the player taps through the game-over screen.
    let onExit: () -> Void

    @State private var scene: GameScene = {
        let scene = GameScene(size: CGSize(width: 750, height: 1334))
        scene.scaleMode = .resizeFill
        return scene
    }()

    var body: some View {
        SpriteView(scene: scene, options: [.ignoresSiblingOrder])
            .ignoresSafeArea()
            .statusBarHidden(true)
            .persistentSystemOverlays(.hidden)
            .onAppear { scene.onReturnToMenu = onExit }
    }
}
