import SpriteKit

extension GameScene {
    func shouldBlockWorldInputForSearsModal() -> Bool {
        isSearsCatalogDialogVisible
    }

    func handleSearsCatalogHUDTap(hudNodes: [SKNode]) -> Bool {
        guard isSearsCatalogDialogVisible else {
            return false
        }

        if isSearsCatalogAlertVisible {
            if hudNodes.contains(where: { $0.name == SearsCatalogNodeName.alertOKItem || $0.parent?.name == SearsCatalogNodeName.alertOKItem }) {
                setSearsCatalogAlertVisible(false)
            }
            return true
        }

        if hudNodes.contains(where: { $0.name == SearsCatalogNodeName.prepareItem || $0.parent?.name == SearsCatalogNodeName.prepareItem }) {
            handleSearsCatalogPrepareOrder()
        } else if hudNodes.contains(where: { $0.name == SearsCatalogNodeName.cancelItem || $0.parent?.name == SearsCatalogNodeName.cancelItem }) {
            setSearsCatalogDialogVisible(false)
        } else if hudNodes.contains(where: { $0.name == SearsCatalogNodeName.raftToggleItem || $0.parent?.name == SearsCatalogNodeName.raftToggleItem }) {
            searsCatalogItemChecked.toggle()
            updateSearsCatalogCheckboxVisual()
        }

        return true
    }

    func handleSearsCatalogInteraction() {
        guard !isEnvelopeOutstanding() else {
            showMessage("You must mail your previous order before using the catalog again.")
            return
        }

        setMenuVisible(false)
        setStatusWindowVisible(false)
        setQuizDialogVisible(false)
        setStudySubjectPromptVisible(false)
        setSearsCatalogDialogVisible(true)
        setSearsCatalogAlertVisible(false)
        searsCatalogItemChecked = false
        updateSearsCatalogCheckboxVisual()
    }

    func handleSearsCatalogPrepareOrder() {
        guard searsCatalogItemChecked else {
            setSearsCatalogAlertVisible(true, message: "You haven't checked any items")
            return
        }

        let totalCost = searsCatalogRaftPriceCoins
        guard GameState.shared.coins >= totalCost else {
            setSearsCatalogAlertVisible(true, message: "You don't have enough coins")
            return
        }

        _ = GameState.shared.removeCoins(totalCost)
        updateCoinLabel()
        createEnvelopeAndCarry()
        setSearsCatalogDialogVisible(false)
        showMessage("Place the order by taking the envelope to the mailbox.")
        markSaveDirty()
    }

    func handleMailboxInteraction() {
        guard isEnvelopeCurrentlyCarried() else {
            showMessage("You must be carrying an envelope.")
            return
        }

        setEnvelopeCarried(false)
        hideEnvelopeAndResetHomePosition()
        showMessage("You have mailed the envelope.")
        markSaveDirty()
    }

    func handleEnvelopeInteraction() {
        guard isEnvelopeVisibleForPickup() else {
            return
        }

        if isEnvelopeCurrentlyCarried() {
            showMessage("You are already carrying the envelope.")
            return
        }

        setEnvelopeCarried(true)
        showMessage("Picked up envelope.")
        markSaveDirty()
    }
}
