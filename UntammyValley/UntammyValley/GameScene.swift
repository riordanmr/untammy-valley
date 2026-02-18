//
//  GameScene.swift
//  UntammyValley
//
//  Created by Mark Riordan on 2026-02-15 with help from Microsoft Copilot.

import SpriteKit
import GameplayKit
import UIKit

private enum PhysicsCategory {
    static let none: UInt32 = 0
    static let player: UInt32 = 1 << 0
    static let wall: UInt32 = 1 << 1
    static let interactable: UInt32 = 1 << 2
}

func makeBasicTileSet() -> SKTileSet {
    let tileSize = CGSize(width: 64, height: 64)
    
    // Helper to create a tile group from an asset name
    func makeTile(named name: String) -> SKTileGroup {
        let texture = SKTexture(imageNamed: name)
        let definition = SKTileDefinition(texture: texture, size: tileSize)
        let group = SKTileGroup(tileDefinition: definition)
        group.name = name
        return group
    }

    // Your new wood floor tile
    let wood = makeTile(named: "floor_wood")

    // Object tile (your wall)
    let wall = makeTile(named: "wall_vertical")

    // Return a tileset containing both tiles
    let tileSet = SKTileSet(tileGroups: [wood, wall])
    tileSet.defaultTileSize = tileSize
    return tileSet
}

class GameScene: SKScene {

    private enum DebugSettings {
        static let showRoomLabels = true
    }

    var player: PlayerNode!
    var cameraNode: SKCameraNode!

    private var coinLabel: SKLabelNode!
    private var messageLabel: SKLabelNode!
    private var menuButtonNode: SKShapeNode!
    private var menuPanelNode: SKShapeNode!
    private var menuResetLabel: SKLabelNode!
    private var interactableNodesByID: [String: SKSpriteNode] = [:]
    private var interactableConfigsByID: [String: InteractableConfig] = [:]
    private var respawnAtMoveByInteractableID: [String: Int] = [:]

    private var moveTarget: CGPoint?
    private var playerSpawnPosition: CGPoint = .zero
    private var completedMoveCount = 0
    private let worldConfig = WorldConfig.current

    private let worldColumns = 80
    private let worldRows = 60
    private let tileSize = CGSize(width: 64, height: 64)
    private let playerMoveSpeed: CGFloat = 320

    // This is called once per scene load.
    override func didMove(to view: SKView) {
        backgroundColor = .black
        physicsWorld.gravity = .zero

        // --- TILE MAP ---
        let tileSet = makeBasicTileSet()

        // Create ground layer
        let tileMap = SKTileMapNode(tileSet: tileSet,
                                    columns: worldColumns,
                                    rows: worldRows,
                                    tileSize: tileSize)

        // Center the tile map in world space
        tileMap.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        tileMap.position = .zero
        tileMap.zPosition = -10

        let woodGroup = tileSet.tileGroups[0]

        for col in 0..<worldColumns {
            for row in 0..<worldRows {
                tileMap.setTileGroup(woodGroup, forColumn: col, row: row)
            }
        }
        addChild(tileMap)
        
        // Second tile layer for walls, furniture, etc.
        let objectTileMap = SKTileMapNode(
            tileSet: tileSet,
            columns: worldColumns,
            rows: worldRows,
            tileSize: tileSize
        )
        objectTileMap.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        objectTileMap.position = .zero
        objectTileMap.zPosition = 10   // above the floor
        addChild(objectTileMap)
        
        guard let wallGroup = tileSet.tileGroups.first(where: { $0.name == "wall_vertical" }) else {
            print("Missing wall tile group")
            return
        }

        func placeWallTile(column: Int, row: Int) {
            objectTileMap.setTileGroup(wallGroup, forColumn: column, row: row)
            addWallCollider(forColumn: column, row: row, on: objectTileMap)
        }

        for wallTile in worldConfig.wallTiles {
            placeWallTile(column: wallTile.column, row: wallTile.row)
        }

        addDebugRoomLabelsIfNeeded(on: objectTileMap, labels: worldConfig.roomLabels)

        buildInteractables(on: objectTileMap)

        // --- PLAYER ---
        player = PlayerNode()
        // Spawn inside the bedroom
        let spawnColumn = worldConfig.spawnTile.column
        let spawnRow = worldConfig.spawnTile.row
        let spawnLocalCenter = objectTileMap.centerOfTile(atColumn: spawnColumn, row: spawnRow)
        playerSpawnPosition = objectTileMap.convert(spawnLocalCenter, to: self)
        player.position = playerSpawnPosition

        player.physicsBody?.categoryBitMask = PhysicsCategory.player
        player.physicsBody?.collisionBitMask = PhysicsCategory.wall
        player.physicsBody?.contactTestBitMask = PhysicsCategory.interactable
        addChild(player)

        // --- CAMERA ---
        cameraNode = SKCameraNode()
        camera = cameraNode
        addChild(cameraNode)

        // Make sure the camera starts on the player immediately
        cameraNode.position = player.position

        configureHUD()
        updateCoinLabel()
        showMessage("Tap to move. Tap interactables to perform tasks and earn coins.")

    }

