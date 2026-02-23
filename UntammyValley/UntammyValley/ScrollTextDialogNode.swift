import SpriteKit
import UIKit

final class ScrollTextDialogNode: SKNode {
    private let backdropNode = SKShapeNode()
    private let panelNode = SKShapeNode()
    private let titleLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
    private let scrollCropNode = SKCropNode()
    private let scrollContentNode = SKNode()
    private let scrollTrackNode = SKShapeNode()
    private let scrollThumbNode = SKShapeNode()
    private let closeButtonNode = SKShapeNode()

    private var isDraggingScroll = false
    private var lastDragY: CGFloat = 0
    private var didDragScroll = false

    private var scrollViewportWidth: CGFloat = 0
    private var scrollViewportHeight: CGFloat = 0
    private var scrollContentHeight: CGFloat = 0
    private var scrollOffset: CGFloat = 0

    var onClose: (() -> Void)?

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
        removeAllChildren()
        buildUI(sceneSize: sceneSize)
        updateScrollOffset(scrollOffset)
    }

    func configure(
        title: String,
        lines: [String],
        paragraphSpacing: CGFloat,
        closeButtonTitle: String = "Close"
    ) {
        titleLabel.text = title
        if let closeLabel = closeButtonNode.childNode(withName: "scrollTextCloseItem") as? SKLabelNode {
            closeLabel.text = closeButtonTitle
        }
        renderLines(lines, paragraphSpacing: paragraphSpacing)
    }

    func setVisible(_ visible: Bool) {
        backdropNode.isHidden = !visible
        panelNode.isHidden = !visible
        if !visible {
            isDraggingScroll = false
            didDragScroll = false
        }
    }

    func beginDrag(at hudLocation: CGPoint) {
        guard isVisible else { return }
        guard isInScrollViewport(hudLocation) else { return }
        isDraggingScroll = true
        lastDragY = hudLocation.y
        didDragScroll = false
    }

    @discardableResult
    func drag(to hudLocation: CGPoint) -> Bool {
        guard isVisible, isDraggingScroll else { return false }
        let deltaY = hudLocation.y - lastDragY
        lastDragY = hudLocation.y
        if abs(deltaY) > 0.5 {
            didDragScroll = true
        }
        updateScrollOffset(scrollOffset + deltaY)
        return true
    }

    @discardableResult
    func endDrag() -> Bool {
        guard isDraggingScroll else { return false }
        isDraggingScroll = false
        let dragged = didDragScroll
        didDragScroll = false
        return dragged
    }

    @discardableResult
    func handleTap(hudNodes: [SKNode]) -> Bool {
        guard isVisible else { return false }
        let names = hudNodes.compactMap { resolvedName(from: $0) }
        if names.contains("scrollTextCloseItem") {
            setVisible(false)
            onClose?()
            return true
        }
        return true
    }

    private func buildUI(sceneSize: CGSize) {
        backdropNode.path = CGPath(rect: CGRect(x: -sceneSize.width / 2, y: -sceneSize.height / 2, width: sceneSize.width, height: sceneSize.height), transform: nil)
        backdropNode.fillColor = UIColor.black.withAlphaComponent(0.45)
        backdropNode.strokeColor = .clear
        backdropNode.name = "scrollTextBackdrop"
        backdropNode.zPosition = 0
        addChild(backdropNode)

        let panelSize = CGSize(width: min(sceneSize.width - 72, 940), height: min(sceneSize.height * 0.93, 980))
        panelNode.path = CGPath(roundedRect: CGRect(x: -panelSize.width / 2, y: -panelSize.height / 2, width: panelSize.width, height: panelSize.height), cornerWidth: 14, cornerHeight: 14, transform: nil)
        panelNode.fillColor = UIColor(white: 0.10, alpha: 0.97)
        panelNode.strokeColor = .white
        panelNode.lineWidth = 2
        panelNode.name = "scrollTextPanel"
        panelNode.zPosition = 1
        addChild(panelNode)

        titleLabel.text = ""
        titleLabel.fontSize = 32
        titleLabel.fontColor = .white
        titleLabel.horizontalAlignmentMode = .center
        titleLabel.verticalAlignmentMode = .center
        titleLabel.position = CGPoint(x: 0, y: panelSize.height / 2 - 30)
        titleLabel.zPosition = 2
        panelNode.addChild(titleLabel)

        scrollViewportWidth = panelSize.width - 56
        scrollViewportHeight = panelSize.height - 130

        scrollCropNode.zPosition = 2
        scrollCropNode.position = CGPoint(x: 0, y: 10)
        panelNode.addChild(scrollCropNode)

        let scrollMask = SKSpriteNode(color: .white, size: CGSize(width: scrollViewportWidth, height: scrollViewportHeight))
        scrollMask.position = .zero
        scrollCropNode.maskNode = scrollMask
        scrollCropNode.addChild(scrollContentNode)

        scrollTrackNode.path = CGPath(
            roundedRect: CGRect(x: -3, y: -scrollViewportHeight / 2, width: 6, height: scrollViewportHeight),
            cornerWidth: 3,
            cornerHeight: 3,
            transform: nil
        )
        scrollTrackNode.fillColor = UIColor.white.withAlphaComponent(0.2)
        scrollTrackNode.strokeColor = UIColor.white.withAlphaComponent(0.4)
        scrollTrackNode.lineWidth = 1
        scrollTrackNode.position = CGPoint(x: scrollViewportWidth / 2 + 8 + scrollCropNode.position.x, y: scrollCropNode.position.y)
        scrollTrackNode.zPosition = 2
        panelNode.addChild(scrollTrackNode)

        scrollThumbNode.fillColor = UIColor.white.withAlphaComponent(0.85)
        scrollThumbNode.strokeColor = .white
        scrollThumbNode.lineWidth = 0.5
        scrollThumbNode.zPosition = 3
        panelNode.addChild(scrollThumbNode)

        closeButtonNode.path = CGPath(roundedRect: CGRect(x: -75, y: -22, width: 150, height: 44), cornerWidth: 8, cornerHeight: 8, transform: nil)
        closeButtonNode.name = "scrollTextCloseItem"
        closeButtonNode.fillColor = UIColor.systemBlue.withAlphaComponent(0.9)
        closeButtonNode.strokeColor = .white
        closeButtonNode.lineWidth = 1.5
        closeButtonNode.position = CGPoint(x: 0, y: -panelSize.height / 2 + 30)
        closeButtonNode.zPosition = 2
        panelNode.addChild(closeButtonNode)

        let closeLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
        closeLabel.name = "scrollTextCloseItem"
        closeLabel.text = "Close"
        closeLabel.fontSize = 22
        closeLabel.fontColor = .white
        closeLabel.horizontalAlignmentMode = .center
        closeLabel.verticalAlignmentMode = .center
        closeLabel.position = .zero
        closeLabel.zPosition = 3
        closeButtonNode.addChild(closeLabel)

        updateScrollOffset(scrollOffset)
    }

    private func renderLines(_ lines: [String], paragraphSpacing: CGFloat) {
        scrollContentNode.removeAllChildren()

        let fontName = "AvenirNext-Medium"
        let fontSize: CGFloat = 20
        let lineHeight: CGFloat = 24
        let extraSpacing = max(0, paragraphSpacing) * lineHeight
        let topPadding: CGFloat = 8
        let bottomPadding: CGFloat = 8
        let maxCharsPerLine = max(40, Int(scrollViewportWidth / 10))
        let textX = -scrollViewportWidth / 2 + 8

        let sourceLines = lines.isEmpty ? ["No text available."] : lines
        var renderedLines: [(text: String, isSpacer: Bool)] = []
        for (index, sourceLine) in sourceLines.enumerated() {
            let wrapped = wrappedLines(sourceLine, maxCharacters: maxCharsPerLine)
            renderedLines.append(contentsOf: wrapped.map { (text: $0, isSpacer: false) })
            if index < sourceLines.count - 1 {
                renderedLines.append((text: "", isSpacer: true))
            }
        }

        let textHeight = renderedLines.reduce(CGFloat(0)) { partialResult, item in
            partialResult + (item.isSpacer ? extraSpacing : lineHeight)
        }
        let contentHeight = topPadding + bottomPadding + textHeight
        scrollContentHeight = max(contentHeight, scrollViewportHeight)

        let topY = scrollContentHeight / 2 - topPadding
        var currentY = topY
        for renderedLine in renderedLines {
            if renderedLine.isSpacer {
                currentY -= extraSpacing
                continue
            }

            let lineNode = SKLabelNode(fontNamed: fontName)
            lineNode.text = renderedLine.text
            lineNode.fontSize = fontSize
            lineNode.fontColor = .white
            lineNode.horizontalAlignmentMode = .left
            lineNode.verticalAlignmentMode = .top
            lineNode.position = CGPoint(x: textX, y: currentY)
            lineNode.zPosition = 2
            scrollContentNode.addChild(lineNode)

            currentY -= lineHeight
        }

        scrollOffset = 0
        updateScrollOffset(0)
    }

    private func wrappedLines(_ text: String, maxCharacters: Int) -> [String] {
        guard maxCharacters > 0 else { return [text] }
        let words = text.split(separator: " ")
        guard !words.isEmpty else { return [""] }

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

        return lines
    }

    private func updateScrollOffset(_ offset: CGFloat) {
        let maxOffset = max(0, scrollContentHeight - scrollViewportHeight)
        scrollOffset = min(max(0, offset), maxOffset)
        scrollContentNode.position = CGPoint(
            x: 0,
            y: (scrollViewportHeight - scrollContentHeight) / 2 + scrollOffset
        )
        updateScrollIndicator()
    }

    private func updateScrollIndicator() {
        let maxOffset = max(0, scrollContentHeight - scrollViewportHeight)
        guard maxOffset > 0 else {
            scrollTrackNode.isHidden = true
            scrollThumbNode.isHidden = true
            return
        }

        scrollTrackNode.isHidden = false
        scrollThumbNode.isHidden = false

        let visibleRatio = scrollViewportHeight / scrollContentHeight
        let thumbHeight = max(30, scrollViewportHeight * visibleRatio)
        scrollThumbNode.path = CGPath(
            roundedRect: CGRect(x: -3, y: -thumbHeight / 2, width: 6, height: thumbHeight),
            cornerWidth: 3,
            cornerHeight: 3,
            transform: nil
        )

        let trackTopY = scrollTrackNode.position.y + scrollViewportHeight / 2
        let travelRange = scrollViewportHeight - thumbHeight
        let progress = scrollOffset / maxOffset
        let thumbCenterY = trackTopY - thumbHeight / 2 - (travelRange * progress)
        scrollThumbNode.position = CGPoint(x: scrollTrackNode.position.x, y: thumbCenterY)
    }

    private func resolvedName(from node: SKNode) -> String? {
        if let name = node.name {
            return name
        }
        return node.parent?.name
    }

    private func isInScrollViewport(_ hudLocation: CGPoint) -> Bool {
        guard let parent else { return false }

        let localInPanel = panelNode.convert(hudLocation, from: parent)
        let viewportRect = CGRect(
            x: scrollCropNode.position.x - scrollViewportWidth / 2,
            y: scrollCropNode.position.y - scrollViewportHeight / 2,
            width: scrollViewportWidth,
            height: scrollViewportHeight
        )
        return viewportRect.contains(localInPanel)
    }
}
