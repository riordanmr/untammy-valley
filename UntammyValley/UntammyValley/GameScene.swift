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

    func makeFallbackTexture(for name: String) -> SKTexture {
        let image = UIGraphicsImageRenderer(size: tileSize).image { _ in
            let fillColor: UIColor
            if name.contains("wall") {
                fillColor = UIColor.darkGray
            } else if name.contains("outdoor") {
                fillColor = UIColor.systemGreen
            } else {
                fillColor = UIColor.brown
            }
            fillColor.setFill()
            UIBezierPath(rect: CGRect(origin: .zero, size: tileSize)).fill()
        }
        return SKTexture(image: image)
    }
    
    // Helper to create a tile group from an asset name
    func makeTile(named name: String) -> SKTileGroup {
        let texture: SKTexture
        if let image = UIImage(named: name) {
            texture = SKTexture(image: image)
        } else {
            texture = makeFallbackTexture(for: name)
        }
        let definition = SKTileDefinition(texture: texture, size: tileSize)
        let group = SKTileGroup(tileDefinition: definition)
        group.name = name
        return group
    }

    let tileNames = [
        "floor_wood",
        "floor_linoleum",
        "floor_carpet",
        "floor_outdoor",
        "wall_vertical"
    ]

    let groups = tileNames.map { makeTile(named: $0) }

    // Return a tileset containing all floor + wall tiles
    let tileSet = SKTileSet(tileGroups: groups)
    tileSet.defaultTileSize = tileSize
    return tileSet
}

class GameScene: SKScene {

    private enum DebugSettings {
        static let showRoomLabels = true
    }

    private enum BatEventSettings {
        static let spawnIntervalMoves = 44
        static let defeatDeadlineMoves = 22

        static var minSpawnIntervalMoves: Int {
            max(1, Int(round(Double(spawnIntervalMoves) * 0.5)))
        }

        static var maxSpawnIntervalMoves: Int {
            Int(round(Double(spawnIntervalMoves) * 1.5))
        }

        static func randomSpawnIntervalMoves() -> Int {
            Int.random(in: minSpawnIntervalMoves...maxSpawnIntervalMoves)
        }
    }

    var player: PlayerNode!
    var cameraNode: SKCameraNode!

    private var coinLabel: SKLabelNode!
    private var messageLabel: SKLabelNode!
    private var menuButtonNode: SKShapeNode!
    private var menuPanelNode: SKShapeNode!
    private var menuStatusLabel: SKLabelNode!
    private var menuResetLabel: SKLabelNode!
    private var statusBackdropNode: SKShapeNode!
    private var statusPanelNode: SKShapeNode!
    private var statusTitleLabel: SKLabelNode!
    private var statusScrollCropNode: SKCropNode!
    private var statusScrollContentNode: SKNode!
    private var statusDoneLabel: SKLabelNode!
    private var makerLoadedIndicatorNode: SKShapeNode?
    private var bucketSelectedIndicatorNode: SKShapeNode?
    private var interactableNodesByID: [String: SKSpriteNode] = [:]
    private var interactableConfigsByID: [String: InteractableConfig] = [:]
    private var interactableHomePositionByID: [String: CGPoint] = [:]
    private var respawnAtMoveByInteractableID: [String: Int] = [:]

    private let bucketID = "bucket"
    private let potatoBinID = "potatoBin"
    private let potatoMakerID = "potatoStation"
    private let spigotID = "spigot"
    private let tennisRacketID = "tennisRacket"
    private let bedroomBatID = "bedroomBat"
    private let bucketCapacity = 5

    private var isBucketCarried = false
    private var bucketPotatoCount = 0
    private var washedPotatoCount = 0
    private var selectedPotatoForLoading = false
    private var selectedPotatoIsWashed = false
    private var makerHasLoadedPotato = false
    private var isTennisRacketCarried = false
    private var nextBatSpawnMove = BatEventSettings.randomSpawnIntervalMoves()
    private var batDefeatDeadlineMove: Int?

