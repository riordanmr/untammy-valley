//
//  SnowtankerBuildCoordinator.swift
//  UntammyValley
//

import CoreGraphics
import SpriteKit

struct SnowtankerBuildRequirementsStatus {
    let metLines: [String]
    let unmetLines: [String]

    var allRequirementsMet: Bool {
        unmetLines.isEmpty
    }
}

final class SnowtankerBuildCoordinator {
    struct NodeState {
        let position: CGPoint
        let isHidden: Bool
    }

    struct Scene1Plan {
        let snowmobileTargets: [CGPoint]
        let toolTargetsByID: [String: CGPoint]
        let moveDuration: TimeInterval
        let holdDuration: TimeInterval
    }

    func evaluateRequirements(
        requiredSnowmobileCount: Int,
        snowmobilesInAssemblyAreaCount: Int,
        isPropaneTankInAssemblyArea: Bool,
        isRadioInAssemblyArea: Bool,
        isCrescentWrenchInAssemblyArea: Bool,
        isRivetGunInAssemblyArea: Bool
    ) -> SnowtankerBuildRequirementsStatus {
        let requirements: [(String, Bool)] = [
            ("Propane tank is in vehicle assembly area", isPropaneTankInAssemblyArea),
            ("Radio is in vehicle assembly area", isRadioInAssemblyArea),
            ("Crescent wrench is in vehicle assembly area", isCrescentWrenchInAssemblyArea),
            ("Rivet gun is in vehicle assembly area", isRivetGunInAssemblyArea),
            (
                "All \(requiredSnowmobileCount) snowmobiles are in vehicle assembly area (\(snowmobilesInAssemblyAreaCount)/\(requiredSnowmobileCount))",
                snowmobilesInAssemblyAreaCount >= requiredSnowmobileCount
            )
        ]

        var metLines: [String] = []
        var unmetLines: [String] = []

        for (description, isMet) in requirements {
            if isMet {
                metLines.append("[x] \(description)")
            } else {
                unmetLines.append("[ ] \(description)")
            }
        }

        return SnowtankerBuildRequirementsStatus(metLines: metLines, unmetLines: unmetLines)
    }

    func makeScene1Plan(
        center: CGPoint,
        tileSize: CGSize,
        snowmobileCount: Int,
        propaneTankID: String,
        radioID: String,
        crescentWrenchID: String,
        rivetGunID: String
    ) -> Scene1Plan {
        let clampedSnowmobileCount = max(0, min(6, snowmobileCount))
        let columns = 3
        let horizontalSpacing = tileSize.width * 1.45
        let verticalSpacing = tileSize.height * 1.35

        var snowmobileTargets: [CGPoint] = []
        for index in 0..<clampedSnowmobileCount {
            let row = index / columns
            let column = index % columns
            let x = center.x + (CGFloat(column) - 1) * horizontalSpacing
            let y = center.y + (row == 0 ? verticalSpacing * 0.5 : -verticalSpacing * 0.5)
            snowmobileTargets.append(CGPoint(x: x, y: y))
        }

        let toolOffset = tileSize.width
        let toolTargetsByID: [String: CGPoint] = [
            crescentWrenchID: CGPoint(x: center.x - (horizontalSpacing + toolOffset), y: center.y),
            rivetGunID: CGPoint(x: center.x + (horizontalSpacing + toolOffset), y: center.y),
            propaneTankID: CGPoint(x: center.x - toolOffset, y: center.y - (verticalSpacing + toolOffset * 0.4)),
            radioID: CGPoint(x: center.x + toolOffset, y: center.y - (verticalSpacing + toolOffset * 0.4))
        ]

        return Scene1Plan(
            snowmobileTargets: snowmobileTargets,
            toolTargetsByID: toolTargetsByID,
            moveDuration: 0.55,
            holdDuration: 0.95
        )
    }

    func makeTemporarySprite(from sourceNode: SKSpriteNode) -> SKSpriteNode {
        let temporaryNode = SKSpriteNode(texture: sourceNode.texture, color: sourceNode.color, size: sourceNode.size)
        temporaryNode.position = sourceNode.position
        temporaryNode.zRotation = sourceNode.zRotation
        temporaryNode.alpha = sourceNode.alpha
        temporaryNode.colorBlendFactor = sourceNode.colorBlendFactor
        return temporaryNode
    }