    override func didSimulatePhysics() {
        cameraNode.position = player.position
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        let hudLocation = touch.location(in: cameraNode)

        let hudNodes = cameraNode.nodes(at: hudLocation)
        if hudNodes.contains(where: { $0.name == "hamburgerButton" || $0.parent?.name == "hamburgerButton" }) {
            setMenuVisible(menuPanelNode.isHidden)
            return
        }
        if hudNodes.contains(where: { $0.name == "menuResetItem" || $0.parent?.name == "menuResetItem" }) {
            resetGameToInitialState()
            setMenuVisible(false)
            return
        }
        if !menuPanelNode.isHidden {
            setMenuVisible(false)
            return
        }

        if let interactableID = interactableID(at: location) {
            moveTarget = nil
            player.physicsBody?.velocity = .zero
            performInteractionIfPossible(interactableID: interactableID)
            return
        }

        setMenuVisible(false)
        moveTarget = location
    }

    override func update(_ currentTime: TimeInterval) {
        guard let body = player.physicsBody else { return }
        guard let target = moveTarget else {
            body.velocity = .zero
            return
        }

        let dx = target.x - player.position.x
        let dy = target.y - player.position.y
        let distance = hypot(dx, dy)

        if distance < 12 {
            moveTarget = nil
            body.velocity = .zero
            completedMoveCount += 1
            processInteractableRespawns()
            return
        }

        let vx = (dx / distance) * playerMoveSpeed
        let vy = (dy / distance) * playerMoveSpeed
        body.velocity = CGVector(dx: vx, dy: vy)
    }

    private func addWallCollider(forColumn column: Int, row: Int, on tileMap: SKTileMapNode) {
        let localCenter = tileMap.centerOfTile(atColumn: column, row: row)
        let sceneCenter = tileMap.convert(localCenter, to: self)

        let wallCollider = SKNode()
        wallCollider.position = sceneCenter
        wallCollider.name = "wallCollider"

        let body = SKPhysicsBody(rectangleOf: tileMap.tileSize)
        body.isDynamic = false
        body.affectedByGravity = false
        body.friction = 0.0
        body.restitution = 0.0
        body.categoryBitMask = PhysicsCategory.wall
        body.collisionBitMask = PhysicsCategory.player
        body.contactTestBitMask = PhysicsCategory.none
        wallCollider.physicsBody = body

        addChild(wallCollider)
    }

    private func addDebugRoomLabelsIfNeeded(on tileMap: SKTileMapNode, labels: [(name: String, tile: TileCoordinate)]) {
        guard DebugSettings.showRoomLabels else { return }

        for label in labels {
            addDebugRoomLabel(label.name, atColumn: label.tile.column, row: label.tile.row, on: tileMap)
        }
    }

    private func addDebugRoomLabel(_ text: String, atColumn column: Int, row: Int, on tileMap: SKTileMapNode) {
        let localCenter = tileMap.centerOfTile(atColumn: column, row: row)
        let sceneCenter = tileMap.convert(localCenter, to: self)

        let label = SKLabelNode(fontNamed: "AvenirNext-Bold")
        label.text = text
        label.fontSize = 22
        label.fontColor = UIColor.white.withAlphaComponent(0.85)
        label.horizontalAlignmentMode = .center
        label.verticalAlignmentMode = .center
        label.position = sceneCenter
        label.zPosition = 30
        addChild(label)
    }

