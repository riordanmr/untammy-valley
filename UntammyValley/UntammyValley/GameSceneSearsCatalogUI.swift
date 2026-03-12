import SpriteKit
import UIKit

extension GameScene {
    func configureSearsCatalogDialog() {
        guard cameraNode != nil else { return }

        searsCatalogBackdropNode?.removeFromParent()
        searsCatalogPanelNode?.removeFromParent()
        searsCatalogAlertBackdropNode?.removeFromParent()
        searsCatalogAlertPanelNode?.removeFromParent()

        searsCatalogBackdropNode = SKShapeNode(rectOf: CGSize(width: size.width, height: size.height))
        searsCatalogBackdropNode.name = SearsCatalogNodeName.backdrop
        searsCatalogBackdropNode.fillColor = UIColor.black.withAlphaComponent(0.45)
        searsCatalogBackdropNode.strokeColor = .clear
        searsCatalogBackdropNode.position = .zero
        searsCatalogBackdropNode.zPosition = ZLayer.searsCatalogDialog
        searsCatalogBackdropNode.isHidden = true
        cameraNode.addChild(searsCatalogBackdropNode)

        let panelWidth = min(size.width - 72, 820)
        let panelHeight = min(size.height - 96, 560)
        searsCatalogPanelNode = SKShapeNode(
            rectOf: CGSize(width: panelWidth, height: panelHeight),
            cornerRadius: 14
        )
        searsCatalogPanelNode.name = SearsCatalogNodeName.panel
        searsCatalogPanelNode.fillColor = UIColor(white: 0.12, alpha: 0.98)
        searsCatalogPanelNode.strokeColor = .white
        searsCatalogPanelNode.lineWidth = 2
        searsCatalogPanelNode.position = .zero
        searsCatalogPanelNode.zPosition = ZLayer.searsCatalogDialog + 1
        searsCatalogPanelNode.isHidden = true
        cameraNode.addChild(searsCatalogPanelNode)

        let titleLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
        titleLabel.text = "Sears Catalog"
        titleLabel.fontSize = 32
        titleLabel.fontColor = .white
        titleLabel.horizontalAlignmentMode = .center
        titleLabel.verticalAlignmentMode = .center
        titleLabel.position = CGPoint(x: 0, y: panelHeight / 2 - 36)
        titleLabel.zPosition = ZLayer.searsCatalogDialog + 2
        searsCatalogPanelNode.addChild(titleLabel)

        let instructionLine1 = SKLabelNode(fontNamed: "AvenirNext-Medium")
        instructionLine1.text = "Check the items you want to buy."
        instructionLine1.fontSize = 20
        instructionLine1.fontColor = .white
        instructionLine1.horizontalAlignmentMode = .center
        instructionLine1.verticalAlignmentMode = .center
        instructionLine1.position = CGPoint(x: 0, y: panelHeight / 2 - 78)
        instructionLine1.zPosition = ZLayer.searsCatalogDialog + 2
        searsCatalogPanelNode.addChild(instructionLine1)

        let instructionLine2 = SKLabelNode(fontNamed: "AvenirNext-Medium")
        instructionLine2.text = "Touch Prepare Order to pay and prepare the envelope to be mailed."
        instructionLine2.fontSize = 19
        instructionLine2.fontColor = .white
        instructionLine2.horizontalAlignmentMode = .center
        instructionLine2.verticalAlignmentMode = .center
        instructionLine2.position = CGPoint(x: 0, y: panelHeight / 2 - 98)
        instructionLine2.zPosition = ZLayer.searsCatalogDialog + 2
        searsCatalogPanelNode.addChild(instructionLine2)

        let listTopY = panelHeight / 2 - 124
        let buttonTopY = (-panelHeight / 2 + 44) + 23
        let minListBottomGap: CGFloat = 24
        let minListHeight: CGFloat = 72
        let maxListHeight: CGFloat = 220
        let availableListHeight = listTopY - (buttonTopY + minListBottomGap)
        let listHeight = max(minListHeight, min(maxListHeight, availableListHeight))
        let listWidth = panelWidth - 48

        let listFrame = SKShapeNode(
            rectOf: CGSize(width: listWidth, height: listHeight),
            cornerRadius: 8
        )
        listFrame.fillColor = UIColor(white: 0.08, alpha: 0.95)
        listFrame.strokeColor = UIColor.white.withAlphaComponent(0.5)
        listFrame.lineWidth = 1.2
        listFrame.position = CGPoint(x: 0, y: listTopY - listHeight / 2)
        listFrame.zPosition = ZLayer.searsCatalogDialog + 2
        searsCatalogPanelNode.addChild(listFrame)

        let coinsHeading = SKLabelNode(fontNamed: "AvenirNext-Bold")
        coinsHeading.text = "Coins"
        coinsHeading.fontSize = 18
        coinsHeading.fontColor = .white
        coinsHeading.horizontalAlignmentMode = .center
        coinsHeading.verticalAlignmentMode = .center
        coinsHeading.position = CGPoint(x: -listWidth * 0.21, y: listHeight / 2 - 24)
        coinsHeading.zPosition = ZLayer.searsCatalogDialog + 3
        listFrame.addChild(coinsHeading)

        let descriptionHeading = SKLabelNode(fontNamed: "AvenirNext-Bold")
        descriptionHeading.text = "Description"
        descriptionHeading.fontSize = 18
        descriptionHeading.fontColor = .white
        descriptionHeading.horizontalAlignmentMode = .center
        descriptionHeading.verticalAlignmentMode = .center
        descriptionHeading.position = CGPoint(x: listWidth * 0.16, y: listHeight / 2 - 24)
        descriptionHeading.zPosition = ZLayer.searsCatalogDialog + 3
        listFrame.addChild(descriptionHeading)

        let rowTopInset = min(68, max(46, listHeight * 0.34))
        let rowY = listHeight / 2 - rowTopInset

        searsCatalogItemCheckboxNode = SKLabelNode(fontNamed: "Menlo-Bold")
        searsCatalogItemCheckboxNode.name = SearsCatalogNodeName.raftToggleItem
        searsCatalogItemCheckboxNode.fontSize = 22
        searsCatalogItemCheckboxNode.fontColor = .white
        searsCatalogItemCheckboxNode.horizontalAlignmentMode = .center
        searsCatalogItemCheckboxNode.verticalAlignmentMode = .center
        searsCatalogItemCheckboxNode.position = CGPoint(x: -listWidth * 0.42, y: rowY)
        searsCatalogItemCheckboxNode.zPosition = ZLayer.searsCatalogDialog + 3
        listFrame.addChild(searsCatalogItemCheckboxNode)

        let rowHitTarget = SKShapeNode(
            rectOf: CGSize(width: listWidth - 18, height: max(34, min(46, listHeight * 0.24))),
            cornerRadius: 6
        )
        rowHitTarget.name = SearsCatalogNodeName.raftToggleItem
        rowHitTarget.fillColor = UIColor.clear
        rowHitTarget.strokeColor = UIColor.clear
        rowHitTarget.position = CGPoint(x: 0, y: rowY)
        rowHitTarget.zPosition = ZLayer.searsCatalogDialog + 2
        listFrame.addChild(rowHitTarget)

        let priceLabel = SKLabelNode(fontNamed: "AvenirNext-Medium")
        priceLabel.text = "\(searsCatalogRaftPriceCoins)"
        priceLabel.fontSize = 20
        priceLabel.fontColor = .white
        priceLabel.horizontalAlignmentMode = .center
        priceLabel.verticalAlignmentMode = .center
        priceLabel.position = CGPoint(x: -listWidth * 0.21, y: rowY)
        priceLabel.zPosition = ZLayer.searsCatalogDialog + 3
        listFrame.addChild(priceLabel)

        let descriptionLabel = SKLabelNode(fontNamed: "AvenirNext-Medium")
        descriptionLabel.text = "Raft"
        descriptionLabel.fontSize = 20
        descriptionLabel.fontColor = .white
        descriptionLabel.horizontalAlignmentMode = .left
        descriptionLabel.verticalAlignmentMode = .center
        descriptionLabel.position = CGPoint(x: listWidth * 0.03, y: rowY)
        descriptionLabel.zPosition = ZLayer.searsCatalogDialog + 3
        listFrame.addChild(descriptionLabel)

        let prepareButton = SKShapeNode(rectOf: CGSize(width: 220, height: 46), cornerRadius: 8)
        prepareButton.name = SearsCatalogNodeName.prepareItem
        prepareButton.fillColor = UIColor.systemBlue.withAlphaComponent(0.9)
        prepareButton.strokeColor = .white
        prepareButton.lineWidth = 1.5
        prepareButton.position = CGPoint(x: -130, y: -panelHeight / 2 + 44)
        prepareButton.zPosition = ZLayer.searsCatalogDialog + 2
        searsCatalogPanelNode.addChild(prepareButton)

        let prepareLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
        prepareLabel.name = SearsCatalogNodeName.prepareItem
        prepareLabel.text = "Prepare Order"
        prepareLabel.fontSize = 21
        prepareLabel.fontColor = .white
        prepareLabel.horizontalAlignmentMode = .center
        prepareLabel.verticalAlignmentMode = .center
        prepareLabel.position = .zero
        prepareLabel.zPosition = ZLayer.searsCatalogDialog + 3
        prepareButton.addChild(prepareLabel)

        let cancelButton = SKShapeNode(rectOf: CGSize(width: 160, height: 46), cornerRadius: 8)
        cancelButton.name = SearsCatalogNodeName.cancelItem
        cancelButton.fillColor = UIColor.darkGray.withAlphaComponent(0.9)
        cancelButton.strokeColor = .white
        cancelButton.lineWidth = 1.5
        cancelButton.position = CGPoint(x: 150, y: -panelHeight / 2 + 44)
        cancelButton.zPosition = ZLayer.searsCatalogDialog + 2
        searsCatalogPanelNode.addChild(cancelButton)

        let cancelLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
        cancelLabel.name = SearsCatalogNodeName.cancelItem
        cancelLabel.text = "Cancel"
        cancelLabel.fontSize = 21
        cancelLabel.fontColor = .white
        cancelLabel.horizontalAlignmentMode = .center
        cancelLabel.verticalAlignmentMode = .center
        cancelLabel.position = .zero
        cancelLabel.zPosition = ZLayer.searsCatalogDialog + 3
        cancelButton.addChild(cancelLabel)

        searsCatalogAlertBackdropNode = SKShapeNode(rectOf: CGSize(width: size.width, height: size.height))
        searsCatalogAlertBackdropNode.name = SearsCatalogNodeName.alertBackdrop
        searsCatalogAlertBackdropNode.fillColor = UIColor(white: 0.0, alpha: 1.0)
        searsCatalogAlertBackdropNode.strokeColor = .clear
        searsCatalogAlertBackdropNode.lineWidth = 0
        searsCatalogAlertBackdropNode.position = .zero
        searsCatalogAlertBackdropNode.zPosition = ZLayer.searsCatalogDialog + 4
        searsCatalogAlertBackdropNode.isHidden = true
        cameraNode.addChild(searsCatalogAlertBackdropNode)

        searsCatalogAlertPanelNode = SKShapeNode(rectOf: CGSize(width: min(panelWidth - 80, 560), height: 190), cornerRadius: 12)
        searsCatalogAlertPanelNode.name = SearsCatalogNodeName.alertPanel
        searsCatalogAlertPanelNode.fillColor = UIColor(white: 0.08, alpha: 0.98)
        searsCatalogAlertPanelNode.strokeColor = .white
        searsCatalogAlertPanelNode.lineWidth = 1.8
        searsCatalogAlertPanelNode.position = CGPoint(x: 0, y: -10)
        searsCatalogAlertPanelNode.zPosition = ZLayer.searsCatalogDialog + 5
        searsCatalogAlertPanelNode.isHidden = true
        cameraNode.addChild(searsCatalogAlertPanelNode)

        searsCatalogAlertMessageLabel = SKLabelNode(fontNamed: "AvenirNext-Medium")
        searsCatalogAlertMessageLabel.fontSize = 20
        searsCatalogAlertMessageLabel.fontColor = .white
        searsCatalogAlertMessageLabel.horizontalAlignmentMode = .center
        searsCatalogAlertMessageLabel.verticalAlignmentMode = .center
        searsCatalogAlertMessageLabel.numberOfLines = 2
        searsCatalogAlertMessageLabel.preferredMaxLayoutWidth = min(panelWidth - 130, 500)
        searsCatalogAlertMessageLabel.position = CGPoint(x: 0, y: 24)
        searsCatalogAlertMessageLabel.zPosition = ZLayer.searsCatalogDialog + 6
        searsCatalogAlertPanelNode.addChild(searsCatalogAlertMessageLabel)

        let alertOKButton = SKShapeNode(rectOf: CGSize(width: 120, height: 42), cornerRadius: 8)
        alertOKButton.name = SearsCatalogNodeName.alertOKItem
        alertOKButton.fillColor = UIColor.systemBlue.withAlphaComponent(0.9)
        alertOKButton.strokeColor = .white
        alertOKButton.lineWidth = 1.4
        alertOKButton.position = CGPoint(x: 0, y: -58)
        alertOKButton.zPosition = ZLayer.searsCatalogDialog + 6
        searsCatalogAlertPanelNode.addChild(alertOKButton)

        let alertOKLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
        alertOKLabel.name = SearsCatalogNodeName.alertOKItem
        alertOKLabel.text = "OK"
        alertOKLabel.fontSize = 20
        alertOKLabel.fontColor = .white
        alertOKLabel.horizontalAlignmentMode = .center
        alertOKLabel.verticalAlignmentMode = .center
        alertOKLabel.position = .zero
        alertOKLabel.zPosition = ZLayer.searsCatalogDialog + 7
        alertOKButton.addChild(alertOKLabel)

        updateSearsCatalogCheckboxVisual()
        setSearsCatalogDialogVisible(false)
    }

    func setSearsCatalogDialogVisible(_ visible: Bool) {
        isSearsCatalogDialogVisible = visible
        if !visible {
            isSearsCatalogAlertVisible = false
        }
        updateSearsCatalogModalVisibility()
    }

    func updateSearsCatalogCheckboxVisual() {
        searsCatalogItemCheckboxNode?.text = searsCatalogItemChecked ? "[x]" : "[ ]"
    }

    func setSearsCatalogAlertVisible(_ visible: Bool, message: String = "") {
        isSearsCatalogAlertVisible = visible && isSearsCatalogDialogVisible
        if isSearsCatalogAlertVisible {
            searsCatalogAlertMessageLabel?.text = message
        }
        updateSearsCatalogModalVisibility()
    }

    func updateSearsCatalogModalVisibility() {
        searsCatalogBackdropNode?.isHidden = !isSearsCatalogDialogVisible
        searsCatalogPanelNode?.isHidden = !isSearsCatalogDialogVisible || isSearsCatalogAlertVisible
        searsCatalogAlertBackdropNode?.isHidden = !isSearsCatalogAlertVisible
        searsCatalogAlertPanelNode?.isHidden = !isSearsCatalogAlertVisible
    }
}