    private var isStatusWindowVisible = false
    private var isDraggingStatusScroll = false
    private var lastStatusDragY: CGFloat = 0
    private var statusScrollOffset: CGFloat = 0
    private var statusScrollViewportHeight: CGFloat = 0
    private var statusScrollContentHeight: CGFloat = 0
    private var statusScrollViewportWidth: CGFloat = 0

    private var moveTarget: CGPoint?
    private var playerSpawnPosition: CGPoint = .zero
    private var completedMoveCount = 0
    private let worldConfig = WorldConfig.current

    private let worldColumns = 80
    private let worldRows = 60
    private let tileSize = CGSize(width: 64, height: 64)
    private let playerMoveSpeed: CGFloat = 500

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

        var tileGroupsByName: [String: SKTileGroup] = [:]
        for group in tileSet.tileGroups {
            if let name = group.name {
                tileGroupsByName[name] = group
            }
        }

        guard let fallbackFloorGroup = tileGroupsByName["floor_wood"] ?? tileSet.tileGroups.first else {
            print("Missing floor tile groups")
            return
        }

        let defaultFloorGroup = tileGroupsByName[worldConfig.defaultFloorTileName] ?? fallbackFloorGroup

        for col in 0..<worldColumns {
            for row in 0..<worldRows {
                tileMap.setTileGroup(defaultFloorGroup, forColumn: col, row: row)
            }
        }

        for floorRegion in worldConfig.floorRegions {
            guard let floorGroup = tileGroupsByName[floorRegion.tileName] else {
                print("Missing floor tile group: \(floorRegion.tileName)")
                continue
            }
            for col in floorRegion.region.minColumn..<floorRegion.region.maxColumnExclusive {
                for row in floorRegion.region.minRow..<floorRegion.region.maxRowExclusive {
                    tileMap.setTileGroup(floorGroup, forColumn: col, row: row)
                }
            }
        }

