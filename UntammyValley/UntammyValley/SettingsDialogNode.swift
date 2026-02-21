//
//  SettingsDialogNode.swift
//  UntammyValley
//

import SpriteKit
import UIKit

final class SettingsDialogNode: SKNode {
    private enum Tab: String {
        case counts
    }

    private let backdropNode = SKShapeNode()
    private let panelNode = SKShapeNode()
    private let leftPaneNode = SKShapeNode()
    private let rightPaneNode = SKShapeNode()
    private let countsScrollCropNode = SKCropNode()
    private let countsScrollContentNode = SKNode()
    private let countsScrollTrackNode = SKShapeNode()
    private let countsScrollThumbNode = SKShapeNode()

    private var valueLabelsByField: [UTSettings.CountField: SKLabelNode] = [:]
    private var currentTab: Tab = .counts
    private var countsScrollOffset: CGFloat = 0
    private var countsScrollViewportHeight: CGFloat = 0
    private var countsScrollContentHeight: CGFloat = 0
    private var countsScrollContentBaseY: CGFloat = 0
    private var countsViewportRect: CGRect = .zero
    private var isDraggingCountsScroll = false
    private var didDragCountsScroll = false
    private var lastCountsDragY: CGFloat = 0

    var onClose: (() -> Void)?

    var isVisible: Bool {
        !backdropNode.isHidden
    }

