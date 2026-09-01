//
//  DaedalusApp.swift
//  DaedalusiOS
//
//  App entry point. SwiftUI drives the menu; SpriteKit drives the game.
//

import SwiftUI

@main
struct DaedalusApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(.dark)
        }
    }
}
