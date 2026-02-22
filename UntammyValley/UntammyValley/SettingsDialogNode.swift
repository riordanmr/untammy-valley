//
//  SettingsDialogNode.swift
//  UntammyValley
//

import SpriteKit
import UIKit

final class SettingsDialogNode: SKNode {
    private enum Tab: String {
        case counts
        case avatar
    }

    private let backdropNode = SKShapeNode()
    private let panelNode = SKShapeNode()
    private let leftPaneNode = SKShapeNode()
    private let rightPaneNode = SKShapeNode()
    private let countsTabButtonNode = SKShapeNode()
    private let avatarTabButtonNode = SKShapeNode()
    private let countsScrollCropNode = SKCropNode()
    private let countsScrollContentNode = SKNode()
    private let countsScrollTrackNode = SKShapeNode()
    private let countsScrollThumbNode = SKShapeNode()
    private let avatarScrollCropNode = SKCropNode()
    private let avatarScrollContentNode = SKNode()
    private let avatarScrollTrackNode = SKShapeNode()
    private let avatarScrollThumbNode = SKShapeNode()
    private let resetFeedbackLabel = SKLabelNode(fontNamed: "AvenirNext-Medium")

    private var valueLabelsByField: [UTSettings.CountField: SKLabelNode] = [:]
    private var avatarSelectionBorderByAvatar: [UTSettings.Avatar: SKShapeNode] = [:]
    private var currentTab: Tab = .counts
    private var countsScrollOffset: CGFloat = 0
    private var countsScrollViewportHeight: CGFloat = 0
    private var countsScrollContentHeight: CGFloat = 0
    private var countsScrollContentBaseY: CGFloat = 0
    private var countsViewportRect: CGRect = .zero
    private var avatarScrollOffset: CGFloat = 0
    private var avatarScrollViewportHeight: CGFloat = 0
    private var avatarScrollContentHeight: CGFloat = 0
    private var avatarScrollContentBaseY: CGFloat = 0
    private var avatarViewportRect: CGRect = .zero
    private var isDraggingCountsScroll = false
    private var didDragCountsScroll = false
    private var lastCountsDragY: CGFloat = 0
    private var isDraggingAvatarScroll = false
    private var didDragAvatarScroll = false
    private var lastAvatarDragY: CGFloat = 0

