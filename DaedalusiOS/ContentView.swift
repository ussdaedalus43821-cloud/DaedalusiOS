//
//  ContentView.swift
//  DaedalusiOS
//
//  SwiftUI front end: main menu, ship select, live settings, controls, and the
//  full-screen SpriteKit game overlay.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var highScores = HighScoreStore.shared
    @State private var screen: Screen = .menu
    @State private var showGame = false

    enum Screen { case menu, ships, settings, controls }

    var body: some View {
        ZStack {
            MenuBackground().ignoresSafeArea()

            switch screen {
            case .menu:     mainMenu
            case .ships:    ShipSelectView { screen = .menu }
            case .settings: SettingsView { screen = .menu }
            case .controls: ControlsView { screen = .menu }
            }

            if showGame {
                GameContainerView { showGame = false }
                    .transition(.opacity)
            }
        }
        .preferredColorScheme(.dark)
        .tint(.cyan)
        .animation(.easeInOut(duration: 0.2), value: showGame)
        .animation(.easeInOut(duration: 0.15), value: screen)
    }

    private var mainMenu: some View {
        VStack(spacing: 20) {
            Spacer()
            Text("DAEDALUS")
                .font(.system(size: 52, weight: .heavy, design: .rounded))
                .foregroundStyle(.cyan)
                .shadow(color: .cyan.opacity(0.6), radius: 12)
            Text("OPEN-WORLD SPACE COMBAT")
                .font(.system(size: 13, weight: .semibold, design: .monospaced))
                .tracking(4).foregroundStyle(.white.opacity(0.6))
            Spacer()

            HStack(spacing: 10) {
                Image(systemName: "trophy.fill").foregroundStyle(.yellow)
                Text("HIGH SCORE").font(.system(size: 13, weight: .bold, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.65))
                Text("\(highScores.highScore)")
                    .font(.system(size: 19, weight: .bold, design: .monospaced))
                    .foregroundStyle(.white).contentTransition(.numericText())
            }
            .padding(.horizontal, 20).padding(.vertical, 10)
            .background(.white.opacity(0.08), in: Capsule())

            VStack(spacing: 12) {
                bigButton("START GAME") { showGame = true }
                HStack(spacing: 12) {
                    smallButton("SELECT SHIP") { screen = .ships }
                    smallButton("SETTINGS") { screen = .settings }
                }
                smallButton("CONTROLS") { screen = .controls }
            }
            .frame(maxWidth: 360)

            Text("Ship: \(Ships.spec(PlayerLoadout.selected).name)   ·   \(Settings.shared.difficulty.name)")
                .font(.system(size: 11, design: .monospaced))
                .foregroundStyle(.white.opacity(0.4))
            Spacer()
        }
        .padding()
    }

    private func bigButton(_ t: String, _ a: @escaping () -> Void) -> some View {
        Button(action: a) {
            Text(t).font(.system(size: 22, weight: .heavy, design: .rounded))
                .frame(maxWidth: .infinity).padding(.vertical, 16)
        }
        .buttonStyle(.borderedProminent).tint(.cyan).foregroundStyle(.black)
    }
    private func smallButton(_ t: String, _ a: @escaping () -> Void) -> some View {
        Button(action: a) {
            Text(t).font(.system(size: 15, weight: .bold, design: .monospaced))
                .frame(maxWidth: .infinity).padding(.vertical, 12)
        }
        .buttonStyle(.bordered).tint(.cyan)
    }
}

// =====================================================================
// MARK: - Ship select
// =====================================================================
private struct ShipSelectView: View {
    var onDone: () -> Void
    @State private var selected = PlayerLoadout.selected

    var body: some View {
        VStack(spacing: 12) {
            header("SELECT SHIP", onDone)
            ScrollView {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 250), spacing: 12)], spacing: 12) {
                    ForEach(ShipID.allCases) { id in
                        card(id)
                    }
                }
                .padding()
            }
        }
    }

    private func card(_ id: ShipID) -> some View {
        let s = Ships.spec(id)
        let on = id == selected
        return VStack(alignment: .leading, spacing: 4) {
            Text(s.name).font(.system(size: 15, weight: .bold, design: .monospaced))
                .foregroundStyle(.white)
            Text(s.role).font(.system(size: 10, design: .monospaced))
                .foregroundStyle(.cyan.opacity(0.8))
            Divider().overlay(.white.opacity(0.15))
            stat("SHIELD", Int(s.shieldMax)); stat("HULL", Int(s.hullMax))
            stat("SPEED", Int(s.maxSpeed)); stat("TURN", Int(s.turn.degrees))
            Text(special(s)).font(.system(size: 10, weight: .bold, design: .monospaced))
                .foregroundStyle(.yellow).padding(.top, 2)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(on ? .cyan.opacity(0.14) : .white.opacity(0.05),
                    in: RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12)
            .stroke(on ? .cyan : .white.opacity(0.15), lineWidth: on ? 2 : 1))
        .contentShape(Rectangle())
        .onTapGesture { selected = id; PlayerLoadout.selected = id }
    }

    private func special(_ s: ShipSpec) -> String {
        if s.beamDmg > 0 { return "ASGARD BEAM" }
        if s.hardened { return "HARDENED SHIELD · \(s.homingSalvo)x DRONE" }
        if s.turrets > 0 { return "\(s.turrets) TURRETS · \(s.homingSalvo)x DRONE" }
        if s.homingSalvo >= 2 { return "\(s.homingSalvo)x DRONE SALVO" }
        return "GUNS + ORDNANCE"
    }
    private func stat(_ k: String, _ v: Int) -> some View {
        HStack {
            Text(k).font(.system(size: 10, design: .monospaced)).foregroundStyle(.white.opacity(0.5))
            Spacer()
            Text("\(v)").font(.system(size: 11, weight: .semibold, design: .monospaced))
                .foregroundStyle(.white.opacity(0.9))
        }
    }
}