    init(sceneSize: CGSize) {
        super.init()
        isUserInteractionEnabled = false
        buildUI(sceneSize: sceneSize)
        refreshValues()
        setVisible(false)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func updateLayout(sceneSize: CGSize) {
        removeAllChildren()
        valueLabelsByField.removeAll()
        buildUI(sceneSize: sceneSize)
        refreshValues()
    }

    func setVisible(_ visible: Bool) {
        backdropNode.isHidden = !visible
        panelNode.isHidden = !visible
        if !visible {
            isDraggingCountsScroll = false
            didDragCountsScroll = false
        }
    }

    func beginDrag(at hudLocation: CGPoint) {
        guard isVisible else { return }
        if countsScrollCropNode.contains(hudLocation) {
            isDraggingCountsScroll = true
            didDragCountsScroll = false
            lastCountsDragY = hudLocation.y
        }
    }

    @discardableResult
    func drag(to hudLocation: CGPoint) -> Bool {
        guard isVisible, isDraggingCountsScroll else { return false }

        let deltaY = hudLocation.y - lastCountsDragY
        lastCountsDragY = hudLocation.y
        if abs(deltaY) > 0.5 {
            didDragCountsScroll = true
        }
        setCountsScrollOffset(countsScrollOffset + deltaY)
        return true
    }

    @discardableResult
    func endDrag() -> Bool {
        guard isDraggingCountsScroll else { return false }
        isDraggingCountsScroll = false
        let wasDragging = didDragCountsScroll
        didDragCountsScroll = false
        return wasDragging
    }

    @discardableResult
    func handleTap(hudNodes: [SKNode]) -> Bool {
        guard isVisible else { return false }

        let names = hudNodes.compactMap { resolvedName(from: $0) }

        if names.contains("settingsResetItem") {
            UTSettings.shared.resetCountsToDefaults()
            refreshValues()
            return true
        }

        if names.contains("settingsDoneItem") {
            setVisible(false)
            onClose?()
            return true
        }

        if names.contains("settingsTabCounts") {
            currentTab = .counts
            refreshValues()
            return true
        }

        if let plusName = names.first(where: { $0.hasPrefix("settingsPlus:") }),
           let raw = plusName.split(separator: ":", maxSplits: 1).last,
           let field = UTSettings.CountField(rawValue: String(raw)) {
            UTSettings.shared.adjustValue(for: field, delta: 1)
            refreshValues()
            return true
        }

        if let minusName = names.first(where: { $0.hasPrefix("settingsMinus:") }),
           let raw = minusName.split(separator: ":", maxSplits: 1).last,
           let field = UTSettings.CountField(rawValue: String(raw)) {
            UTSettings.shared.adjustValue(for: field, delta: -1)
            refreshValues()
            return true
        }

        return true
    }

    func refreshValues() {
        for field in UTSettings.CountField.allCases {
            valueLabelsByField[field]?.text = "\(UTSettings.shared.value(for: field))"
        }
    }

    private func setCountsScrollOffset(_ offset: CGFloat) {
        let maxOffset = max(0, countsScrollContentHeight - countsScrollViewportHeight)
        countsScrollOffset = min(max(0, offset), maxOffset)

        countsScrollContentNode.position = CGPoint(x: 0, y: countsScrollContentBaseY + countsScrollOffset)

        let canScroll = maxOffset > 0.5
        countsScrollTrackNode.isHidden = !canScroll
        countsScrollThumbNode.isHidden = !canScroll

        guard canScroll else { return }

        let trackHeight = countsViewportRect.height
        let visibleRatio = min(1, countsScrollViewportHeight / max(1, countsScrollContentHeight))
        let thumbHeight = max(20, trackHeight * visibleRatio)
        let thumbWidth: CGFloat = 6

        countsScrollThumbNode.path = CGPath(
            roundedRect: CGRect(x: -thumbWidth / 2, y: -thumbHeight / 2, width: thumbWidth, height: thumbHeight),
            cornerWidth: thumbWidth / 2,
            cornerHeight: thumbWidth / 2,
            transform: nil
        )

        let progress = countsScrollOffset / maxOffset
        let travel = trackHeight - thumbHeight
        let thumbCenterY = countsViewportRect.maxY - (thumbHeight / 2) - (progress * travel)
        countsScrollThumbNode.position = CGPoint(x: countsViewportRect.maxX - 6, y: thumbCenterY)
    }

    private func buildUI(sceneSize: CGSize) {
        let panelWidth = min(max(sceneSize.width - 120, 640), 900)
        let panelHeight = min(max(sceneSize.height * 0.74, 360), 540)
        let leftPaneWidth: CGFloat = 180
        let rightPaneX = -panelWidth / 2 + leftPaneWidth + 24
        let rightPaneY = -panelHeight / 2 + 12
        let rightPaneWidth = panelWidth - leftPaneWidth - 36
        let rightPaneHeight = panelHeight - 24

        backdropNode.path = CGPath(rect: CGRect(x: -sceneSize.width / 2, y: -sceneSize.height / 2, width: sceneSize.width, height: sceneSize.height), transform: nil)
        backdropNode.fillColor = UIColor.black.withAlphaComponent(0.5)
        backdropNode.strokeColor = .clear
        backdropNode.name = "settingsBackdrop"
        backdropNode.zPosition = 760
        addChild(backdropNode)

        panelNode.path = CGPath(roundedRect: CGRect(x: -panelWidth / 2, y: -panelHeight / 2, width: panelWidth, height: panelHeight), cornerWidth: 12, cornerHeight: 12, transform: nil)
        panelNode.fillColor = UIColor(white: 0.12, alpha: 0.97)
        panelNode.strokeColor = .white
        panelNode.lineWidth = 2
        panelNode.zPosition = 761
        addChild(panelNode)

        leftPaneNode.path = CGPath(rect: CGRect(x: -panelWidth / 2 + 12, y: -panelHeight / 2 + 12, width: leftPaneWidth, height: panelHeight - 24), transform: nil)
        leftPaneNode.fillColor = UIColor(white: 0.16, alpha: 1.0)
        leftPaneNode.strokeColor = UIColor.white.withAlphaComponent(0.25)
        leftPaneNode.lineWidth = 1
        leftPaneNode.zPosition = 762
        panelNode.addChild(leftPaneNode)

        rightPaneNode.path = CGPath(rect: CGRect(x: rightPaneX, y: rightPaneY, width: rightPaneWidth, height: rightPaneHeight), transform: nil)
        rightPaneNode.fillColor = UIColor(white: 0.10, alpha: 1.0)
        rightPaneNode.strokeColor = UIColor.white.withAlphaComponent(0.25)
        rightPaneNode.lineWidth = 1
        rightPaneNode.zPosition = 762
        panelNode.addChild(rightPaneNode)

        let countsTabButton = SKShapeNode(rectOf: CGSize(width: leftPaneWidth - 28, height: 42), cornerRadius: 8)
        countsTabButton.name = "settingsTabCounts"
        countsTabButton.fillColor = UIColor.systemBlue.withAlphaComponent(0.85)
        countsTabButton.strokeColor = .white
        countsTabButton.lineWidth = 1.5
        countsTabButton.position = CGPoint(x: -panelWidth / 2 + 12 + leftPaneWidth / 2, y: panelHeight / 2 - 44)
        countsTabButton.zPosition = 763
        panelNode.addChild(countsTabButton)

        let countsTabLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
        countsTabLabel.name = "settingsTabCounts"
        countsTabLabel.text = "Counts"
        countsTabLabel.fontSize = 21
        countsTabLabel.fontColor = .white
        countsTabLabel.horizontalAlignmentMode = .center
        countsTabLabel.verticalAlignmentMode = .center
        countsTabLabel.zPosition = 764
        countsTabButton.addChild(countsTabLabel)

        let viewportInsetX: CGFloat = 10
        let viewportTopInset: CGFloat = 12
        let viewportBottomInset: CGFloat = 58
        let viewportRect = CGRect(
            x: rightPaneX + viewportInsetX,
            y: rightPaneY + viewportBottomInset,
            width: rightPaneWidth - (viewportInsetX * 2),
            height: rightPaneHeight - viewportTopInset - viewportBottomInset
        )
        countsViewportRect = viewportRect

        countsScrollViewportHeight = viewportRect.height
        countsScrollCropNode.zPosition = 763
        countsScrollCropNode.position = .zero
        panelNode.addChild(countsScrollCropNode)

        let maskNode = SKShapeNode(rect: viewportRect)
        maskNode.fillColor = .white
        maskNode.strokeColor = .clear
        countsScrollCropNode.maskNode = maskNode
        countsScrollCropNode.addChild(countsScrollContentNode)

        countsScrollTrackNode.path = CGPath(
            roundedRect: CGRect(x: -2, y: -countsViewportRect.height / 2, width: 4, height: countsViewportRect.height),
            cornerWidth: 2,
            cornerHeight: 2,
            transform: nil
        )
        countsScrollTrackNode.fillColor = UIColor.white.withAlphaComponent(0.18)
        countsScrollTrackNode.strokeColor = .clear
        countsScrollTrackNode.zPosition = 764
        countsScrollTrackNode.position = CGPoint(x: countsViewportRect.maxX - 6, y: countsViewportRect.midY)
        panelNode.addChild(countsScrollTrackNode)

        countsScrollThumbNode.fillColor = UIColor.white.withAlphaComponent(0.82)
        countsScrollThumbNode.strokeColor = .clear
        countsScrollThumbNode.zPosition = 765
        panelNode.addChild(countsScrollThumbNode)

        let rightStartX = viewportRect.minX + 6
        let controlsMinusX = viewportRect.maxX - 116
        let controlsValueX = viewportRect.maxX - 76
        let controlsPlusX = viewportRect.maxX - 40
        let fields = UTSettings.CountField.allCases
        let rowHeight: CGFloat = 40
        let topPadding: CGFloat = 8
        let bottomPadding: CGFloat = 8
        countsScrollContentHeight = max(
            countsScrollViewportHeight,
            topPadding + bottomPadding + CGFloat(fields.count) * rowHeight
        )
        let topY = countsScrollContentHeight / 2 - topPadding - rowHeight / 2
        countsScrollContentBaseY = viewportRect.maxY - (countsScrollContentHeight / 2)
        var y = topY

        for field in fields {
            let title = SKLabelNode(fontNamed: "AvenirNext-Medium")
            title.text = field.title
            title.fontSize = 18
            title.fontColor = .white
            title.horizontalAlignmentMode = .left
            title.verticalAlignmentMode = .center
            title.position = CGPoint(x: rightStartX, y: y)
            title.zPosition = 763
            countsScrollContentNode.addChild(title)

            let minusButton = SKShapeNode(rectOf: CGSize(width: 30, height: 28), cornerRadius: 5)
            minusButton.name = "settingsMinus:\(field.rawValue)"
            minusButton.fillColor = UIColor.systemRed.withAlphaComponent(0.85)
            minusButton.strokeColor = .white
            minusButton.lineWidth = 1
            minusButton.position = CGPoint(x: controlsMinusX, y: y)
            minusButton.zPosition = 763
            countsScrollContentNode.addChild(minusButton)

            let minusLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
            minusLabel.name = "settingsMinus:\(field.rawValue)"
            minusLabel.text = "−"
            minusLabel.fontSize = 20
            minusLabel.fontColor = .white
            minusLabel.horizontalAlignmentMode = .center
            minusLabel.verticalAlignmentMode = .center
            minusLabel.position = CGPoint(x: 0, y: -1)
            minusLabel.zPosition = 764
            minusButton.addChild(minusLabel)

            let valueLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
            valueLabel.text = "0"
            valueLabel.fontSize = 18
            valueLabel.fontColor = .white
            valueLabel.horizontalAlignmentMode = .center
            valueLabel.verticalAlignmentMode = .center
            valueLabel.position = CGPoint(x: controlsValueX, y: y)
            valueLabel.zPosition = 763
            countsScrollContentNode.addChild(valueLabel)
            valueLabelsByField[field] = valueLabel

            let plusButton = SKShapeNode(rectOf: CGSize(width: 30, height: 28), cornerRadius: 5)
            plusButton.name = "settingsPlus:\(field.rawValue)"
            plusButton.fillColor = UIColor.systemGreen.withAlphaComponent(0.85)
            plusButton.strokeColor = .white
            plusButton.lineWidth = 1
            plusButton.position = CGPoint(x: controlsPlusX, y: y)
            plusButton.zPosition = 763
            countsScrollContentNode.addChild(plusButton)

            let plusLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
            plusLabel.name = "settingsPlus:\(field.rawValue)"
            plusLabel.text = "+"
            plusLabel.fontSize = 20
            plusLabel.fontColor = .white
            plusLabel.horizontalAlignmentMode = .center
            plusLabel.verticalAlignmentMode = .center
            plusLabel.position = CGPoint(x: 0, y: -1)
            plusLabel.zPosition = 764
            plusButton.addChild(plusLabel)

            y -= rowHeight
        }

        setCountsScrollOffset(0)

        let resetButton = SKShapeNode(rectOf: CGSize(width: 130, height: 40), cornerRadius: 8)
        resetButton.name = "settingsResetItem"
        resetButton.fillColor = UIColor.systemOrange.withAlphaComponent(0.9)
        resetButton.strokeColor = .white
        resetButton.lineWidth = 1.5
        resetButton.position = CGPoint(x: panelWidth / 2 - 240, y: -panelHeight / 2 + 34)
        resetButton.zPosition = 763
        panelNode.addChild(resetButton)

        let resetLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
        resetLabel.name = "settingsResetItem"
        resetLabel.text = "Reset"
        resetLabel.fontSize = 21
        resetLabel.fontColor = .white
        resetLabel.horizontalAlignmentMode = .center
        resetLabel.verticalAlignmentMode = .center
        resetLabel.position = .zero
        resetLabel.zPosition = 764
        resetButton.addChild(resetLabel)

        let doneButton = SKShapeNode(rectOf: CGSize(width: 130, height: 40), cornerRadius: 8)
        doneButton.name = "settingsDoneItem"
        doneButton.fillColor = UIColor.systemBlue.withAlphaComponent(0.9)
        doneButton.strokeColor = .white
        doneButton.lineWidth = 1.5
        doneButton.position = CGPoint(x: panelWidth / 2 - 90, y: -panelHeight / 2 + 34)
        doneButton.zPosition = 763
        panelNode.addChild(doneButton)

        let doneLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
        doneLabel.name = "settingsDoneItem"
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