    private func buildInteractables(on tileMap: SKTileMapNode) {
        interactableNodesByID.removeAll()
        interactableConfigsByID.removeAll()

        for config in worldConfig.interactables {
            let center = tileMap.centerOfTile(atColumn: config.tile.column, row: config.tile.row)
            let position = tileMap.convert(center, to: self)

            let texture = SKTexture(imageNamed: config.spriteName)
            let node: SKSpriteNode
            if texture.size() == .zero {
                if config.kind == .chaseGoats {
                    let goatTexture = makeGoatMarkerTexture(size: config.size)
                    node = SKSpriteNode(texture: goatTexture, color: .clear, size: config.size)
                } else {
                    node = SKSpriteNode(color: .systemYellow, size: config.size)
                }
            } else {
                node = SKSpriteNode(texture: texture, color: .clear, size: config.size)
            }

            node.name = "interactable:\(config.id)"
            node.position = position
            node.zPosition = 20

            let body = SKPhysicsBody(rectangleOf: node.size)
            body.isDynamic = false
            body.categoryBitMask = PhysicsCategory.interactable
            body.collisionBitMask = PhysicsCategory.none
            body.contactTestBitMask = PhysicsCategory.player
            node.physicsBody = body

            addChild(node)
            interactableNodesByID[config.id] = node
            interactableConfigsByID[config.id] = config
        }
    }

    private func makeGoatMarkerTexture(size: CGSize) -> SKTexture {
        let image = UIGraphicsImageRenderer(size: size).image { _ in
            let markerRect = CGRect(origin: .zero, size: size)
            UIColor.systemGreen.withAlphaComponent(0.92).setFill()
            UIBezierPath(roundedRect: markerRect, cornerRadius: size.width * 0.22).fill()

            let emoji = "🐐" as NSString
            let fontSize = min(size.width, size.height) * 0.62
            let attributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: fontSize),
                .foregroundColor: UIColor.white
            ]

