//
//  HighScoreStore.swift
//  DaedalusiOS
//
//  Tiny wrapper around UserDefaults for the persisted high score.
//

import Foundation
import Combine

/// Observable so SwiftUI views refresh when the record changes.
final class HighScoreStore: ObservableObject {

    static let shared = HighScoreStore()

    private let key = "daedalus.highScore"

    @Published private(set) var highScore: Int

    private init() {
        highScore = UserDefaults.standard.integer(forKey: key)
    }

    /// Records `score` if it beats the stored record. Returns true when a new
    /// record was set.
    @discardableResult
    func submit(_ score: Int) -> Bool {
        guard score > highScore else { return false }
        highScore = score
        UserDefaults.standard.set(score, forKey: key)
        return true
    }

    func reset() {
        highScore = 0
        UserDefaults.standard.removeObject(forKey: key)
    }
}