    func makeAssemblyCenterTile(
        minColumn: Int,
        maxColumnExclusive: Int,
        minRow: Int,
        maxRowExclusive: Int
    ) -> TileCoordinate {
        TileCoordinate(
            column: (minColumn + maxColumnExclusive - 1) / 2,
            row: (minRow + maxRowExclusive - 1) / 2
        )
    }

    func makeSnowmobileIDs(configsByID: [String: InteractableConfig]) -> [String] {
        configsByID.compactMap { id, config in
            config.kind == .snowmobile ? id : nil
        }
    }

    func makeNodes(ids: [String], nodesByID: [String: SKSpriteNode]) -> [SKSpriteNode] {
        ids.compactMap { nodesByID[$0] }
    }

    func makeNodesByID(ids: [String], nodesByID: [String: SKSpriteNode]) -> [String: SKSpriteNode] {
        Dictionary(uniqueKeysWithValues: ids.compactMap { id in
            guard let node = nodesByID[id] else { return nil }
            return (id, node)
        })
    }

    func captureNodeStates(ids: [String], nodesByID: [String: SKSpriteNode]) -> [String: NodeState] {
        var states: [String: NodeState] = [:]
        for id in ids {
            guard let node = nodesByID[id] else { continue }
            states[id] = NodeState(position: node.position, isHidden: node.isHidden)
        }
        return states
    }

    func setHidden(_ hidden: Bool, ids: [String], nodesByID: [String: SKSpriteNode]) {
        for id in ids {
            nodesByID[id]?.isHidden = hidden
        }
    }

    func setHidden(_ hidden: Bool, nodes: [SKSpriteNode]) {
        for node in nodes {
            node.isHidden = hidden
        }
    }

    func restoreNodes(ids: [String], states: [String: NodeState], nodesByID: [String: SKSpriteNode]) {
        for id in ids {
            guard let state = states[id],
                  let node = nodesByID[id] else {
                continue
            }
            node.position = state.position
            node.isHidden = state.isHidden
        }
    }

    func makeConsumedIDs(snowmobileIDs: [String], propaneTankID: String, radioID: String) -> [String] {
        snowmobileIDs + [propaneTankID, radioID]
    }

    func makeScene1MontageNode(
        sceneSize: CGSize,
        cameraPosition: CGPoint,
        snowmobileNodes: [SKSpriteNode],
        toolNodesByID: [String: SKSpriteNode],
        plan: Scene1Plan,
        baseZPosition: CGFloat,
        overlayAlpha: CGFloat
    ) -> SKNode {
        let montageNode = SKNode()
        montageNode.name = "snowtankerBuildScene1Node"
        montageNode.zPosition = baseZPosition

        let overlayNode = SKSpriteNode(color: UIColor.black.withAlphaComponent(overlayAlpha), size: sceneSize)
        overlayNode.position = cameraPosition
        overlayNode.zPosition = -1
        montageNode.addChild(overlayNode)

        for (index, snowmobileNode) in snowmobileNodes.enumerated() {
            let temporaryNode = makeTemporarySprite(from: snowmobileNode)
            temporaryNode.zPosition = baseZPosition + 1
            montageNode.addChild(temporaryNode)
            if index < plan.snowmobileTargets.count {
                let moveAction = SKAction.move(to: plan.snowmobileTargets[index], duration: plan.moveDuration)
                moveAction.timingMode = .easeInEaseOut
                temporaryNode.run(moveAction)
            }
        }

        for (toolID, targetPosition) in plan.toolTargetsByID {
            guard let toolNode = toolNodesByID[toolID] else { continue }
            let temporaryNode = makeTemporarySprite(from: toolNode)
            temporaryNode.zPosition = baseZPosition + 1
            montageNode.addChild(temporaryNode)
            let moveAction = SKAction.move(to: targetPosition, duration: plan.moveDuration)
            moveAction.timingMode = .easeInEaseOut
            temporaryNode.run(moveAction)
        }

        return montageNode
    }
}
