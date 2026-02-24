import Foundation

enum QuizStatusFormatter {
    static let defaultSubjects: [String] = [
        ClassroomSubject.history.quizSubjectName,
        ClassroomSubject.english.quizSubjectName,
        ClassroomSubject.mathematics.quizSubjectName,
        ClassroomSubject.science.quizSubjectName
    ]

    static func makeStatusLines(
        subjects: [String] = defaultSubjects,
        statsProvider: (String) -> QuizSubjectStats
    ) -> [String] {
        var lines: [String] = ["Quiz totals:"]
        for subject in subjects {
            let totals = statsProvider(subject)
            let percent = totals.answered > 0
                ? Int(round((Double(totals.correct) / Double(totals.answered)) * 100.0))
                : 0
            lines.append("Quiz \(subject): \(totals.correct)/\(totals.answered) (\(percent)%)")
        }
        return lines
    }
}
