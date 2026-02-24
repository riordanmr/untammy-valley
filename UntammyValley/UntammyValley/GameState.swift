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

    private(set) var quizStatsBySubject: [String: QuizSubjectStats] {
        didSet {
            persistQuizStats()
        }
    }

    private static let coinsKey = "game.coins"
    private static let quizStatsKey = "game.quizStatsBySubject"

    private init() {
        coins = UserDefaults.standard.integer(forKey: Self.coinsKey)
        if let data = UserDefaults.standard.data(forKey: Self.quizStatsKey),
           let decoded = try? JSONDecoder().decode([String: QuizSubjectStats].self, from: data) {
            quizStatsBySubject = decoded
        } else {
            quizStatsBySubject = [:]
        }
    }

    private func persistQuizStats() {
        if let data = try? JSONEncoder().encode(quizStatsBySubject) {
            UserDefaults.standard.set(data, forKey: Self.quizStatsKey)
        }
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

    @discardableResult
    func setCoins(_ amount: Int) -> Int {
        coins = max(0, amount)
        return coins
    }

    func resetCoins() {
        coins = 0
    }

    func quizTotals(for subject: String) -> QuizSubjectStats {
        quizStatsBySubject[subject] ?? QuizSubjectStats(answered: 0, correct: 0)
    }

    @discardableResult
    func addQuizResults(subject: String, answered answeredCount: Int, correct correctCount: Int) -> QuizSubjectStats {
        let safeAnswered = max(0, answeredCount)
        let safeCorrect = max(0, min(safeAnswered, correctCount))
        var current = quizStatsBySubject[subject] ?? QuizSubjectStats(answered: 0, correct: 0)
        current.answered += safeAnswered
        current.correct += safeCorrect
        quizStatsBySubject[subject] = current
        return current
    }
}
