//
//  Sectors.swift
//  DaedalusiOS
//
//  The 10 hyperdrive destinations, ported from the desktop SECTORS table.
//  Each carries its own danger, ambient spawn mix, per-destination charge /
//  travel timing, backdrop tint and scenery.
//

import SpriteKit

struct SectorSpec {
    var name: String
    var danger: Int                 // 0 safe .. 3 EXTREME
    var spawns: Bool = true         // false == home / safe: no ambient hostiles
    var fighterCd: ClosedRange<CGFloat>
    var charge: CGFloat
    var travel: CGFloat
    var tint: SKColor
    var enemyMix: [(EnemyKind, Int)]? = nil
    var uniqueSpawn: EnemyKind? = nil        // the one replicator
    var scenery: [LandmarkSpec] = []

    var mix: [(EnemyKind, Int)] {
        enemyMix ?? [(.fighter, 5), (.capital, 1)]
    }
}

enum Sectors {

    static let all: [SectorSpec] = [
        SectorSpec(
            name: "Terra Nova Orbit  //  HOME", danger: 0, spawns: false,
            fighterCd: 6...11, charge: 1.2, travel: 2.0,
            tint: SKColor(red: 0.035, green: 0.055, blue: 0.10, alpha: 1),
            scenery: [
                LandmarkSpec(kind: .planet, seed: 11, offset: CGVector(dx: 320, dy: -360),
                             radius: 420, core: SKColor(red: 0.15, green: 0.33, blue: 0.52, alpha: 1),
                             land: SKColor(red: 0.29, green: 0.48, blue: 0.36, alpha: 1),
                             atmo: SKColor(red: 0.47, green: 0.7, blue: 1, alpha: 1), continents: true),
                LandmarkSpec(kind: .moon, seed: 12, offset: CGVector(dx: -560, dy: 300),
                             radius: 80, core: SKColor(white: 0.4, alpha: 1),
                             land: SKColor(white: 0.55, alpha: 1),
                             atmo: SKColor(white: 0.6, alpha: 1))
            ]),

        SectorSpec(
            name: "Pegasus Gate", danger: 2, fighterCd: 2.2...4.6, charge: 2.5, travel: 5.0,
            tint: SKColor(red: 0.08, green: 0.04, blue: 0.11, alpha: 1),
            scenery: [
                LandmarkSpec(kind: .stargate, seed: 21, offset: CGVector(dx: 280, dy: 110), radius: 240),
                LandmarkSpec(kind: .planet, seed: 22, offset: CGVector(dx: -1400, dy: 900),
                             radius: 360, core: SKColor(red: 0.27, green: 0.23, blue: 0.36, alpha: 1),
                             atmo: SKColor(red: 0.6, green: 0.5, blue: 0.8, alpha: 1))
            ]),

        SectorSpec(
            name: "Deep Void", danger: 1, fighterCd: 5...9.5, charge: 3.0, travel: 8.0,
            tint: SKColor(red: 0.02, green: 0.02, blue: 0.045, alpha: 1),
            scenery: [
                LandmarkSpec(kind: .nebula, seed: 31, offset: CGVector(dx: 280, dy: 120), radius: 900,
                             nebulaColor: SKColor(red: 0.31, green: 0.17, blue: 0.48, alpha: 1)),
                LandmarkSpec(kind: .nebula, seed: 32, offset: CGVector(dx: -780, dy: -520), radius: 680,
                             nebulaColor: SKColor(red: 0.11, green: 0.24, blue: 0.48, alpha: 1))
            ]),

        SectorSpec(
            name: "Asuran Frontier  //  EXTREME", danger: 3, fighterCd: 1.3...2.8,
            charge: 2.2, travel: 6.0,
            tint: SKColor(red: 0.10, green: 0.045, blue: 0.035, alpha: 1),
            enemyMix: [(.fighter, 3), (.capital, 2)], uniqueSpawn: .replicator,
            scenery: [
                LandmarkSpec(kind: .planet, seed: 41, offset: CGVector(dx: 360, dy: 280),
                             radius: 460, core: SKColor(red: 0.47, green: 0.18, blue: 0.13, alpha: 1),
                             land: SKColor(red: 0.35, green: 0.12, blue: 0.10, alpha: 1),
                             atmo: SKColor(red: 1, green: 0.43, blue: 0.27, alpha: 1), continents: true),
                LandmarkSpec(kind: .debris, seed: 42, offset: CGVector(dx: -120, dy: -180),
                             radius: 900, debrisCount: 50)
            ]),

        SectorSpec(
            name: "Lantea Orbit  //  LOW DANGER", danger: 1, fighterCd: 4.5...8,
            charge: 1.8, travel: 3.2,
            tint: SKColor(red: 0.03, green: 0.05, blue: 0.09, alpha: 1),
            scenery: [
                LandmarkSpec(kind: .planet, seed: 51, offset: CGVector(dx: -320, dy: -300),
                             radius: 500, core: SKColor(red: 0.10, green: 0.26, blue: 0.46, alpha: 1),
                             land: SKColor(red: 0.24, green: 0.52, blue: 0.58, alpha: 1),
                             atmo: SKColor(red: 0.5, green: 0.75, blue: 1, alpha: 1)),
                LandmarkSpec(kind: .moon, seed: 52, offset: CGVector(dx: 700, dy: 360), radius: 70,
                             core: SKColor(white: 0.42, alpha: 1), land: SKColor(white: 0.6, alpha: 1),
                             atmo: SKColor(white: 0.6, alpha: 1))
            ]),

        SectorSpec(
            name: "Chulak Approach  //  MEDIUM", danger: 2, fighterCd: 2.4...5,
            charge: 2.4, travel: 4.6,
            tint: SKColor(red: 0.085, green: 0.06, blue: 0.04, alpha: 1),
            scenery: [
                LandmarkSpec(kind: .planet, seed: 61, offset: CGVector(dx: 400, dy: 260),
                             radius: 470, core: SKColor(red: 0.38, green: 0.28, blue: 0.17, alpha: 1),
                             land: SKColor(red: 0.59, green: 0.46, blue: 0.27, alpha: 1),
                             atmo: SKColor(red: 0.86, green: 0.67, blue: 0.47, alpha: 1), continents: true),
                LandmarkSpec(kind: .debris, seed: 62, offset: CGVector(dx: -260, dy: -220),
                             radius: 760, debrisCount: 30)
            ]),

        SectorSpec(
            name: "Dakara Sands  //  HIGH DANGER", danger: 3, fighterCd: 1.5...3.2,
            charge: 2.6, travel: 5.4,
            tint: SKColor(red: 0.09, green: 0.07, blue: 0.045, alpha: 1),
            scenery: [
                LandmarkSpec(kind: .planet, seed: 71, offset: CGVector(dx: -360, dy: 300),
                             radius: 560, core: SKColor(red: 0.47, green: 0.36, blue: 0.20, alpha: 1),
                             land: SKColor(red: 0.71, green: 0.57, blue: 0.36, alpha: 1),
                             atmo: SKColor(red: 0.94, green: 0.78, blue: 0.55, alpha: 1), continents: true)
            ]),

        SectorSpec(
            name: "The Supergate  //  ORI", danger: 3, fighterCd: 2...4, charge: 3.2, travel: 6.6,
            tint: SKColor(red: 0.055, green: 0.04, blue: 0.086, alpha: 1),
            enemyMix: [(.fighter, 3), (.ori, 2)],
            scenery: [
                LandmarkSpec(kind: .stargate, seed: 81, offset: CGVector(dx: 220, dy: 60), radius: 540)
            ]),

        SectorSpec(
            name: "Hive Territory  //  WRAITH", danger: 3, fighterCd: 1.4...3, charge: 2.4, travel: 6.2,
            tint: SKColor(red: 0.062, green: 0.03, blue: 0.078, alpha: 1),
            enemyMix: [(.dart, 7), (.wcruiser, 3), (.whive, 1)],
            scenery: [
                LandmarkSpec(kind: .nebula, seed: 91, offset: CGVector(dx: 200, dy: -120), radius: 1050,
                             nebulaColor: SKColor(red: 0.38, green: 0.16, blue: 0.38, alpha: 1)),
                LandmarkSpec(kind: .debris, seed: 92, offset: CGVector(dx: -320, dy: 260),
                             radius: 880, debrisCount: 40)
            ]),

        SectorSpec(
            name: "The Black Rift  //  DEEP VOID", danger: 1, fighterCd: 5.5...10,
            charge: 3.4, travel: 9.0,
            tint: SKColor(red: 0.012, green: 0.012, blue: 0.03, alpha: 1),
            scenery: [
                LandmarkSpec(kind: .blackhole, seed: 101, offset: CGVector(dx: 360, dy: 220), radius: 150),
                LandmarkSpec(kind: .nebula, seed: 102, offset: CGVector(dx: -900, dy: -500), radius: 780,
                             nebulaColor: SKColor(red: 0.27, green: 0.12, blue: 0.16, alpha: 1))
            ])
    ]

    static func shortName(_ i: Int) -> String {
        all[i % all.count].name.components(separatedBy: "//").first!
            .trimmingCharacters(in: .whitespaces)
    }
}
