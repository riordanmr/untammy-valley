import SpriteKit
import UIKit

final class QuizDialogNode: SKNode {
    private let backdropNode = SKShapeNode()
    private let panelNode = SKShapeNode()
    private let titleLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
    private let indexLabel = SKLabelNode(fontNamed: "AvenirNext-Medium")
    private let questionLabel = SKLabelNode(fontNamed: "AvenirNext-DemiBold")
    private let prevButtonNode = SKShapeNode()
    private let nextButtonNode = SKShapeNode()
    private let submitButtonNode = SKShapeNode()
    private let closeButtonNode = SKShapeNode()
    private let resultsContainerNode = SKNode()

    private var answerButtonNodes: [SKShapeNode] = []
    private var answerLabelNodes: [SKLabelNode] = []
    private var panelSize = CGSize.zero
    private var isIntroPaneVisible = false
    private let answerButtonHeight: CGFloat = 48

    private(set) var isResultsVisible = false
    private(set) var sessionState: QuizSessionState?

    var onClose: (() -> Void)?
    var onSubmit: ((QuizSessionState, Int) -> QuizSubjectStats)?

    var isVisible: Bool {
        !panelNode.isHidden
    }

    init(sceneSize: CGSize) {
        super.init()
        buildUI(sceneSize: sceneSize)
        setVisible(false)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func updateLayout(sceneSize: CGSize) {
        let existingSession = sessionState
        let existingResultsVisible = isResultsVisible
        let existingIntroPaneVisible = isIntroPaneVisible
        removeAllChildren()
        answerButtonNodes.removeAll()
        answerLabelNodes.removeAll()
        buildUI(sceneSize: sceneSize)
        sessionState = existingSession
        isResultsVisible = existingResultsVisible
        isIntroPaneVisible = existingIntroPaneVisible

        if let sessionState {
            if isResultsVisible {
                showResultsPane(using: sessionState, updateStats: false)
            } else {
                updateQuestionPane()
            }
        }
    }

    func setVisible(_ visible: Bool) {
        backdropNode.isHidden = !visible
        panelNode.isHidden = !visible
        if !visible {
            isResultsVisible = false
            isIntroPaneVisible = false
            sessionState = nil
            resultsContainerNode.removeAllChildren()
            resultsContainerNode.isHidden = true
        }
    }

    func startQuiz(session: QuizSessionState) {
        sessionState = session
        isResultsVisible = false
        isIntroPaneVisible = true
        setVisible(true)
        updateQuestionPane()
    }

    @discardableResult
    func handleTap(hudNodes: [SKNode]) -> Bool {
        guard isVisible else { return false }
        let names = hudNodes.compactMap { resolvedName(from: $0) }

        if names.contains("quizClose") {
            setVisible(false)
            onClose?()
            return true
        }

        if isResultsVisible {
            return true
        }

        guard var session = sessionState else { return true }

        if names.contains("quizPrev") {
            if isIntroPaneVisible {
                return true
            }
            if session.currentQuestionIndex > 0 {
                session.currentQuestionIndex -= 1
            } else {
                isIntroPaneVisible = true
            }
            sessionState = session
            updateQuestionPane()
            return true
        }

        if names.contains("quizNext") {
            if isIntroPaneVisible {
                isIntroPaneVisible = false
                session.currentQuestionIndex = 0
            } else if session.currentQuestionIndex < session.questions.count - 1 {
                session.currentQuestionIndex += 1
            }
            sessionState = session
            updateQuestionPane()
            return true
        }

        if names.contains("quizSubmit"), session.allAnswered {
            sessionState = session
            showResultsPane(using: session, updateStats: true)
            return true
        }

        for optionIndex in 0..<4 {
            if names.contains("quizAnswer\(optionIndex)") {
                session.selectedOptionIndexes[session.currentQuestionIndex] = optionIndex
                sessionState = session
                updateQuestionPane()
                return true
            }
        }

        return true
    }

    private func buildUI(sceneSize: CGSize) {
        backdropNode.path = CGPath(
            rect: CGRect(x: -sceneSize.width / 2, y: -sceneSize.height / 2, width: sceneSize.width, height: sceneSize.height),
            transform: nil
        )
        backdropNode.fillColor = UIColor.black.withAlphaComponent(0.45)
        backdropNode.strokeColor = .clear
        backdropNode.name = "quizBackdrop"
        backdropNode.zPosition = 0
        addChild(backdropNode)

        panelSize = CGSize(width: min(sceneSize.width - 80, 880), height: min(sceneSize.height - 50, 840))
        panelNode.path = CGPath(
            roundedRect: CGRect(x: -panelSize.width / 2, y: -panelSize.height / 2, width: panelSize.width, height: panelSize.height),
            cornerWidth: 14,
            cornerHeight: 14,
            transform: nil
        )
        panelNode.fillColor = UIColor(white: 0.14, alpha: 0.97)
        panelNode.strokeColor = .white
        panelNode.lineWidth = 2
        panelNode.name = "quizPanel"
        panelNode.zPosition = 1
        addChild(panelNode)

        titleLabel.text = "Quiz"
        titleLabel.fontSize = 28
        titleLabel.fontColor = .white
        titleLabel.horizontalAlignmentMode = .center
        titleLabel.verticalAlignmentMode = .center
        titleLabel.position = CGPoint(x: 0, y: panelSize.height / 2 - 36)
        titleLabel.zPosition = 2
        titleLabel.isHidden = true
        panelNode.addChild(titleLabel)

        indexLabel.text = ""
        indexLabel.fontSize = 18
        indexLabel.fontColor = UIColor.white.withAlphaComponent(0.88)
        indexLabel.horizontalAlignmentMode = .right
        indexLabel.verticalAlignmentMode = .center
        indexLabel.position = CGPoint(x: -258, y: -panelSize.height / 2 + 34)
        indexLabel.zPosition = 2
        panelNode.addChild(indexLabel)

        questionLabel.text = ""
        questionLabel.fontSize = 17
        questionLabel.fontColor = .white
        questionLabel.horizontalAlignmentMode = .center
        questionLabel.verticalAlignmentMode = .center
        let layout = questionAndAnswerLayout()
        questionLabel.position = CGPoint(x: 0, y: layout.questionY)
        questionLabel.zPosition = 2
        panelNode.addChild(questionLabel)

        let answerYPositions = layout.answerYPositions
        for index in 0..<4 {
            let buttonName = "quizAnswer\(index)"
            let button = SKShapeNode(rectOf: CGSize(width: panelSize.width - 120, height: answerButtonHeight), cornerRadius: 8)
            button.name = buttonName
            button.fillColor = UIColor.darkGray.withAlphaComponent(0.85)
            button.strokeColor = .white
            button.lineWidth = 1.2
            button.position = CGPoint(x: 0, y: answerYPositions[index])
            button.zPosition = 2
            panelNode.addChild(button)
            answerButtonNodes.append(button)

            let label = SKLabelNode(fontNamed: "AvenirNext-Medium")
            label.name = buttonName
            label.text = ""
            label.fontSize = 15
            label.fontColor = .white
            label.horizontalAlignmentMode = .center
            label.verticalAlignmentMode = .center
            label.position = .zero
            label.zPosition = 3
            button.addChild(label)
            answerLabelNodes.append(label)
        }

        configureNavButton(
            prevButtonNode,
            name: "quizPrev",
            text: "Prev",
            size: CGSize(width: 120, height: 44),
            position: CGPoint(x: -190, y: -panelSize.height / 2 + 34)
        )

        configureNavButton(
            nextButtonNode,
            name: "quizNext",
            text: "Next",
            size: CGSize(width: 120, height: 44),
            position: CGPoint(x: -52, y: -panelSize.height / 2 + 34)
        )

        configureNavButton(
            submitButtonNode,
            name: "quizSubmit",
            text: "Submit",
            size: CGSize(width: 150, height: 44),
            position: CGPoint(x: 118, y: -panelSize.height / 2 + 34)
        )

        closeButtonNode.path = CGPath(roundedRect: CGRect(x: -60, y: -22, width: 120, height: 44), cornerWidth: 8, cornerHeight: 8, transform: nil)
        closeButtonNode.name = "quizClose"
        closeButtonNode.fillColor = UIColor.darkGray.withAlphaComponent(0.9)
        closeButtonNode.strokeColor = .white
        closeButtonNode.lineWidth = 1.2
        closeButtonNode.position = CGPoint(x: panelSize.width / 2 - 96, y: -panelSize.height / 2 + 34)
        closeButtonNode.zPosition = 2
        panelNode.addChild(closeButtonNode)

        let closeLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
        closeLabel.name = "quizClose"
        closeLabel.text = "Close"
        closeLabel.fontSize = 20
        closeLabel.fontColor = .white
        closeLabel.horizontalAlignmentMode = .center
        closeLabel.verticalAlignmentMode = .center
        closeLabel.position = .zero
        closeLabel.zPosition = 3
        closeButtonNode.addChild(closeLabel)

        resultsContainerNode.zPosition = 2
        resultsContainerNode.isHidden = true
        panelNode.addChild(resultsContainerNode)
    }

    private func configureNavButton(
        _ button: SKShapeNode,
        name: String,
        text: String,
        size: CGSize,
        position: CGPoint
    ) {
        button.path = CGPath(roundedRect: CGRect(x: -size.width / 2, y: -size.height / 2, width: size.width, height: size.height), cornerWidth: 8, cornerHeight: 8, transform: nil)
        button.name = name
        button.position = position
        button.zPosition = 2
        panelNode.addChild(button)

        let label = SKLabelNode(fontNamed: "AvenirNext-Bold")
        label.name = name
        label.text = text
        label.fontSize = 20
        label.fontColor = .white
        label.horizontalAlignmentMode = .center
        label.verticalAlignmentMode = .center
        label.position = .zero
        label.zPosition = 3
        button.addChild(label)
    }

    private func setButton(
        _ button: SKShapeNode,
        enabled: Bool,
        activeColor: UIColor = UIColor.systemBlue.withAlphaComponent(0.88)
    ) {
        button.fillColor = enabled
            ? activeColor
            : UIColor.darkGray.withAlphaComponent(0.45)
        button.strokeColor = enabled ? .white : UIColor.white.withAlphaComponent(0.35)
        button.alpha = enabled ? 1.0 : 0.72
    }

    private func updateQuestionPane() {
        guard var session = sessionState else { return }
        if isIntroPaneVisible {
            indexLabel.isHidden = true
            questionLabel.isHidden = false
            questionLabel.fontSize = 30
            questionLabel.text = "\(session.subject) Quiz"
            questionLabel.position = CGPoint(x: 0, y: questionAndAnswerLayout().questionY)

            answerButtonNodes.forEach { $0.isHidden = true }
            prevButtonNode.isHidden = false
            nextButtonNode.isHidden = false
            submitButtonNode.isHidden = true
            setButton(prevButtonNode, enabled: false)
            setButton(nextButtonNode, enabled: true)
            resultsContainerNode.removeAllChildren()
            resultsContainerNode.isHidden = true
            sessionState = session
            return
        }

        let questionIndex = max(0, min(session.currentQuestionIndex, session.questions.count - 1))
        session.currentQuestionIndex = questionIndex
        sessionState = session

        let question = session.questions[questionIndex]
        indexLabel.isHidden = false
        indexLabel.text = "\(questionIndex + 1)/\(session.questions.count)"
        questionLabel.fontSize = 17
        let layout = questionAndAnswerLayout()
        questionLabel.position = CGPoint(x: 0, y: layout.questionY)
        questionLabel.text = wrappedText(question.prompt, maxCharacters: 64)

        let answerYPositions = layout.answerYPositions

        for optionIndex in 0..<4 {
            let optionText = optionIndex < question.options.count ? question.options[optionIndex] : ""
            answerLabelNodes[optionIndex].text = wrappedText(optionText, maxCharacters: 72)
            answerButtonNodes[optionIndex].position.y = answerYPositions[optionIndex]
            let isSelected = session.selectedOptionIndexes[questionIndex] == optionIndex
            setButton(
                answerButtonNodes[optionIndex],
                enabled: true,
                activeColor: isSelected
                    ? UIColor.systemBlue.withAlphaComponent(0.95)
                    : UIColor.darkGray.withAlphaComponent(0.88)
            )
        }

        setButton(prevButtonNode, enabled: questionIndex > 0)
        setButton(nextButtonNode, enabled: questionIndex < session.questions.count - 1)
        setButton(submitButtonNode, enabled: session.allAnswered, activeColor: UIColor.systemGreen.withAlphaComponent(0.88))

        resultsContainerNode.removeAllChildren()
        resultsContainerNode.isHidden = true
        questionLabel.isHidden = false
        indexLabel.isHidden = false
        answerButtonNodes.forEach { $0.isHidden = false }
        prevButtonNode.isHidden = false
        nextButtonNode.isHidden = false
        submitButtonNode.isHidden = false
    }

    private func showResultsPane(using session: QuizSessionState, updateStats: Bool) {
        isResultsVisible = true

        let correctCount = session.correctAnswerCount()
        let totals: QuizSubjectStats
        if updateStats, let onSubmit {
            totals = onSubmit(session, correctCount)
        } else {
            totals = QuizSubjectStats(answered: session.questions.count, correct: correctCount)
        }

        let percent = totals.answered > 0 ? (Double(totals.correct) / Double(totals.answered)) * 100.0 : 0

        indexLabel.isHidden = true
        questionLabel.isHidden = true
        answerButtonNodes.forEach { $0.isHidden = true }
        prevButtonNode.isHidden = true
        nextButtonNode.isHidden = true
        submitButtonNode.isHidden = true
        resultsContainerNode.isHidden = false
        resultsContainerNode.removeAllChildren()

        var y: CGFloat = panelSize.height / 2 - 110
        let lineSpacing: CGFloat = 32
        for (index, question) in session.questions.enumerated() {
            let selectedOption = session.selectedOptionIndexes[index]
            let isCorrect = selectedOption == question.correctOptionIndex
            let marker = isCorrect ? "✅" : "❌"

            let questionLabel = SKLabelNode(fontNamed: "AvenirNext-DemiBold")
            questionLabel.text = "\(marker) \(wrappedText(question.prompt, maxCharacters: 78))"
            questionLabel.fontSize = 15
            questionLabel.fontColor = isCorrect ? UIColor.systemGreen : UIColor.systemRed
            questionLabel.horizontalAlignmentMode = .left
            questionLabel.verticalAlignmentMode = .center
            questionLabel.position = CGPoint(x: -panelSize.width / 2 + 48, y: y)
            questionLabel.zPosition = 3
            resultsContainerNode.addChild(questionLabel)

            y -= lineSpacing
        }

        let totalsLine = SKLabelNode(fontNamed: "AvenirNext-Bold")
        totalsLine.text = "\(session.subject): \(totals.correct) correct, \(totals.answered) answered (\(Int(round(percent)))%)"
        totalsLine.fontSize = 19
        totalsLine.fontColor = percent >= 80 ? UIColor.systemGreen : UIColor.systemRed
        totalsLine.horizontalAlignmentMode = .left
        totalsLine.verticalAlignmentMode = .center
        totalsLine.position = CGPoint(x: -panelSize.width / 2 + 48, y: y - 12)
        totalsLine.zPosition = 3
        resultsContainerNode.addChild(totalsLine)
    }

    private func wrappedText(_ text: String, maxCharacters: Int) -> String {
        guard maxCharacters > 0 else { return text }
        let words = text.split(separator: " ")
        guard !words.isEmpty else { return "" }

        var lines: [String] = []
        var currentLine = ""

        for wordPart in words {
            let word = String(wordPart)
            if currentLine.isEmpty {
                currentLine = word
                continue
            }

            let candidate = currentLine + " " + word
            if candidate.count <= maxCharacters {
                currentLine = candidate
            } else {
                lines.append(currentLine)
                currentLine = word
            }
        }

        if !currentLine.isEmpty {
            lines.append(currentLine)
        }

        // Keep an explicit space before each forced line break so text still has
        // word separation if line breaks are visually collapsed by SKLabelNode.
        return lines.joined(separator: " \n")
    }

    private func questionAndAnswerLayout() -> (questionY: CGFloat, answerYPositions: [CGFloat]) {
        let top = panelSize.height / 2
        let rowSpacing: CGFloat = 52
        let questionToAnswerGap: CGFloat = 52
        let minimumGapToButtons: CGFloat = 12
        let buttonCenterY: CGFloat = -panelSize.height / 2 + 34
        let buttonTopY = buttonCenterY + 22
        let answerHalfHeight = answerButtonHeight / 2

        var questionY = top - 42
        let preferredFirstAnswerY = top - 150
        let maxFirstAnswerFromQuestion = questionY - questionToAnswerGap
        var firstAnswerY = min(preferredFirstAnswerY, maxFirstAnswerFromQuestion)

        let requiredLastAnswerY = buttonTopY + minimumGapToButtons + answerHalfHeight
        let requiredFirstAnswerY = requiredLastAnswerY + (3 * rowSpacing)
        if firstAnswerY < requiredFirstAnswerY {
            firstAnswerY = requiredFirstAnswerY
            questionY = min(top - 24, max(questionY, firstAnswerY + questionToAnswerGap))
        }

        let answerYPositions = (0..<4).map { rowIndex in
            firstAnswerY - (CGFloat(rowIndex) * rowSpacing)
        }

        return (questionY, answerYPositions)
    }

    private func resolvedName(from node: SKNode) -> String? {
        if let name = node.name {
            return name
        }
        return node.parent?.name
    }
}