// =====================================================================
// MARK: - Settings
// =====================================================================
private struct SettingsView: View {
    var onDone: () -> Void
    @State private var tick = 0
    private var s: Settings { Settings.shared }

    var body: some View {
        let _ = tick
        VStack(spacing: 0) {
            header("SETTINGS", onDone)
            Form {
                Section("MISSION") {
                    Picker("Difficulty", selection: bind(\.difficulty)) {
                        ForEach(Difficulty.allCases) { Text($0.name).tag($0) }
                    }
                    Picker("Start sector", selection: bind(\.startSector)) {
                        ForEach(0..<Sectors.all.count, id: \.self) {
                            Text(Sectors.shortName($0)).tag($0)
                        }
                    }
                    Stepper("Starting wingmen: \(s.startWingmen)",
                            value: bind(\.startWingmen), in: 0...GC.allyMaxWingmen)
                }
                Section("CHEATS") {
                    toggle("God mode", \.godMode)
                    toggle("Infinite rockets", \.infiniteRockets)
                    toggle("Infinite homing", \.infiniteHoming)
                    toggle("Infinite beam", \.infiniteBeam)
                    toggle("No weapon cooldown", \.noCooldown)
                    toggle("One-shot kill", \.oneShotKill)
                    toggle("Auto hull repair", \.autoRepair)
                    toggle("Cloak available", \.cloakEnabled)
                }
            }
            .scrollContentBackground(.hidden)
        }
    }

    private func bind<T>(_ kp: ReferenceWritableKeyPath<Settings, T>) -> Binding<T> {
        Binding(get: { Settings.shared[keyPath: kp] },
                set: { Settings.shared[keyPath: kp] = $0; tick += 1 })
    }
    private func toggle(_ t: String, _ kp: ReferenceWritableKeyPath<Settings, Bool>) -> some View {
        Toggle(t, isOn: bind(kp)).font(.system(size: 14, design: .monospaced))
    }
}

// =====================================================================
// MARK: - Controls
// =====================================================================
private struct ControlsView: View {
    var onDone: () -> Void
    private let rows: [(String, String)] = [
        ("«  »", "rotate left / right"),
        ("THR", "thrust along the nose"),
        ("FIRE", "energy cannons (hold)"),
        ("RKT", "splash rockets (hold)"),
        ("HOM", "homing drone salvo"),
        ("BEAM", "Asgard beam — BC-304 / BC-305 only (hold)"),
        ("CLK", "invincibility cloak — shields go offline"),
        ("WING", "call an allied wingman"),
        ("JUMP", "open the hyperdrive sector map"),
        ("tap", "return to menu on the game-over screen")
    ]
    var body: some View {
        VStack(spacing: 0) {
            header("CONTROLS", onDone)
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    ForEach(rows, id: \.0) { r in
                        HStack(alignment: .top, spacing: 14) {
                            Text(r.0).font(.system(size: 14, weight: .bold, design: .monospaced))
                                .foregroundStyle(.cyan).frame(width: 66, alignment: .leading)
                            Text(r.1).font(.system(size: 13, design: .monospaced))
                                .foregroundStyle(.white.opacity(0.8))
                        }
                    }
                }
                .padding(24)
            }
        }
    }
}

// =====================================================================
private func header(_ title: String, _ onDone: @escaping () -> Void) -> some View {
    HStack {
        Button { onDone() } label: {
            Image(systemName: "chevron.left"); Text("MENU")
        }
        .font(.system(size: 14, weight: .bold, design: .monospaced))
        Spacer()
        Text(title).font(.system(size: 18, weight: .heavy, design: .monospaced))
            .foregroundStyle(.cyan)
        Spacer()
        Color.clear.frame(width: 70)
    }
    .padding(.horizontal, 18).padding(.vertical, 14)
}

// =====================================================================
// MARK: - Menu backdrop
// =====================================================================
private struct MenuBackground: View {
    private let stars: [Star] = (0..<90).map { _ in Star() }
    var body: some View {
        TimelineView(.animation) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate
            Canvas { ctx, size in
                ctx.fill(Path(CGRect(origin: .zero, size: size)),
                         with: .color(Color(red: 0.02, green: 0.03, blue: 0.08)))
                for s in stars {
                    let y = (s.y + t * s.speed / 40).truncatingRemainder(dividingBy: 1)
                    let rect = CGRect(x: s.x * size.width, y: y * size.height, width: s.size, height: s.size)
                    ctx.fill(Path(ellipseIn: rect), with: .color(.white.opacity(s.brightness)))
                }
            }
        }
    }
    private struct Star {
        let x = Double.random(in: 0...1), y = Double.random(in: 0...1)
        let size = Double.random(in: 1...2.6), speed = Double.random(in: 0.6...2.2)
        let brightness = Double.random(in: 0.25...0.9)
    }
}

#Preview { ContentView() }
