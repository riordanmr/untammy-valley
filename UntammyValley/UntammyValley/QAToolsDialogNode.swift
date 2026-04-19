//
//  QAToolsDialogNode.swift
//  UntammyValley
//

import SpriteKit
import UIKit

final class QAToolsDialogNode: SKNode {
    private struct ActionRow {
        let id: String
        let description: String
        let buttonTitle: String
    }

    private let backdropNode = SKShapeNode()
    private let panelNode = SKShapeNode()
    private let scrollCropNode = SKCropNode()
    private let scrollContentNode = SKNode()
    private let scrollTrackNode = SKShapeNode()
    private let scrollThumbNode = SKShapeNode()
    private let feedbackLabel = SKLabelNode(fontNamed: "AvenirNext-Medium")

    private var scrollOffset: CGFloat = 0
    private var scrollViewportHeight: CGFloat = 0
    private var scrollContentHeight: CGFloat = 0
    private var scrollContentBaseY: CGFloat = 0
    private var viewportRect: CGRect = .zero
    private var isDraggingScroll = false
    private var didDragScroll = false
    private var lastDragY: CGFloat = 0

    private let actionRows: [ActionRow] = [
        ActionRow(id: "qaAddCoins", description: "Add 600 coins", buttonTitle: "Run"),
        ActionRow(id: "qaMoveSnowtankerObjects", description: "Move all snowtanker objects to vehicle assembly area", buttonTitle: "Run")
    ]

    var onClose: (() -> Void)?
    var onAddCoinsTapped: (() -> Void)?
    var onMoveSnowtankerObjectsTapped: (() -> Void)?

    var isVisible: Bool {
        !backdropNode.isHidden
    }

