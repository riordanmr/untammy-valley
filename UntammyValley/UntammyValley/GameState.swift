//
//  GameState.swift
//  UntammyValley
//
//  Created by Mark Riordan on 2026-02-18.
//

import Foundation

final class GameState {
    static let shared = GameState()

    private static let trackedQuizSubjects = ["English", "US History", "Mathematics", "Science"]

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

    private(set) var studyGuideOpenedBySubject: [String: Bool] {
        didSet {
            persistStudyGuideOpenedBySubject()
        }
    }

    private static let coinsKey = "game.coins"
    private static let quizStatsKey = "game.quizStatsBySubject"
    private static let studyGuideOpenedBySubjectKey = "game.studyGuideOpenedBySubject"

    private init() {
        coins = UserDefaults.standard.integer(forKey: Self.coinsKey)
        if let data = UserDefaults.standard.data(forKey: Self.quizStatsKey),
           let decoded = try? JSONDecoder().decode([String: QuizSubjectStats].self, from: data) {
            quizStatsBySubject = decoded
        } else {
            quizStatsBySubject = [:]
        }

        if let data = UserDefaults.standard.data(forKey: Self.studyGuideOpenedBySubjectKey),
           let decoded = try? JSONDecoder().decode([String: Bool].self, from: data) {
            studyGuideOpenedBySubject = Self.normalizedStudyGuideOpenedBySubject(decoded)
        } else {
            studyGuideOpenedBySubject = Self.defaultStudyGuideOpenedBySubject()
        }
    }

    private func persistQuizStats() {
        if let data = try? JSONEncoder().encode(quizStatsBySubject) {
            UserDefaults.standard.set(data, forKey: Self.quizStatsKey)
        }
    }

    private func persistStudyGuideOpenedBySubject() {
        if let data = try? JSONEncoder().encode(studyGuideOpenedBySubject) {
            UserDefaults.standard.set(data, forKey: Self.studyGuideOpenedBySubjectKey)
        }
    }

    private static func defaultStudyGuideOpenedBySubject() -> [String: Bool] {
        var result: [String: Bool] = [:]
        for subject in trackedQuizSubjects {
            result[subject] = false
        }
        return result
    }

    private static func normalizedStudyGuideOpenedBySubject(_ values: [String: Bool]) -> [String: Bool] {
        var normalized = defaultStudyGuideOpenedBySubject()
        for subject in trackedQuizSubjects {
            if let isOpened = values[subject] {
                normalized[subject] = isOpened
            }
        }
        return normalized
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

    func resetQuizStats() {
        quizStatsBySubject = [:]
    }

    func hasOpenedStudyGuide(for subject: String) -> Bool {
        guard Self.trackedQuizSubjects.contains(subject) else {
            return false
        }
        return studyGuideOpenedBySubject[subject] ?? false
    }

    func markStudyGuideOpened(for subject: String) {
        guard Self.trackedQuizSubjects.contains(subject) else {
            return
        }

        guard studyGuideOpenedBySubject[subject] != true else { return }
        studyGuideOpenedBySubject[subject] = true
    }

    func clearStudyGuideOpened(for subject: String) {
        guard Self.trackedQuizSubjects.contains(subject) else {
            return
        }

        guard studyGuideOpenedBySubject[subject] == true else { return }
        studyGuideOpenedBySubject[subject] = false
    }

    func setStudyGuideOpenedBySubject(_ values: [String: Bool]) {
        studyGuideOpenedBySubject = Self.normalizedStudyGuideOpenedBySubject(values)
    }

    func resetStudyGuideOpenedBySubject() {
        studyGuideOpenedBySubject = Self.defaultStudyGuideOpenedBySubject()
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
