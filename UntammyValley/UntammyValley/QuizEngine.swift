import Foundation

enum QuizEngine {
    static func makeSession(
        subject: String,
        from allQuestions: [QuizQuestion],
        questionCount: Int = 5
    ) -> QuizSessionState? {
        guard questionCount > 0 else { return nil }
        let matchingQuestions = allQuestions.filter { $0.subject == subject }
        guard matchingQuestions.count >= questionCount else { return nil }

        let selectedQuestions = Array(matchingQuestions.shuffled().prefix(questionCount)).shuffled()
        let sessionQuestions = selectedQuestions.map { sourceQuestion in
            let shuffledIndexedOptions = Array(sourceQuestion.options.enumerated()).shuffled()
            let shuffledOptions = shuffledIndexedOptions.map { $0.element }
            let correctIndex = shuffledIndexedOptions.firstIndex { $0.offset == 0 } ?? 0
            return QuizSessionQuestion(
                prompt: sourceQuestion.question,
                options: shuffledOptions,
                correctOptionIndex: correctIndex
            )
        }

        return QuizSessionState(
            subject: subject,
            questions: sessionQuestions,
            selectedOptionIndexes: Array(repeating: nil, count: sessionQuestions.count),
            currentQuestionIndex: 0
        )
    }
}