    init(sceneSize: CGSize) {
        super.init()
        isUserInteractionEnabled = false
        buildUI(sceneSize: sceneSize)
        setVisible(false)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func updateLayout(sceneSize: CGSize) {
        removeAllChildren()
        buildUI(sceneSize: sceneSize)
    }

    func setVisible(_ visible: Bool) {
        backdropNode.isHidden = !visible
        panelNode.isHidden = !visible
        if !visible {
            isDraggingScroll = false
            didDragScroll = false
        }
    }

    func setFeedback(_ message: String) {
        feedbackLabel.text = message
        feedbackLabel.isHidden = message.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    func beginDrag(at hudLocation: CGPoint) {
        guard isVisible else { return }
        guard scrollCropNode.contains(hudLocation) else { return }

        isDraggingScroll = true
        didDragScroll = false
        lastDragY = hudLocation.y
    }

    @discardableResult
    func drag(to hudLocation: CGPoint) -> Bool {
        guard isVisible else { return false }
        guard isDraggingScroll else { return false }

        let deltaY = hudLocation.y - lastDragY
        lastDragY = hudLocation.y
        if abs(deltaY) > 0.5 {
            didDragScroll = true
        }
        setScrollOffset(scrollOffset + deltaY)
        return true
    }

    @discardableResult
    func endDrag() -> Bool {
        guard isDraggingScroll else { return false }

        isDraggingScroll = false
        let wasDragging = didDragScroll
        didDragScroll = false
        return wasDragging
    }

    @discardableResult
    func handleTap(hudNodes: [SKNode]) -> Bool {
        guard isVisible else { return false }

        let names = hudNodes.compactMap { resolvedName(from: $0) }

        if names.contains("qaToolsDoneItem") {
            setVisible(false)
            onClose?()
            return true
        }

        if names.contains("qaAction:qaAddCoins") {
            onAddCoinsTapped?()
            return true
        }

        if names.contains("qaAction:qaMoveSnowtankerObjects") {
            onMoveSnowtankerObjectsTapped?()
            return true
        }

        return true
    }

    private func setScrollOffset(_ offset: CGFloat) {
        let maxOffset = max(0, scrollContentHeight - scrollViewportHeight)
        scrollOffset = min(max(0, offset), maxOffset)

        scrollContentNode.position = CGPoint(x: 0, y: scrollContentBaseY + scrollOffset)

        let canScroll = maxOffset > 0.5
        scrollTrackNode.isHidden = !canScroll
        scrollThumbNode.isHidden = !canScroll

        guard canScroll else { return }

        let trackHeight = viewportRect.height
        let visibleRatio = min(1, scrollViewportHeight / max(1, scrollContentHeight))
        let thumbHeight = max(20, trackHeight * visibleRatio)
        let thumbWidth: CGFloat = 6

        scrollThumbNode.path = CGPath(
            roundedRect: CGRect(x: -thumbWidth / 2, y: -thumbHeight / 2, width: thumbWidth, height: thumbHeight),
            cornerWidth: thumbWidth / 2,
            cornerHeight: thumbWidth / 2,
            transform: nil
        )

        let progress = scrollOffset / maxOffset
        let travel = trackHeight - thumbHeight
        let thumbCenterY = viewportRect.maxY - (thumbHeight / 2) - (progress * travel)
        scrollThumbNode.position = CGPoint(x: viewportRect.maxX - 6, y: thumbCenterY)
    }

    private func buildUI(sceneSize: CGSize) {
        let panelWidth = min(max(sceneSize.width - 120, 640), 900)
        let panelHeight = min(max(sceneSize.height * 0.74, 360), 540)
        let bodyX = -panelWidth / 2 + 24
        let bodyY = -panelHeight / 2 + 12
        let bodyWidth = panelWidth - 48
        let bodyHeight = panelHeight - 24

        backdropNode.path = CGPath(
            rect: CGRect(
                x: -sceneSize.width / 2,
                y: -sceneSize.height / 2,
                width: sceneSize.width,
                height: sceneSize.height
            ),
            transform: nil
        )
        backdropNode.fillColor = UIColor.black.withAlphaComponent(0.5)
        backdropNode.strokeColor = .clear
        backdropNode.name = "qaToolsBackdrop"
        backdropNode.zPosition = 760
        addChild(backdropNode)

        panelNode.path = CGPath(
            roundedRect: CGRect(x: -panelWidth / 2, y: -panelHeight / 2, width: panelWidth, height: panelHeight),
            cornerWidth: 12,
            cornerHeight: 12,
            transform: nil
        )
        panelNode.fillColor = UIColor(white: 0.12, alpha: 0.97)
        panelNode.strokeColor = .white
        panelNode.lineWidth = 2
        panelNode.zPosition = 761
        addChild(panelNode)

        let bodyNode = SKShapeNode(
            rect: CGRect(x: bodyX, y: bodyY, width: bodyWidth, height: bodyHeight),
            cornerRadius: 8
        )
        bodyNode.fillColor = UIColor(white: 0.10, alpha: 1.0)
        bodyNode.strokeColor = UIColor.white.withAlphaComponent(0.25)
        bodyNode.lineWidth = 1
        bodyNode.zPosition = 762
        panelNode.addChild(bodyNode)

        let titleLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
        titleLabel.text = "QA Tools"
        titleLabel.fontSize = 28
        titleLabel.fontColor = .white
        titleLabel.horizontalAlignmentMode = .left
        titleLabel.verticalAlignmentMode = .center
        titleLabel.position = CGPoint(x: bodyX + 14, y: bodyY + bodyHeight - 22)
        titleLabel.zPosition = 763
        panelNode.addChild(titleLabel)

        let viewportInsetX: CGFloat = 10
        let viewportTopInset: CGFloat = 46
        let viewportBottomInset: CGFloat = 58
        viewportRect = CGRect(
            x: bodyX + viewportInsetX,
            y: bodyY + viewportBottomInset,
            width: bodyWidth - (viewportInsetX * 2),
            height: bodyHeight - viewportTopInset - viewportBottomInset
        )

        scrollContentNode.removeAllChildren()
        scrollViewportHeight = viewportRect.height

        scrollCropNode.zPosition = 763
        scrollCropNode.position = .zero
        panelNode.addChild(scrollCropNode)

        let maskNode = SKShapeNode(rect: viewportRect)
        maskNode.fillColor = .white
        maskNode.strokeColor = .clear
        scrollCropNode.maskNode = maskNode
        scrollCropNode.addChild(scrollContentNode)

        scrollTrackNode.path = CGPath(
            roundedRect: CGRect(x: -2, y: -viewportRect.height / 2, width: 4, height: viewportRect.height),
            cornerWidth: 2,
            cornerHeight: 2,
            transform: nil
        )
        scrollTrackNode.fillColor = UIColor.white.withAlphaComponent(0.18)
        scrollTrackNode.strokeColor = .clear
        scrollTrackNode.zPosition = 764
        scrollTrackNode.position = CGPoint(x: viewportRect.maxX - 6, y: viewportRect.midY)
        panelNode.addChild(scrollTrackNode)

        scrollThumbNode.fillColor = UIColor.white.withAlphaComponent(0.82)
        scrollThumbNode.strokeColor = .clear
        scrollThumbNode.zPosition = 765
        panelNode.addChild(scrollThumbNode)

        let rowHeight: CGFloat = 52
        let topPadding: CGFloat = 8
        let bottomPadding: CGFloat = 8
        scrollContentHeight = max(
            scrollViewportHeight,
            topPadding + bottomPadding + CGFloat(actionRows.count) * rowHeight
        )
        let topY = scrollContentHeight / 2 - topPadding - rowHeight / 2
        scrollContentBaseY = viewportRect.maxY - (scrollContentHeight / 2)

        let descriptionX = viewportRect.minX + 8
        let buttonX = viewportRect.maxX - 56

        var y = topY
        for row in actionRows {
            let descriptionLabel = SKLabelNode(fontNamed: "AvenirNext-Medium")
            descriptionLabel.text = row.description
            descriptionLabel.fontSize = 18
            descriptionLabel.fontColor = .white
            descriptionLabel.horizontalAlignmentMode = .left
            descriptionLabel.verticalAlignmentMode = .center
            descriptionLabel.position = CGPoint(x: descriptionX, y: y)
            descriptionLabel.zPosition = 763
            scrollContentNode.addChild(descriptionLabel)

            let buttonName = "qaAction:\(row.id)"
            let runButton = SKShapeNode(rectOf: CGSize(width: 78, height: 32), cornerRadius: 6)
            runButton.name = buttonName
            runButton.fillColor = UIColor.systemBlue.withAlphaComponent(0.9)
            runButton.strokeColor = .white
            runButton.lineWidth = 1.5
            runButton.position = CGPoint(x: buttonX, y: y)
            runButton.zPosition = 763
            scrollContentNode.addChild(runButton)

            let runLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
            runLabel.name = buttonName
            runLabel.text = row.buttonTitle
            runLabel.fontSize = 18
            runLabel.fontColor = .white
            runLabel.horizontalAlignmentMode = .center
            runLabel.verticalAlignmentMode = .center
            runLabel.position = CGPoint(x: 0, y: -1)
            runLabel.zPosition = 764
            runButton.addChild(runLabel)

            y -= rowHeight
        }

        setScrollOffset(0)

        let doneButton = SKShapeNode(rectOf: CGSize(width: 130, height: 40), cornerRadius: 8)
        doneButton.name = "qaToolsDoneItem"
        doneButton.fillColor = UIColor.systemBlue.withAlphaComponent(0.9)
        doneButton.strokeColor = .white
        doneButton.lineWidth = 1.5
        doneButton.position = CGPoint(x: panelWidth / 2 - 90, y: -panelHeight / 2 + 34)
        doneButton.zPosition = 763
        panelNode.addChild(doneButton)

        feedbackLabel.text = ""
        feedbackLabel.fontSize = 17
        feedbackLabel.fontColor = UIColor.systemGreen
        feedbackLabel.horizontalAlignmentMode = .left
        feedbackLabel.verticalAlignmentMode = .center
        feedbackLabel.position = CGPoint(x: -panelWidth / 2 + 26, y: -panelHeight / 2 + 34)
        feedbackLabel.zPosition = 764
        feedbackLabel.isHidden = true
        panelNode.addChild(feedbackLabel)

        let doneLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
        doneLabel.name = "qaToolsDoneItem"
        doneLabel.text = "Done"
        doneLabel.fontSize = 21
        doneLabel.fontColor = .white
        doneLabel.horizontalAlignmentMode = .center
        doneLabel.verticalAlignmentMode = .center
        doneLabel.position = .zero
        doneLabel.zPosition = 764
        doneButton.addChild(doneLabel)
    }

    private func resolvedName(from node: SKNode) -> String? {
        if let name = node.name {
            return name
        }
        return node.parent?.name
    }
}
