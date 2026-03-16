import SpriteKit
import UIKit

final class SavesDialogNode: SKNode {
    private let backdropNode = SKShapeNode()
    private let panelNode = SKShapeNode()
    private let titleLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
    private let emptyStateLabel = SKLabelNode(fontNamed: "AvenirNext-Medium")
    private let feedbackLabel = SKLabelNode(fontNamed: "AvenirNext-Medium")

    private let listCropNode = SKCropNode()
    private let listContentNode = SKNode()
    private let listTrackNode = SKShapeNode()
    private let listThumbNode = SKShapeNode()

    private let saveButtonNode = SKShapeNode()
    private let restoreButtonNode = SKShapeNode()
    private let deleteButtonNode = SKShapeNode()
    private let closeButtonNode = SKShapeNode()

    private var listViewportRect: CGRect = .zero
    private var listViewportHeight: CGFloat = 0
    private var listContentHeight: CGFloat = 0
    private var listContentBaseY: CGFloat = 0
    private var listScrollOffset: CGFloat = 0

    private var isDraggingList = false
    private var didDragList = false
    private var lastListDragY: CGFloat = 0

    private var saves: [NamedGameSaveSummary] = []
    private var rowNodeBySaveID: [String: SKShapeNode] = [:]

    private(set) var selectedSaveID: String?

