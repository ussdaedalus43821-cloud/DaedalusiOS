//
//  ContentView.swift
//  DaedalusiOS
//
//  Main menu: title, Start Game, and the persisted high score.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var highScores = HighScoreStore.shared
    @State private var showGame = false

    var body: some View {
        ZStack {
            menu
            if showGame {
                GameContainerView { showGame = false }
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.25), value: showGame)
    }

    private var menu: some View {
        ZStack {
            ZStack {
                MenuBackground()

                VStack(spacing: 28) {
                    Spacer()

                    VStack(spacing: 6) {
                        Text("DAEDALUS")
                            .font(.system(size: 52, weight: .heavy, design: .rounded))
                            .foregroundStyle(.cyan)
                            .shadow(color: .cyan.opacity(0.6), radius: 12)
                        Text("SPACE FIGHTER")
                            .font(.system(size: 16, weight: .semibold, design: .monospaced))
                            .tracking(6)
                            .foregroundStyle(.white.opacity(0.7))
                    }

                    Spacer()

                    HStack(spacing: 10) {
                        Image(systemName: "trophy.fill")
                            .foregroundStyle(.yellow)
                        Text("HIGH SCORE")
                            .font(.system(size: 14, weight: .bold, design: .monospaced))
                            .foregroundStyle(.white.opacity(0.65))
                        Text("\(highScores.highScore)")
                            .font(.system(size: 20, weight: .bold, design: .monospaced))
                            .foregroundStyle(.white)
                            .contentTransition(.numericText())
                    }
                    .padding(.horizontal, 22)
                    .padding(.vertical, 12)
                    .background(.white.opacity(0.08), in: Capsule())

                    Button {
                        showGame = true
                    } label: {
                        Text("START GAME")
                            .font(.system(size: 22, weight: .heavy, design: .rounded))
                            .frame(maxWidth: 320)
                            .padding(.vertical, 18)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.cyan)
                    .foregroundStyle(.black)

                    Text("«  » rotate   ·   THR thrust   ·   FIRE / RKT")
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.45))

                    Spacer()
                }
                .padding()
            }
        }
        .tint(.cyan)
    }
}

/// A slow parallax starfield behind the menu, drawn with TimelineView so it
/// needs no SpriteKit scene of its own.
private struct MenuBackground: View {
    private let stars: [Star] = (0..<90).map { _ in Star() }

    var body: some View {
        TimelineView(.animation) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate
            Canvas { context, size in
                context.fill(Path(CGRect(origin: .zero, size: size)),
                             with: .color(Color(red: 0.02, green: 0.03, blue: 0.08)))
                for star in stars {
                    let y = (star.y + t * star.speed / 40).truncatingRemainder(dividingBy: 1)
                    let point = CGPoint(x: star.x * size.width, y: y * size.height)
                    let rect = CGRect(x: point.x, y: point.y, width: star.size, height: star.size)
                    context.fill(Path(ellipseIn: rect),
                                 with: .color(.white.opacity(star.brightness)))
                }
            }
        }
        .ignoresSafeArea()
    }

    private struct Star {
        let x = Double.random(in: 0...1)
        let y = Double.random(in: 0...1)
        let size = Double.random(in: 1...2.6)
        let speed = Double.random(in: 0.6...2.2)
        let brightness = Double.random(in: 0.25...0.9)
    }
}

#Preview {
    ContentView()
}