            let textSize = emoji.size(withAttributes: attributes)
            let textRect = CGRect(
                x: (size.width - textSize.width) / 2,
                y: (size.height - textSize.height) / 2 - 1,
                width: textSize.width,
                height: textSize.height
            )
            emoji.draw(in: textRect, withAttributes: attributes)
        }
        return SKTexture(image: image)
    }

    private func interactableID(at scenePoint: CGPoint) -> String? {
        for node in nodes(at: scenePoint) {
            if node.isHidden {
                continue
            }
            if let name = node.name, name.hasPrefix("interactable:") {
                return String(name.dropFirst("interactable:".count))
            }
        }
        return nil
    }

    private func processInteractableRespawns() {
        for (interactableID, respawnMove) in respawnAtMoveByInteractableID where completedMoveCount >= respawnMove {
            interactableNodesByID[interactableID]?.isHidden = false
            if interactableConfigsByID[interactableID]?.kind == .chaseGoats {
                showMessage("Goat returned to the parking lot.")
            }
            respawnAtMoveByInteractableID.removeValue(forKey: interactableID)
        }
    }

    private func configureHUD() {
        coinLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
        coinLabel.fontSize = 28
        coinLabel.fontColor = .white
        coinLabel.horizontalAlignmentMode = .left
        coinLabel.verticalAlignmentMode = .top
        coinLabel.position = CGPoint(x: -size.width / 2 + 20, y: size.height / 2 - 20)
        coinLabel.zPosition = 500
        cameraNode.addChild(coinLabel)

        messageLabel = SKLabelNode(fontNamed: "AvenirNext-Medium")
        messageLabel.fontSize = 20
        messageLabel.fontColor = .white
        messageLabel.horizontalAlignmentMode = .center
        messageLabel.verticalAlignmentMode = .top
        messageLabel.position = CGPoint(x: 0, y: size.height / 2 - 56)
        messageLabel.zPosition = 500
        messageLabel.alpha = 0
        cameraNode.addChild(messageLabel)

        configureMenu()
    }

    private func configureMenu() {
        let rightX = size.width / 2 - 20
        let topY = size.height / 2 - 20

        menuButtonNode = SKShapeNode(rectOf: CGSize(width: 36, height: 30), cornerRadius: 6)
        menuButtonNode.name = "hamburgerButton"
        menuButtonNode.fillColor = UIColor.darkGray.withAlphaComponent(0.65)
        menuButtonNode.strokeColor = .white
        menuButtonNode.lineWidth = 1.5
        menuButtonNode.position = CGPoint(x: rightX - 18, y: topY - 15)
        menuButtonNode.zPosition = 520
        cameraNode.addChild(menuButtonNode)

        for offset in [-6, 0, 6] {
            let line = SKShapeNode(rectOf: CGSize(width: 18, height: 2), cornerRadius: 1)
            line.fillColor = .white
            line.strokeColor = .clear
            line.position = CGPoint(x: 0, y: CGFloat(offset))
            line.name = "hamburgerLine"
            menuButtonNode.addChild(line)
        }

        menuPanelNode = SKShapeNode(rectOf: CGSize(width: 138, height: 52), cornerRadius: 9)
        menuPanelNode.name = "menuPanel"
        menuPanelNode.fillColor = UIColor.black.withAlphaComponent(0.6)
        menuPanelNode.strokeColor = .white
        menuPanelNode.lineWidth = 1.5
        menuPanelNode.position = CGPoint(x: rightX - 69, y: topY - 73)
        menuPanelNode.zPosition = 520
        menuPanelNode.isHidden = true
        cameraNode.addChild(menuPanelNode)

        menuResetLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
        menuResetLabel.name = "menuResetItem"
        menuResetLabel.text = "Reset"
        menuResetLabel.fontSize = 24
        menuResetLabel.fontColor = .white
        menuResetLabel.verticalAlignmentMode = .center
        menuResetLabel.horizontalAlignmentMode = .center
        menuResetLabel.position = .zero
        menuResetLabel.zPosition = 521
        menuPanelNode.addChild(menuResetLabel)
    }

    private func setMenuVisible(_ visible: Bool) {
        menuPanelNode.isHidden = !visible
        if visible {
            menuButtonNode.fillColor = UIColor.systemBlue.withAlphaComponent(0.65)
            menuButtonNode.strokeColor = .systemYellow
        } else {
            menuButtonNode.fillColor = UIColor.darkGray.withAlphaComponent(0.65)
            menuButtonNode.strokeColor = .white
        }
    }

    private func updateCoinLabel() {
        coinLabel.text = "Coins: \(GameState.shared.coins)"
    }

    private func performInteractionIfPossible(interactableID: String) {
        guard let config = interactableConfigsByID[interactableID],
              let node = interactableNodesByID[interactableID] else { return }

        let dx = node.position.x - player.position.x
        let dy = node.position.y - player.position.y
        let distance = hypot(dx, dy)

        if distance > config.interactionRange {
            showMessage("Move closer to interact.")
            return
        }

        let actionMessage: String
        switch config.kind {
        case .potatoChips:
            actionMessage = "Made potato chips!"
        case .chaseGoats:
            actionMessage = "Chased goats off cars!"
            node.isHidden = true
            let respawnAfterMoves = Int.random(in: 10...20)
            respawnAtMoveByInteractableID[interactableID] = completedMoveCount + respawnAfterMoves
        }

        GameState.shared.addCoins(config.rewardCoins)
        updateCoinLabel()
        showMessage("\(actionMessage) +\(config.rewardCoins) coins")
    }

    private func resetGameToInitialState() {
        moveTarget = nil
        player.physicsBody?.velocity = .zero
        player.position = playerSpawnPosition
        cameraNode.position = playerSpawnPosition
        completedMoveCount = 0
        respawnAtMoveByInteractableID.removeAll()
        for (_, interactableNode) in interactableNodesByID {
            interactableNode.isHidden = false
        }

        GameState.shared.resetCoins()
        updateCoinLabel()
        showMessage("Progress reset.")
    }

    private func showMessage(_ text: String) {
        messageLabel.removeAllActions()
        messageLabel.text = text
        messageLabel.alpha = 1
        let wait = SKAction.wait(forDuration: 1.2)
        let fade = SKAction.fadeOut(withDuration: 0.35)
        messageLabel.run(SKAction.sequence([wait, fade]))
    }
}
