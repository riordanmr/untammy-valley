//
//  GameState.swift
//  UntammyValley
//
//  Created by Mark Riordan on 2026-02-18.
//

import Foundation

final class GameState {
    static let shared = GameState()

    private(set) var coins: Int {
        didSet {
            UserDefaults.standard.set(coins, forKey: Self.coinsKey)
        }
    }

    private static let coinsKey = "game.coins"

    private init() {
        coins = UserDefaults.standard.integer(forKey: Self.coinsKey)
    }

    @discardableResult
    func addCoins(_ amount: Int) -> Int {
        coins += max(0, amount)
        return coins
    }


    @discardableResult
    func removeCoins(_ amount: Int) -> Int {
        coins = max(0, coins - max(0, amount))
        return coins
    }

    func resetCoins() {
        coins = 0
    }
}