    var onClose: (() -> Void)?
    var onSaveTapped: ((NamedGameSaveSummary?) -> Void)?
    var onRestoreTapped: ((NamedGameSaveSummary?) -> Void)?
    var onDeleteTapped: ((NamedGameSaveSummary?) -> Void)?

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
        rowNodeBySaveID.removeAll()
        buildUI(sceneSize: sceneSize)
        renderSaveList()
        updateListScrollOffset(listScrollOffset)
    }

    func refreshFromPersistence() {
        saves = SaveManager.shared.listNamedSaves()

        if let selectedSaveID,
           !saves.contains(where: { $0.id == selectedSaveID }) {
            self.selectedSaveID = nil
        }

        renderSaveList()
    }

    func selectSave(id: String?) {
        selectedSaveID = id
        updateSelectedState()
        feedbackLabel.removeAllActions()
        feedbackLabel.isHidden = true
    }

    func showFeedback(_ message: String) {
        feedbackLabel.removeAllActions()
        feedbackLabel.text = message
        feedbackLabel.alpha = 0
        feedbackLabel.isHidden = false

        feedbackLabel.run(
            .sequence([
                .fadeAlpha(to: 1, duration: 0.12),
                .wait(forDuration: 1.6),
                .fadeOut(withDuration: 0.25),
                .run { [weak self] in
                    self?.feedbackLabel.isHidden = true
                }
            ])
        )
    }

    func setVisible(_ visible: Bool) {
        backdropNode.isHidden = !visible
        panelNode.isHidden = !visible
        if !visible {
            isDraggingList = false
            didDragList = false
            feedbackLabel.removeAllActions()
            feedbackLabel.isHidden = true
        }
    }

    func beginDrag(at hudLocation: CGPoint) {
        guard isVisible else { return }
        guard listCropNode.contains(hudLocation) else { return }
        isDraggingList = true
        didDragList = false
        lastListDragY = hudLocation.y
    }

    @discardableResult
    func drag(to hudLocation: CGPoint) -> Bool {
        guard isVisible, isDraggingList else { return false }

        let deltaY = hudLocation.y - lastListDragY
        lastListDragY = hudLocation.y
        if abs(deltaY) > 0.5 {
            didDragList = true
        }

        updateListScrollOffset(listScrollOffset + deltaY)
        return true
    }

    @discardableResult
    func endDrag() -> Bool {
        guard isDraggingList else { return false }
        isDraggingList = false
        let wasDragging = didDragList
        didDragList = false
        return wasDragging
    }

    @discardableResult
    func handleTap(hudNodes: [SKNode]) -> Bool {
        guard isVisible else { return false }

        let names = hudNodes.compactMap { resolvedName(from: $0) }

        if names.contains("savesCloseItem") {
            setVisible(false)
            onClose?()
            return true
        }

        if names.contains("savesSaveItem") {
            onSaveTapped?(selectedSaveSummary())
            return true
        }

        if names.contains("savesRestoreItem") {
            onRestoreTapped?(selectedSaveSummary())
            return true
        }

        if names.contains("savesDeleteItem") {
            onDeleteTapped?(selectedSaveSummary())
            return true
        }

        if let rowName = names.first(where: { $0.hasPrefix("savesRow:") }) {
            let saveID = String(rowName.dropFirst("savesRow:".count))
            if saves.contains(where: { $0.id == saveID }) {
                selectedSaveID = saveID
                updateSelectedState()
            }
            return true
        }

        return true
    }

    private func buildUI(sceneSize: CGSize) {
        backdropNode.path = CGPath(rect: CGRect(x: -sceneSize.width / 2, y: -sceneSize.height / 2, width: sceneSize.width, height: sceneSize.height), transform: nil)
        backdropNode.fillColor = UIColor.black.withAlphaComponent(0.45)
        backdropNode.strokeColor = .clear
        backdropNode.name = "savesBackdrop"
        backdropNode.zPosition = 0
        addChild(backdropNode)

        let panelSize = CGSize(width: min(sceneSize.width - 88, 720), height: min(sceneSize.height * 0.8, 700))
        panelNode.path = CGPath(roundedRect: CGRect(x: -panelSize.width / 2, y: -panelSize.height / 2, width: panelSize.width, height: panelSize.height), cornerWidth: 14, cornerHeight: 14, transform: nil)
        panelNode.fillColor = UIColor(white: 0.10, alpha: 0.97)
        panelNode.strokeColor = .white
        panelNode.lineWidth = 2
        panelNode.name = "savesPanel"
        panelNode.zPosition = 1
        addChild(panelNode)

        titleLabel.text = "Saves"
        titleLabel.fontSize = 32
        titleLabel.fontColor = .white
        titleLabel.horizontalAlignmentMode = .center
        titleLabel.verticalAlignmentMode = .center
        titleLabel.position = CGPoint(x: 0, y: panelSize.height / 2 - 34)
        titleLabel.zPosition = 2
        panelNode.addChild(titleLabel)

        let listHeight = panelSize.height - 170
        let listWidth = panelSize.width - 72
        listViewportRect = CGRect(x: -listWidth / 2, y: -listHeight / 2 + 24, width: listWidth, height: listHeight)
        listViewportHeight = listHeight

        listCropNode.zPosition = 2
        listCropNode.position = CGPoint(x: 0, y: listViewportRect.midY)
        panelNode.addChild(listCropNode)

        let listMask = SKSpriteNode(color: .white, size: CGSize(width: listWidth, height: listHeight))
        listMask.position = .zero
        listCropNode.maskNode = listMask
        listCropNode.addChild(listContentNode)

        listTrackNode.path = CGPath(
            roundedRect: CGRect(x: -3, y: -listHeight / 2, width: 6, height: listHeight),
            cornerWidth: 3,
            cornerHeight: 3,
            transform: nil
        )
        listTrackNode.fillColor = UIColor.white.withAlphaComponent(0.2)
        listTrackNode.strokeColor = UIColor.white.withAlphaComponent(0.4)
        listTrackNode.lineWidth = 1
        listTrackNode.position = CGPoint(x: listViewportRect.maxX + 9, y: listViewportRect.midY)
        listTrackNode.zPosition = 2
        panelNode.addChild(listTrackNode)

        listThumbNode.fillColor = UIColor.white.withAlphaComponent(0.85)
        listThumbNode.strokeColor = .white
        listThumbNode.lineWidth = 0.5
        listThumbNode.zPosition = 3
        panelNode.addChild(listThumbNode)

        emptyStateLabel.text = "No saves yet."
        emptyStateLabel.fontSize = 22
        emptyStateLabel.fontColor = UIColor.white.withAlphaComponent(0.75)
        emptyStateLabel.horizontalAlignmentMode = .center
        emptyStateLabel.verticalAlignmentMode = .center
        emptyStateLabel.position = CGPoint(x: 0, y: listViewportRect.midY)
        emptyStateLabel.zPosition = 3
        panelNode.addChild(emptyStateLabel)

        feedbackLabel.text = ""
        feedbackLabel.fontSize = 18
        feedbackLabel.fontColor = UIColor.systemYellow.withAlphaComponent(0.95)
        feedbackLabel.horizontalAlignmentMode = .center
        feedbackLabel.verticalAlignmentMode = .center
        feedbackLabel.position = CGPoint(x: 0, y: -panelSize.height / 2 + 68)
        feedbackLabel.zPosition = 3
        feedbackLabel.isHidden = true
        panelNode.addChild(feedbackLabel)

        saveButtonNode.path = CGPath(roundedRect: CGRect(x: -72, y: -21, width: 144, height: 42), cornerWidth: 8, cornerHeight: 8, transform: nil)
        saveButtonNode.name = "savesSaveItem"
        saveButtonNode.fillColor = UIColor.systemBlue.withAlphaComponent(0.9)
        saveButtonNode.strokeColor = .white
        saveButtonNode.lineWidth = 1.5
        saveButtonNode.position = CGPoint(x: -228, y: -panelSize.height / 2 + 34)
        saveButtonNode.zPosition = 2
        panelNode.addChild(saveButtonNode)
        addButtonLabel(text: "Save", name: "savesSaveItem", to: saveButtonNode)

        restoreButtonNode.path = CGPath(roundedRect: CGRect(x: -72, y: -21, width: 144, height: 42), cornerWidth: 8, cornerHeight: 8, transform: nil)
        restoreButtonNode.name = "savesRestoreItem"
        restoreButtonNode.fillColor = UIColor.systemBlue.withAlphaComponent(0.9)
        restoreButtonNode.strokeColor = .white
        restoreButtonNode.lineWidth = 1.5
        restoreButtonNode.position = CGPoint(x: -76, y: -panelSize.height / 2 + 34)
        restoreButtonNode.zPosition = 2
        panelNode.addChild(restoreButtonNode)
        addButtonLabel(text: "Restore", name: "savesRestoreItem", to: restoreButtonNode)

        deleteButtonNode.path = CGPath(roundedRect: CGRect(x: -72, y: -21, width: 144, height: 42), cornerWidth: 8, cornerHeight: 8, transform: nil)
        deleteButtonNode.name = "savesDeleteItem"
        deleteButtonNode.fillColor = UIColor.systemRed.withAlphaComponent(0.85)
        deleteButtonNode.strokeColor = .white
        deleteButtonNode.lineWidth = 1.5
        deleteButtonNode.position = CGPoint(x: 76, y: -panelSize.height / 2 + 34)
        deleteButtonNode.zPosition = 2
        panelNode.addChild(deleteButtonNode)
        addButtonLabel(text: "Delete", name: "savesDeleteItem", to: deleteButtonNode)

        closeButtonNode.path = CGPath(roundedRect: CGRect(x: -72, y: -21, width: 144, height: 42), cornerWidth: 8, cornerHeight: 8, transform: nil)
        closeButtonNode.name = "savesCloseItem"
        closeButtonNode.fillColor = UIColor(white: 0.25, alpha: 1.0)
        closeButtonNode.strokeColor = .white
        closeButtonNode.lineWidth = 1.5
        closeButtonNode.position = CGPoint(x: 228, y: -panelSize.height / 2 + 34)
        closeButtonNode.zPosition = 2
        panelNode.addChild(closeButtonNode)
        addButtonLabel(text: "Close", name: "savesCloseItem", to: closeButtonNode)

        renderSaveList()
    }

    private func addButtonLabel(text: String, name: String, to buttonNode: SKShapeNode) {
        let label = SKLabelNode(fontNamed: "AvenirNext-Bold")
        label.name = name
        label.text = text
        label.fontSize = 22
        label.fontColor = .white
        label.horizontalAlignmentMode = .center
        label.verticalAlignmentMode = .center
        label.zPosition = 3
        buttonNode.addChild(label)
    }

    private func renderSaveList() {
        listContentNode.removeAllChildren()
        rowNodeBySaveID.removeAll()

        emptyStateLabel.isHidden = !saves.isEmpty

        guard !saves.isEmpty else {
            listContentHeight = listViewportHeight
            listContentBaseY = 0
            updateListScrollOffset(0)
            return
        }

        let rowHeight: CGFloat = 56
        let rowSpacing: CGFloat = 8
        let topPadding: CGFloat = 6
        let bottomPadding: CGFloat = 6

        let contentHeight = topPadding + bottomPadding + CGFloat(saves.count) * rowHeight + CGFloat(max(0, saves.count - 1)) * rowSpacing
        listContentHeight = max(contentHeight, listViewportHeight)

        let rowWidth = listViewportRect.width - 18
        var currentTopY = listContentHeight / 2 - topPadding

        for save in saves {
            let rowName = "savesRow:\(save.id)"
            let rowNode = SKShapeNode(rectOf: CGSize(width: rowWidth, height: rowHeight), cornerRadius: 8)
            rowNode.name = rowName
            rowNode.strokeColor = UIColor.white.withAlphaComponent(0.25)
            rowNode.lineWidth = 1
            rowNode.position = CGPoint(x: 0, y: currentTopY - rowHeight / 2)
            rowNode.zPosition = 2
            listContentNode.addChild(rowNode)
            rowNodeBySaveID[save.id] = rowNode

            let nameLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
            nameLabel.name = rowName
            nameLabel.text = save.name
            nameLabel.fontSize = 21
            nameLabel.fontColor = .white
            nameLabel.horizontalAlignmentMode = .left
            nameLabel.verticalAlignmentMode = .center
            nameLabel.position = CGPoint(x: -rowWidth / 2 + 12, y: 8)
            nameLabel.zPosition = 3
            rowNode.addChild(nameLabel)

            let dateLabel = SKLabelNode(fontNamed: "AvenirNext-Medium")
            dateLabel.name = rowName
            dateLabel.text = "Saved \(Self.savedAtFormatter.string(from: save.savedAt))"
            dateLabel.fontSize = 14
            dateLabel.fontColor = UIColor.white.withAlphaComponent(0.75)
            dateLabel.horizontalAlignmentMode = .left
            dateLabel.verticalAlignmentMode = .center
            dateLabel.position = CGPoint(x: -rowWidth / 2 + 12, y: -12)
            dateLabel.zPosition = 3
            rowNode.addChild(dateLabel)

            currentTopY -= (rowHeight + rowSpacing)
        }

        listContentBaseY = (listViewportHeight - listContentHeight) / 2
        updateSelectedState()
        updateListScrollOffset(0)
    }

    private func selectedSaveSummary() -> NamedGameSaveSummary? {
        guard let selectedSaveID else { return nil }
        return saves.first(where: { $0.id == selectedSaveID })
    }

    private func updateSelectedState() {
        for save in saves {
            guard let rowNode = rowNodeBySaveID[save.id] else { continue }

            if save.id == selectedSaveID {
                rowNode.fillColor = UIColor.systemBlue.withAlphaComponent(0.35)
                rowNode.strokeColor = UIColor.systemBlue
                rowNode.lineWidth = 2
            } else {
                rowNode.fillColor = UIColor(white: 0.18, alpha: 0.75)
                rowNode.strokeColor = UIColor.white.withAlphaComponent(0.25)
                rowNode.lineWidth = 1
            }
        }
    }

    private func updateListScrollOffset(_ offset: CGFloat) {
        let maxOffset = max(0, listContentHeight - listViewportHeight)
        listScrollOffset = min(max(0, offset), maxOffset)

        listContentNode.position = CGPoint(x: 0, y: listContentBaseY + listScrollOffset)

        let canScroll = maxOffset > 0.5
        listTrackNode.isHidden = !canScroll
        listThumbNode.isHidden = !canScroll

        guard canScroll else { return }

        let trackHeight = listViewportRect.height
        let visibleRatio = min(1, listViewportHeight / max(1, listContentHeight))
        let thumbHeight = max(24, trackHeight * visibleRatio)
        let thumbWidth: CGFloat = 6

        listThumbNode.path = CGPath(
            roundedRect: CGRect(x: -thumbWidth / 2, y: -thumbHeight / 2, width: thumbWidth, height: thumbHeight),
            cornerWidth: thumbWidth / 2,
            cornerHeight: thumbWidth / 2,
            transform: nil
        )

        let progress = listScrollOffset / maxOffset
        let travel = trackHeight - thumbHeight
        let thumbCenterY = listViewportRect.maxY - (thumbHeight / 2) - (progress * travel)
        listThumbNode.position = CGPoint(x: listViewportRect.maxX + 9, y: thumbCenterY)
    }

    private func resolvedName(from node: SKNode) -> String? {
        if let name = node.name {
            return name
        }
        return node.parent?.name
    }

    private static let savedAtFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()
}