        for doorwayFloor in worldConfig.doorwayFloorOverrides {
            guard let floorGroup = tileGroupsByName[doorwayFloor.tileName] else {
                print("Missing doorway floor tile group: \(doorwayFloor.tileName)")
                continue
            }
            for col in doorwayFloor.region.minColumn..<doorwayFloor.region.maxColumnExclusive {
                for row in doorwayFloor.region.minRow..<doorwayFloor.region.maxRowExclusive {
                    tileMap.setTileGroup(floorGroup, forColumn: col, row: row)
                }
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

    }

    override func didSimulatePhysics() {
        if isBucketCarried, let bucketNode = interactableNodesByID[bucketID] {
            bucketNode.position = CGPoint(x: player.position.x + 22, y: player.position.y + 8)
        }
        if isTennisRacketCarried, let racketNode = interactableNodesByID[tennisRacketID] {
            racketNode.position = CGPoint(x: player.position.x - 24, y: player.position.y + 10)
        }
        if let bucketNode = interactableNodesByID[bucketID] {
            bucketSelectedIndicatorNode?.position = CGPoint(x: bucketNode.position.x, y: bucketNode.position.y + 22)
        }
        updateBucketSelectedIndicator()
        cameraNode.position = player.position
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        let hudLocation = touch.location(in: cameraNode)

        let hudNodes = cameraNode.nodes(at: hudLocation)

        if isStatusWindowVisible {
            isDraggingStatusScroll = false
            if hudNodes.contains(where: { $0.name == "statusDoneItem" || $0.parent?.name == "statusDoneItem" }) {
                setStatusWindowVisible(false)
            }
            return
        }

        if hudNodes.contains(where: { $0.name == "hamburgerButton" || $0.parent?.name == "hamburgerButton" }) {
            setMenuVisible(menuPanelNode.isHidden)
            return
        }
        if hudNodes.contains(where: { $0.name == "menuStatusItem" || $0.parent?.name == "menuStatusItem" }) {
            updateStatusWindowBody()
            setStatusWindowVisible(true)
            setMenuVisible(false)
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

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard isStatusWindowVisible, let touch = touches.first else { return }
        let hudLocation = touch.location(in: cameraNode)
        if statusScrollCropNode.contains(hudLocation) {
            isDraggingStatusScroll = true
            lastStatusDragY = hudLocation.y
        }
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard isStatusWindowVisible, isDraggingStatusScroll, let touch = touches.first else { return }
        let hudLocation = touch.location(in: cameraNode)
        let deltaY = hudLocation.y - lastStatusDragY
        lastStatusDragY = hudLocation.y
        setStatusScrollOffset(statusScrollOffset + deltaY)
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
        interactableHomePositionByID.removeAll()
        makerLoadedIndicatorNode?.removeFromParent()
        makerLoadedIndicatorNode = nil
        bucketSelectedIndicatorNode?.removeFromParent()
        bucketSelectedIndicatorNode = nil

        for config in worldConfig.interactables {
            let center = tileMap.centerOfTile(atColumn: config.tile.column, row: config.tile.row)
            let position = tileMap.convert(center, to: self)

            let node: SKSpriteNode
            if let image = UIImage(named: config.spriteName) {
                let texture = SKTexture(image: image)
                node = SKSpriteNode(texture: texture, color: .clear, size: config.size)
            } else {
                if config.kind == .chaseGoats {
                    let goatTexture = makeGoatMarkerTexture(size: config.size)
                    node = SKSpriteNode(texture: goatTexture, color: .clear, size: config.size)
                } else if config.kind == .potatoBin {
                    let binTexture = makeLabeledMarkerTexture(size: config.size, emoji: "🥔", color: .systemBrown)
                    node = SKSpriteNode(texture: binTexture, color: .clear, size: config.size)
                } else if config.kind == .bucket {
                    let bucketTexture = makeLabeledMarkerTexture(size: config.size, emoji: "🪣", color: .systemBlue)
                    node = SKSpriteNode(texture: bucketTexture, color: .clear, size: config.size)
                } else if config.kind == .spigot {
                    let spigotTexture = makeLabeledMarkerTexture(size: config.size, emoji: "🚰", color: .systemTeal)
                    node = SKSpriteNode(texture: spigotTexture, color: .clear, size: config.size)
                } else if config.kind == .tennisRacket {
                    let racketTexture = makeLabeledMarkerTexture(size: config.size, emoji: "🏸", color: .systemOrange)
                    node = SKSpriteNode(texture: racketTexture, color: .clear, size: config.size)
                } else if config.kind == .bedroomBat {
                    let batTexture = makeLabeledMarkerTexture(size: config.size, emoji: "🦇", color: .systemPurple)
                    node = SKSpriteNode(texture: batTexture, color: .clear, size: config.size)
                } else {
                    node = SKSpriteNode(color: .systemYellow, size: config.size)
                }
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
            interactableHomePositionByID[config.id] = position

            if config.id == bedroomBatID {
                node.isHidden = true
            }

            if config.id == potatoMakerID {
                let radius = max(node.size.width, node.size.height) * 0.62
                let indicator = SKShapeNode(circleOfRadius: radius)
                indicator.lineWidth = 4
                indicator.strokeColor = .systemYellow
                indicator.fillColor = .clear
                indicator.alpha = 0
                indicator.zPosition = node.zPosition + 1
                indicator.position = node.position
                addChild(indicator)
                makerLoadedIndicatorNode = indicator
            } else if config.id == bucketID {
                let indicator = SKShapeNode(circleOfRadius: 7)
                indicator.lineWidth = 2
                indicator.strokeColor = .white
                indicator.fillColor = .systemYellow
                indicator.alpha = 0
                indicator.zPosition = node.zPosition + 2
                indicator.position = CGPoint(x: node.position.x, y: node.position.y + 22)
                addChild(indicator)
                bucketSelectedIndicatorNode = indicator
            }
        }

        updateMakerLoadedIndicator()
        updateBucketSelectedIndicator()
    }

    private func makeGoatMarkerTexture(size: CGSize) -> SKTexture {
        makeLabeledMarkerTexture(size: size, emoji: "🐐", color: .systemGreen)
    }

    private func makeLabeledMarkerTexture(size: CGSize, emoji: String, color: UIColor) -> SKTexture {
        let image = UIGraphicsImageRenderer(size: size).image { _ in
            let markerRect = CGRect(origin: .zero, size: size)
            color.withAlphaComponent(0.92).setFill()
            UIBezierPath(roundedRect: markerRect, cornerRadius: size.width * 0.22).fill()

            let emojiText = emoji as NSString
            let fontSize = min(size.width, size.height) * 0.62
            let attributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: fontSize),
                .foregroundColor: UIColor.white
            ]

            let textSize = emojiText.size(withAttributes: attributes)
            let textRect = CGRect(
                x: (size.width - textSize.width) / 2,
                y: (size.height - textSize.height) / 2 - 1,
                width: textSize.width,
                height: textSize.height
            )
            emojiText.draw(in: textRect, withAttributes: attributes)
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

        if let batDeadline = batDefeatDeadlineMove,
           completedMoveCount >= batDeadline,
           let batNode = interactableNodesByID[bedroomBatID],
           !batNode.isHidden {
            let previousCoins = GameState.shared.coins
            let remainingCoins = GameState.shared.halveCoins()
            let lostCoins = previousCoins - remainingCoins
            batNode.isHidden = true
            batDefeatDeadlineMove = nil
            nextBatSpawnMove = completedMoveCount + BatEventSettings.randomSpawnIntervalMoves()
            updateCoinLabel()
            showMessage("Bat escaped. Exterminator called: -\(lostCoins) coins.")
        }

        if batDefeatDeadlineMove == nil,
           completedMoveCount >= nextBatSpawnMove,
           isPlayerInBarRooms(),
           let batNode = interactableNodesByID[bedroomBatID] {
            batNode.position = interactableHomePositionByID[bedroomBatID] ?? batNode.position
            batNode.isHidden = false
            batDefeatDeadlineMove = completedMoveCount + BatEventSettings.defeatDeadlineMoves
            showMessage("A bat appeared in the bedroom! Use the tennis racket within \(BatEventSettings.defeatDeadlineMoves) moves.")
        }
    }

    private func updateMakerLoadedIndicator() {
        guard let indicator = makerLoadedIndicatorNode,
              let makerNode = interactableNodesByID[potatoMakerID] else { return }

        indicator.position = makerNode.position
        indicator.alpha = makerHasLoadedPotato ? 1.0 : 0.0
    }

    private func updateBucketSelectedIndicator() {
        bucketSelectedIndicatorNode?.alpha = selectedPotatoForLoading ? 1.0 : 0.0
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
        configureStatusWindow()
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

        menuPanelNode = SKShapeNode(rectOf: CGSize(width: 150, height: 92), cornerRadius: 9)
        menuPanelNode.name = "menuPanel"
        menuPanelNode.fillColor = UIColor.black.withAlphaComponent(0.6)
        menuPanelNode.strokeColor = .white
        menuPanelNode.lineWidth = 1.5
        menuPanelNode.position = CGPoint(x: rightX - 75, y: topY - 95)
        menuPanelNode.zPosition = 520
        menuPanelNode.isHidden = true
        cameraNode.addChild(menuPanelNode)

        menuStatusLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
        menuStatusLabel.name = "menuStatusItem"
        menuStatusLabel.text = "Status"
        menuStatusLabel.fontSize = 23
        menuStatusLabel.fontColor = .white
        menuStatusLabel.verticalAlignmentMode = .center
        menuStatusLabel.horizontalAlignmentMode = .center
        menuStatusLabel.position = CGPoint(x: 0, y: 20)
        menuStatusLabel.zPosition = 521
        menuPanelNode.addChild(menuStatusLabel)

        menuResetLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
        menuResetLabel.name = "menuResetItem"
        menuResetLabel.text = "Reset"
        menuResetLabel.fontSize = 23
        menuResetLabel.fontColor = .white
        menuResetLabel.verticalAlignmentMode = .center
        menuResetLabel.horizontalAlignmentMode = .center
        menuResetLabel.position = CGPoint(x: 0, y: -22)
        menuResetLabel.zPosition = 521
        menuPanelNode.addChild(menuResetLabel)
    }

    private func configureStatusWindow() {
        let backdropSize = CGSize(width: size.width, height: size.height)
        statusBackdropNode = SKShapeNode(rectOf: backdropSize)
        statusBackdropNode.name = "statusBackdrop"
        statusBackdropNode.fillColor = UIColor.black.withAlphaComponent(0.45)
        statusBackdropNode.strokeColor = .clear
        statusBackdropNode.position = .zero
        statusBackdropNode.zPosition = 700
        statusBackdropNode.isHidden = true
        cameraNode.addChild(statusBackdropNode)

        statusPanelNode = SKShapeNode(rectOf: CGSize(width: min(size.width - 80, 560), height: 330), cornerRadius: 14)
        statusPanelNode.name = "statusPanel"
        statusPanelNode.fillColor = UIColor(white: 0.14, alpha: 0.97)
        statusPanelNode.strokeColor = .white
        statusPanelNode.lineWidth = 2
        statusPanelNode.position = .zero
        statusPanelNode.zPosition = 701
        statusPanelNode.isHidden = true
        cameraNode.addChild(statusPanelNode)

        statusTitleLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
        statusTitleLabel.text = "Status"
        statusTitleLabel.fontSize = 28
        statusTitleLabel.fontColor = .white
        statusTitleLabel.horizontalAlignmentMode = .center
        statusTitleLabel.verticalAlignmentMode = .center
        statusTitleLabel.position = CGPoint(x: 0, y: 142)
        statusTitleLabel.zPosition = 702
        statusPanelNode.addChild(statusTitleLabel)

        statusScrollViewportWidth = min(size.width - 130, 500)
        statusScrollViewportHeight = 196

        statusScrollCropNode = SKCropNode()
        statusScrollCropNode.position = CGPoint(x: 0, y: 12)
        statusScrollCropNode.zPosition = 702
        statusPanelNode.addChild(statusScrollCropNode)

        let scrollMask = SKSpriteNode(color: .white, size: CGSize(width: statusScrollViewportWidth, height: statusScrollViewportHeight))
        scrollMask.position = .zero
        statusScrollCropNode.maskNode = scrollMask

        statusScrollContentNode = SKNode()
        statusScrollCropNode.addChild(statusScrollContentNode)

        let doneButton = SKShapeNode(rectOf: CGSize(width: 120, height: 42), cornerRadius: 8)
        doneButton.name = "statusDoneItem"
        doneButton.fillColor = UIColor.systemBlue.withAlphaComponent(0.9)
        doneButton.strokeColor = .white
        doneButton.lineWidth = 1.5
        doneButton.position = CGPoint(x: 0, y: -124)
        doneButton.zPosition = 702
        statusPanelNode.addChild(doneButton)

        statusDoneLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
        statusDoneLabel.name = "statusDoneItem"
        statusDoneLabel.text = "Done"
        statusDoneLabel.fontSize = 22
        statusDoneLabel.fontColor = .white
        statusDoneLabel.horizontalAlignmentMode = .center
        statusDoneLabel.verticalAlignmentMode = .center
        statusDoneLabel.position = .zero
        statusDoneLabel.zPosition = 703
        doneButton.addChild(statusDoneLabel)
    }

    private func setStatusWindowVisible(_ visible: Bool) {
        isStatusWindowVisible = visible
        statusBackdropNode.isHidden = !visible
        statusPanelNode.isHidden = !visible
    }

    private func updateStatusWindowBody() {
        let goatRespawnText: String
        if let respawnMove = respawnAtMoveByInteractableID["goatChaseSpot"] {
            goatRespawnText = "In \(max(0, respawnMove - completedMoveCount)) moves"
        } else {
            goatRespawnText = "Active"
        }

        let batStatusText: String
        if let batDeadline = batDefeatDeadlineMove {
            batStatusText = "Defeat in \(max(0, batDeadline - completedMoveCount)) moves"
        } else {
            batStatusText = "Waiting (avg \(BatEventSettings.spawnIntervalMoves), range \(BatEventSettings.minSpawnIntervalMoves)-\(BatEventSettings.maxSpawnIntervalMoves))"
        }

        let statusLines = [
            "Coins: \(GameState.shared.coins)",
            "Moves: \(completedMoveCount)",
            "Bucket carried: \(isBucketCarried ? "Yes" : "No")",
            "Bucket potatoes: \(bucketPotatoCount)/\(bucketCapacity)",
            "Washed in bucket: \(washedPotatoCount)",
            "Potato selected: \(selectedPotatoForLoading ? "Yes" : "No")",
            "Maker loaded: \(makerHasLoadedPotato ? "Yes" : "No")",
            "Racket carried: \(isTennisRacketCarried ? "Yes" : "No")",
            "Bat event: \(batStatusText)",
            "Goat respawn: \(goatRespawnText)"
        ]

        renderStatusLines(statusLines)
    }

    private func renderStatusLines(_ lines: [String]) {
        statusScrollContentNode.removeAllChildren()

        let lineHeight: CGFloat = 24
        let topPadding: CGFloat = 8
        let bottomPadding: CGFloat = 8
        let textX = -statusScrollViewportWidth / 2 + 8
        let contentHeight = topPadding + bottomPadding + CGFloat(lines.count) * lineHeight
        statusScrollContentHeight = max(contentHeight, statusScrollViewportHeight)

        let topY = statusScrollContentHeight / 2 - topPadding
        for (index, lineText) in lines.enumerated() {
            let lineNode = SKLabelNode(fontNamed: "AvenirNext-Medium")
            lineNode.text = lineText
            lineNode.fontSize = 20
            lineNode.fontColor = .white
            lineNode.horizontalAlignmentMode = .left
            lineNode.verticalAlignmentMode = .top
            lineNode.position = CGPoint(x: textX, y: topY - CGFloat(index) * lineHeight)
            lineNode.zPosition = 702
            statusScrollContentNode.addChild(lineNode)
        }

        setStatusScrollOffset(statusScrollOffset)
    }

    private func setStatusScrollOffset(_ offset: CGFloat) {
        let maxOffset = max(0, statusScrollContentHeight - statusScrollViewportHeight)
        statusScrollOffset = min(max(0, offset), maxOffset)
        statusScrollContentNode.position = CGPoint(
            x: 0,
            y: (statusScrollViewportHeight - statusScrollContentHeight) / 2 + statusScrollOffset
        )
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

        switch config.kind {
        case .bucket:
            handleBucketInteraction(node: node)
            return
        case .potatoBin:
            handlePotatoBinInteraction()
            return
        case .spigot:
            handleSpigotInteraction()
            return
        case .potatoChips:
            handlePotatoMakerInteraction(config: config)
            return
        case .tennisRacket:
            handleTennisRacketInteraction(node: node)
            return
        case .bedroomBat:
            handleBedroomBatInteraction(node: node)
            return
        case .chaseGoats:
            node.isHidden = true
            let respawnAfterMoves = Int.random(in: 10...20)
            respawnAtMoveByInteractableID[interactableID] = completedMoveCount + respawnAfterMoves
            GameState.shared.addCoins(config.rewardCoins)
            updateCoinLabel()
            showMessage("Chased goats off cars! +\(config.rewardCoins) coins")
            return
        }
    }

    private func handleBucketInteraction(node: SKSpriteNode) {
        if !isBucketCarried {
            isBucketCarried = true
            showMessage("Picked up bucket (0/\(bucketCapacity)).")
            return
        }

        if selectedPotatoForLoading {
            selectedPotatoForLoading = false
            bucketPotatoCount = min(bucketCapacity, bucketPotatoCount + 1)
            if selectedPotatoIsWashed {
                washedPotatoCount = min(bucketPotatoCount, washedPotatoCount + 1)
            }
            selectedPotatoIsWashed = false
            showMessage("Returned selected potato to bucket (\(bucketPotatoCount)/\(bucketCapacity), washed \(washedPotatoCount)).")
            return
        }

        let nearMaker = isPlayerNearInteractable(withID: potatoMakerID)
        if nearMaker && bucketPotatoCount > 0 {
            guard washedPotatoCount > 0 else {
                showMessage("Potatoes must be washed at the spigot first.")
                return
            }
            if makerHasLoadedPotato {
                showMessage("Maker already loaded. Click maker to make chips.")
                return
            }
            bucketPotatoCount -= 1
            washedPotatoCount -= 1
            selectedPotatoForLoading = true
            selectedPotatoIsWashed = true
            showMessage("Selected washed potato (\(bucketPotatoCount)/\(bucketCapacity) left, washed \(washedPotatoCount)).")
            return
        }

        isBucketCarried = false
        node.position = player.position
        showMessage("Dropped bucket (\(bucketPotatoCount)/\(bucketCapacity)).")
    }

    private func handlePotatoBinInteraction() {
        guard isBucketCarried else {
            showMessage("Pick up the bucket first.")
            return
        }
        guard !selectedPotatoForLoading else {
            showMessage("Load or return selected potato first.")
            return
        }
        guard bucketPotatoCount < bucketCapacity else {
            showMessage("Bucket is full (\(bucketCapacity)/\(bucketCapacity)).")
            return
        }

        bucketPotatoCount += 1
        showMessage("Fetched potato from bin (\(bucketPotatoCount)/\(bucketCapacity), washed \(washedPotatoCount)).")
    }

    private func handleSpigotInteraction() {
        guard isBucketCarried else {
            showMessage("Pick up the bucket to wash potatoes.")
            return
        }
        guard !selectedPotatoForLoading else {
            showMessage("Load or return selected potato first.")
            return
        }
        guard bucketPotatoCount > 0 else {
            showMessage("Bucket is empty.")
            return
        }
        guard washedPotatoCount < bucketPotatoCount else {
            showMessage("All potatoes in bucket are already washed.")
            return
        }

        washedPotatoCount = bucketPotatoCount
        showMessage("Washed potatoes at spigot (washed \(washedPotatoCount)/\(bucketPotatoCount)).")
    }

    private func handlePotatoMakerInteraction(config: InteractableConfig) {
        if makerHasLoadedPotato {
            makerHasLoadedPotato = false
            GameState.shared.addCoins(config.rewardCoins)
            updateCoinLabel()
            updateMakerLoadedIndicator()
            showMessage("Made potato chips! +\(config.rewardCoins) coins")
            return
        }

        guard isBucketCarried else {
            showMessage("Bring the bucket to the chip maker.")
            return
        }

        if selectedPotatoForLoading {
            guard selectedPotatoIsWashed else {
                showMessage("Selected potato must be washed first.")
                return
            }
            selectedPotatoForLoading = false
            selectedPotatoIsWashed = false
            makerHasLoadedPotato = true
            updateMakerLoadedIndicator()
            showMessage("Loaded potato into chip maker.")
            return
        }

        showMessage("Select a potato from the bucket first.")
    }

    private func handleTennisRacketInteraction(node: SKSpriteNode) {
        if isTennisRacketCarried {
            isTennisRacketCarried = false
            node.position = player.position
            showMessage("Dropped tennis racket.")
            return
        }

        isTennisRacketCarried = true
        showMessage("Picked up tennis racket.")
    }

    private func handleBedroomBatInteraction(node: SKSpriteNode) {
        guard batDefeatDeadlineMove != nil, !node.isHidden else {
            showMessage("No bat to fight right now.")
            return
        }

        guard isTennisRacketCarried else {
            showMessage("Pick up the tennis racket first.")
            return
        }

        node.isHidden = true
        batDefeatDeadlineMove = nil
        nextBatSpawnMove = completedMoveCount + BatEventSettings.randomSpawnIntervalMoves()
        showMessage("You killed the bat.")
    }

    private func isPlayerNearInteractable(withID interactableID: String) -> Bool {
        guard let config = interactableConfigsByID[interactableID],
              let node = interactableNodesByID[interactableID] else { return false }
        let dx = node.position.x - player.position.x
        let dy = node.position.y - player.position.y
        return hypot(dx, dy) <= config.interactionRange
    }

    private func isPlayerInBarRooms() -> Bool {
        guard let playerTile = tileCoordinate(for: player.position) else { return false }
        return worldConfig.floorRegions.contains(where: { region in
            playerTile.column >= region.region.minColumn &&
            playerTile.column < region.region.maxColumnExclusive &&
            playerTile.row >= region.region.minRow &&
            playerTile.row < region.region.maxRowExclusive
        })
    }

    private func tileCoordinate(for scenePoint: CGPoint) -> TileCoordinate? {
        let worldOriginX = -CGFloat(worldColumns) * tileSize.width * 0.5
        let worldOriginY = -CGFloat(worldRows) * tileSize.height * 0.5

        let column = Int(floor((scenePoint.x - worldOriginX) / tileSize.width))
        let row = Int(floor((scenePoint.y - worldOriginY) / tileSize.height))

        guard column >= 0, column < worldColumns, row >= 0, row < worldRows else {
            return nil
        }

        return TileCoordinate(column: column, row: row)
    }

    private func resetGameToInitialState() {
        moveTarget = nil
        player.physicsBody?.velocity = .zero
        player.position = playerSpawnPosition
        cameraNode.position = playerSpawnPosition
        completedMoveCount = 0
        respawnAtMoveByInteractableID.removeAll()
        isBucketCarried = false
        bucketPotatoCount = 0
        washedPotatoCount = 0
        selectedPotatoForLoading = false
        selectedPotatoIsWashed = false
        makerHasLoadedPotato = false
        isTennisRacketCarried = false
        nextBatSpawnMove = BatEventSettings.randomSpawnIntervalMoves()
        batDefeatDeadlineMove = nil
        updateMakerLoadedIndicator()
        for (_, interactableNode) in interactableNodesByID {
            interactableNode.isHidden = false
        }
        for (id, homePosition) in interactableHomePositionByID {
            interactableNodesByID[id]?.position = homePosition
        }
        interactableNodesByID[bedroomBatID]?.isHidden = true

        GameState.shared.resetCoins()
        updateCoinLabel()
        updateStatusWindowBody()
        showMessage("Progress reset.")
    }

    private func showMessage(_ text: String) {
        messageLabel.removeAllActions()
        messageLabel.text = text
        messageLabel.alpha = 1
        let wait = SKAction.wait(forDuration: 2.8)
        let fade = SKAction.fadeOut(withDuration: 0.5)
        messageLabel.run(SKAction.sequence([wait, fade]))
    }
}
