import Foundation

struct QuizSubjectStats: Codable {
    var answered: Int
    var correct: Int
}

struct QuizSessionQuestion {
    let prompt: String
    let options: [String]
    let correctOptionIndex: Int
}

struct QuizSessionState {
    let subject: String
    let questions: [QuizSessionQuestion]
    var selectedOptionIndexes: [Int?]
    var currentQuestionIndex: Int

    var allAnswered: Bool {
        !selectedOptionIndexes.contains { $0 == nil }
    }

    func correctAnswerCount() -> Int {
        questions.enumerated().reduce(0) { partial, item in
            let (index, question) = item
            return partial + (selectedOptionIndexes[index] == question.correctOptionIndex ? 1 : 0)
        }
    }
}