    var onClose: (() -> Void)?
    var onAvatarChanged: (() -> Void)?

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
            isDraggingAvatarScroll = false
            didDragAvatarScroll = false
        }
    }

    func beginDrag(at hudLocation: CGPoint) {
        guard isVisible else { return }
        if currentTab == .counts, countsScrollCropNode.contains(hudLocation) {
            isDraggingCountsScroll = true
            didDragCountsScroll = false
            lastCountsDragY = hudLocation.y
        } else if currentTab == .avatar, avatarScrollCropNode.contains(hudLocation) {
            isDraggingAvatarScroll = true
            didDragAvatarScroll = false
            lastAvatarDragY = hudLocation.y
        }
    }

    @discardableResult
    func drag(to hudLocation: CGPoint) -> Bool {
        guard isVisible else { return false }

        if isDraggingCountsScroll {
            let deltaY = hudLocation.y - lastCountsDragY
            lastCountsDragY = hudLocation.y
            if abs(deltaY) > 0.5 {
                didDragCountsScroll = true
            }
            setCountsScrollOffset(countsScrollOffset + deltaY)
            return true
        }

        if isDraggingAvatarScroll {
            let deltaY = hudLocation.y - lastAvatarDragY
            lastAvatarDragY = hudLocation.y
            if abs(deltaY) > 0.5 {
                didDragAvatarScroll = true
            }
            setAvatarScrollOffset(avatarScrollOffset + deltaY)
            return true
        }

        return false
    }

    @discardableResult
    func endDrag() -> Bool {
        if isDraggingCountsScroll {
            isDraggingCountsScroll = false
            let wasDragging = didDragCountsScroll
            didDragCountsScroll = false
            return wasDragging
        }

        if isDraggingAvatarScroll {
            isDraggingAvatarScroll = false
            let wasDragging = didDragAvatarScroll
            didDragAvatarScroll = false
            return wasDragging
        }

        return false
    }

    @discardableResult
    func handleTap(hudNodes: [SKNode]) -> Bool {
        guard isVisible else { return false }

        let names = hudNodes.compactMap { resolvedName(from: $0) }

        if names.contains("settingsResetItem") {
            let previousAvatar = UTSettings.shared.avatar
            UTSettings.shared.resetToDefaults()
            if previousAvatar != UTSettings.shared.avatar {
                onAvatarChanged?()
            }
            refreshValues()
            showResetFeedback()
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

        if names.contains("settingsTabAvatar") {
            currentTab = .avatar
            refreshValues()
            return true
        }

        if let avatarName = names.first(where: { $0.hasPrefix("settingsAvatar:") }),
           let raw = avatarName.split(separator: ":", maxSplits: 1).last,
           let avatar = UTSettings.Avatar(rawValue: String(raw)) {
            if UTSettings.shared.avatar != avatar {
                UTSettings.shared.setAvatar(avatar)
                onAvatarChanged?()
            }
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

        let selectedAvatar = UTSettings.shared.avatar
        for (avatar, borderNode) in avatarSelectionBorderByAvatar {
            if avatar == selectedAvatar {
                borderNode.lineWidth = 5
                borderNode.strokeColor = UIColor.systemBlue
            } else {
                borderNode.lineWidth = 1.5
                borderNode.strokeColor = UIColor.white.withAlphaComponent(0.35)
            }
        }

        applyTabState()
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

    private func setAvatarScrollOffset(_ offset: CGFloat) {
        let maxOffset = max(0, avatarScrollContentHeight - avatarScrollViewportHeight)
        avatarScrollOffset = min(max(0, offset), maxOffset)

        avatarScrollContentNode.position = CGPoint(x: 0, y: avatarScrollContentBaseY + avatarScrollOffset)

        let canScroll = maxOffset > 0.5
        avatarScrollTrackNode.isHidden = !canScroll
        avatarScrollThumbNode.isHidden = !canScroll

        guard canScroll else { return }

        let trackHeight = avatarViewportRect.height
        let visibleRatio = min(1, avatarScrollViewportHeight / max(1, avatarScrollContentHeight))
        let thumbHeight = max(20, trackHeight * visibleRatio)
        let thumbWidth: CGFloat = 6

        avatarScrollThumbNode.path = CGPath(
            roundedRect: CGRect(x: -thumbWidth / 2, y: -thumbHeight / 2, width: thumbWidth, height: thumbHeight),
            cornerWidth: thumbWidth / 2,
            cornerHeight: thumbWidth / 2,
            transform: nil
        )

        let progress = avatarScrollOffset / maxOffset
        let travel = trackHeight - thumbHeight
        let thumbCenterY = avatarViewportRect.maxY - (thumbHeight / 2) - (progress * travel)
        avatarScrollThumbNode.position = CGPoint(x: avatarViewportRect.maxX - 6, y: thumbCenterY)
    }

    private func applyTabState() {
        let countsSelected = currentTab == .counts

        countsTabButtonNode.fillColor = countsSelected
            ? UIColor.systemBlue.withAlphaComponent(0.85)
            : UIColor(white: 0.22, alpha: 1.0)
        avatarTabButtonNode.fillColor = countsSelected
            ? UIColor(white: 0.22, alpha: 1.0)
            : UIColor.systemBlue.withAlphaComponent(0.85)

        countsScrollCropNode.isHidden = !countsSelected
        countsScrollTrackNode.isHidden = !countsSelected
        countsScrollThumbNode.isHidden = !countsSelected

        avatarScrollCropNode.isHidden = countsSelected
        avatarScrollTrackNode.isHidden = countsSelected
        avatarScrollThumbNode.isHidden = countsSelected
    }

    private func showResetFeedback() {
        resetFeedbackLabel.removeAllActions()
        resetFeedbackLabel.text = "Reset complete"
        resetFeedbackLabel.isHidden = false
        resetFeedbackLabel.alpha = 0

        let sequence: [SKAction] = [
            .fadeAlpha(to: 1, duration: 0.12),
            .wait(forDuration: 1.0),
            .fadeOut(withDuration: 0.25),
            .run { [weak self] in
                self?.resetFeedbackLabel.isHidden = true
            }
        ]
        resetFeedbackLabel.run(.sequence(sequence))
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

        countsTabButtonNode.path = CGPath(roundedRect: CGRect(x: -(leftPaneWidth - 28) / 2, y: -21, width: leftPaneWidth - 28, height: 42), cornerWidth: 8, cornerHeight: 8, transform: nil)
        countsTabButtonNode.name = "settingsTabCounts"
        countsTabButtonNode.strokeColor = .white
        countsTabButtonNode.lineWidth = 1.5
        countsTabButtonNode.position = CGPoint(x: -panelWidth / 2 + 12 + leftPaneWidth / 2, y: panelHeight / 2 - 44)
        countsTabButtonNode.zPosition = 763
        panelNode.addChild(countsTabButtonNode)

        let countsTabLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
        countsTabLabel.name = "settingsTabCounts"
        countsTabLabel.text = "Counts"
        countsTabLabel.fontSize = 21
        countsTabLabel.fontColor = .white
        countsTabLabel.horizontalAlignmentMode = .center
        countsTabLabel.verticalAlignmentMode = .center
        countsTabLabel.zPosition = 764
        countsTabButtonNode.addChild(countsTabLabel)

        avatarTabButtonNode.path = CGPath(roundedRect: CGRect(x: -(leftPaneWidth - 28) / 2, y: -21, width: leftPaneWidth - 28, height: 42), cornerWidth: 8, cornerHeight: 8, transform: nil)
        avatarTabButtonNode.name = "settingsTabAvatar"
        avatarTabButtonNode.strokeColor = .white
        avatarTabButtonNode.lineWidth = 1.5
        avatarTabButtonNode.position = CGPoint(x: -panelWidth / 2 + 12 + leftPaneWidth / 2, y: panelHeight / 2 - 96)
        avatarTabButtonNode.zPosition = 763
        panelNode.addChild(avatarTabButtonNode)

        let avatarTabLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
        avatarTabLabel.name = "settingsTabAvatar"
        avatarTabLabel.text = "Avatar"
        avatarTabLabel.fontSize = 21
        avatarTabLabel.fontColor = .white
        avatarTabLabel.horizontalAlignmentMode = .center
        avatarTabLabel.verticalAlignmentMode = .center
        avatarTabLabel.zPosition = 764
        avatarTabButtonNode.addChild(avatarTabLabel)

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
        avatarViewportRect = viewportRect

        countsScrollContentNode.removeAllChildren()
        avatarScrollContentNode.removeAllChildren()
        valueLabelsByField.removeAll()
        avatarSelectionBorderByAvatar.removeAll()

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

        avatarScrollViewportHeight = viewportRect.height
        avatarScrollCropNode.zPosition = 763
        avatarScrollCropNode.position = .zero
        panelNode.addChild(avatarScrollCropNode)

        let avatarMaskNode = SKShapeNode(rect: viewportRect)
        avatarMaskNode.fillColor = .white
        avatarMaskNode.strokeColor = .clear
        avatarScrollCropNode.maskNode = avatarMaskNode
        avatarScrollCropNode.addChild(avatarScrollContentNode)

        avatarScrollTrackNode.path = CGPath(
            roundedRect: CGRect(x: -2, y: -avatarViewportRect.height / 2, width: 4, height: avatarViewportRect.height),
            cornerWidth: 2,
            cornerHeight: 2,
            transform: nil
        )
        avatarScrollTrackNode.fillColor = UIColor.white.withAlphaComponent(0.18)
        avatarScrollTrackNode.strokeColor = .clear
        avatarScrollTrackNode.zPosition = 764
        avatarScrollTrackNode.position = CGPoint(x: avatarViewportRect.maxX - 6, y: avatarViewportRect.midY)
        panelNode.addChild(avatarScrollTrackNode)

        avatarScrollThumbNode.fillColor = UIColor.white.withAlphaComponent(0.82)
        avatarScrollThumbNode.strokeColor = .clear
        avatarScrollThumbNode.zPosition = 765
        panelNode.addChild(avatarScrollThumbNode)

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

        let avatars = UTSettings.Avatar.allCases
        let avatarColumns = 2
        let cellSpacingX: CGFloat = 16
        let cellPaddingX: CGFloat = 12
        let cellWidth = (viewportRect.width - (cellPaddingX * 2) - cellSpacingX) / CGFloat(avatarColumns)
        let imageSize = max(80, min(170, cellWidth - 30))
        let avatarRowHeight = imageSize + 56
        let rows = Int(ceil(Double(avatars.count) / Double(avatarColumns)))
        let avatarTopPadding: CGFloat = 10
        let avatarBottomPadding: CGFloat = 10
        avatarScrollContentHeight = max(
            avatarScrollViewportHeight,
            avatarTopPadding + avatarBottomPadding + CGFloat(rows) * avatarRowHeight
        )
        let avatarTopY = avatarScrollContentHeight / 2 - avatarTopPadding - avatarRowHeight / 2
        avatarScrollContentBaseY = viewportRect.maxY - (avatarScrollContentHeight / 2)

        for (index, avatar) in avatars.enumerated() {
            let row = index / avatarColumns
            let column = index % avatarColumns
            let centerX = viewportRect.minX + cellPaddingX + cellWidth / 2 + CGFloat(column) * (cellWidth + cellSpacingX)
            let centerY = avatarTopY - CGFloat(row) * avatarRowHeight

            let itemName = "settingsAvatar:\(avatar.rawValue)"
            let itemSize = CGSize(width: cellWidth, height: avatarRowHeight - 8)

            let container = SKShapeNode(rectOf: itemSize, cornerRadius: 10)
            container.name = itemName
            container.fillColor = UIColor(white: 0.18, alpha: 1.0)
            container.strokeColor = UIColor.white.withAlphaComponent(0.25)
            container.lineWidth = 1
            container.position = CGPoint(x: centerX, y: centerY)
            container.zPosition = 763
            avatarScrollContentNode.addChild(container)

            let selectionBorder = SKShapeNode(rectOf: CGSize(width: itemSize.width - 4, height: itemSize.height - 4), cornerRadius: 9)
            selectionBorder.name = itemName
            selectionBorder.fillColor = .clear
            selectionBorder.strokeColor = UIColor.white.withAlphaComponent(0.35)
            selectionBorder.lineWidth = 1.5
            selectionBorder.zPosition = 764
            container.addChild(selectionBorder)
            avatarSelectionBorderByAvatar[avatar] = selectionBorder

            let avatarTexture = SKTexture(imageNamed: avatar.assetName)
            let resolvedTexture = avatarTexture.size() == .zero ? SKTexture(imageNamed: "player_icon") : avatarTexture
            let avatarSprite = SKSpriteNode(texture: resolvedTexture)
            avatarSprite.name = itemName
            avatarSprite.size = CGSize(width: imageSize, height: imageSize)
            avatarSprite.position = CGPoint(x: 0, y: 0)
            avatarSprite.zPosition = 764
            container.addChild(avatarSprite)
        }

        setAvatarScrollOffset(0)

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

        resetFeedbackLabel.text = ""
        resetFeedbackLabel.fontSize = 18
        resetFeedbackLabel.fontColor = UIColor.systemGreen
        resetFeedbackLabel.horizontalAlignmentMode = .center
        resetFeedbackLabel.verticalAlignmentMode = .center
        resetFeedbackLabel.position = CGPoint(x: 0, y: -panelHeight / 2 + 34)
        resetFeedbackLabel.zPosition = 764
        resetFeedbackLabel.isHidden = true
        resetFeedbackLabel.alpha = 1
        panelNode.addChild(resetFeedbackLabel)

        applyTabState()
    }

    private func resolvedName(from node: SKNode) -> String? {
        if let name = node.name {
            return name
        }
        return node.parent?.name
    }
}
