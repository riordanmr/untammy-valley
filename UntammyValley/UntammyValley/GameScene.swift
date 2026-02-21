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
        // Note: This is a global function, so we can't access instance cache directly.
        // Fallback textures are created once per tile set and reused, so this is less critical.
        let image = UIGraphicsImageRenderer(size: tileSize).image { _ in
            let fillColor: UIColor
            if name.contains("wall") {
                fillColor = UIColor.darkGray
            } else if name.contains("trench") {
                fillColor = UIColor.brown
            } else if name.contains("septic") {
                fillColor = UIColor(red: 0.78, green: 0.63, blue: 0.44, alpha: 1.0)
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
        let candidateTexture = SKTexture(imageNamed: name)
        let texture = candidateTexture.size() == .zero
            ? makeFallbackTexture(for: name)
            : candidateTexture
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
        "floor_carroll_sales",
        "septic_cover",
        "septic_trench",
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
        static var spawnIntervalMoves: Int {
            (minSpawnIntervalMoves + maxSpawnIntervalMoves) / 2
        }

        static var defeatDeadlineMoves: Int {
            UTSettings.shared.counts.batDefeatDeadlineMoves
        }

        static var minSpawnIntervalMoves: Int {
            UTSettings.shared.counts.batSpawnMinMoves
        }

        static var maxSpawnIntervalMoves: Int {
            UTSettings.shared.counts.batSpawnMaxMoves
        }

        static func randomSpawnIntervalMoves() -> Int {
            Int.random(in: minSpawnIntervalMoves...maxSpawnIntervalMoves)
        }
    }

    private enum ToiletEventSettings {
        static var dirtyIntervalMoves: Int {
            UTSettings.shared.counts.toiletDirtyIntervalMoves
        }

        static var cleanDeadlineMoves: Int {
            UTSettings.shared.counts.toiletCleanDeadlineMoves
        }

        static var cleanRewardCoins: Int {
            UTSettings.shared.counts.toiletCleanRewardCoins
        }

        static var overduePenaltyCoinsPerMove: Int {
            UTSettings.shared.counts.toiletOverduePenaltyCoinsPerMove
        }

        static var minDirtyIntervalMoves: Int {
            max(1, Int(round(Double(dirtyIntervalMoves) * 0.5)))
        }

        static var maxDirtyIntervalMoves: Int {
            Int(round(Double(dirtyIntervalMoves) * 1.5))
        }

        static func randomDirtyIntervalMoves() -> Int {
            Int.random(in: minDirtyIntervalMoves...maxDirtyIntervalMoves)
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
    private var menuMove20Label: SKLabelNode!
    private var menuMapLabel: SKLabelNode!
    private var mapCloseButtonNode: SKShapeNode!
    private var mapCloseLabel: SKLabelNode!
    private var settingsDialogNode: SettingsDialogNode!
    private var studySubjectBackdropNode: SKShapeNode!
    private var studySubjectPanelNode: SKShapeNode!
    private var studyBackgroundBackdropNode: SKShapeNode!
    private var studyBackgroundPanelNode: SKShapeNode!
    private var studyBackgroundTitleLabel: SKLabelNode!
    private var studyBackgroundScrollCropNode: SKCropNode!
    private var studyBackgroundScrollContentNode: SKNode!
    private var studyBackgroundScrollTrackNode: SKShapeNode!
    private var studyBackgroundScrollThumbNode: SKShapeNode!
    private var studyBackgroundDoneButtonNode: SKShapeNode!
    private var snowmobileChoiceBackdropNode: SKShapeNode!
    private var snowmobileChoicePanelNode: SKShapeNode!
    private var snowmobileChoiceSubtitleLabel: SKLabelNode!
    private var pendingLotSnowmobileID: String?
    private var warningIconContainerNode: SKNode!
    private var warningBatIconNode: SKSpriteNode!
    private var warningToiletIconNode: SKSpriteNode!
    private var statusBackdropNode: SKShapeNode!
    private var statusPanelNode: SKShapeNode!
    private var statusTitleLabel: SKLabelNode!
    private var statusScrollCropNode: SKCropNode!
    private var statusScrollContentNode: SKNode!
    private var statusScrollTrackNode: SKShapeNode!
    private var statusScrollThumbNode: SKShapeNode!
    private var statusDoneLabel: SKLabelNode!
    private var makerLoadedIndicatorNode: SKShapeNode?
    private var bucketSelectedIndicatorNode: SKShapeNode?
    private var groundTileMap: SKTileMapNode?
    private var tileGroupsByName: [String: SKTileGroup] = [:]
    private var cachedTexturesByName: [String: SKTexture] = [:]
    private var cachedDynamicTextures: [String: SKTexture] = [:]
    private var interactableNodesByID: [String: SKSpriteNode] = [:]
    private var interactableConfigsByID: [String: InteractableConfig] = [:]
    private var interactableHomePositionByID: [String: CGPoint] = [:]
    private var snowmobileBadgeNodesByID: [String: SKNode] = [:]
    private var decorationNodesByID: [String: SKSpriteNode] = [:]
    private var respawnAtMoveByInteractableID: [String: Int] = [:]

    private let bucketID = "bucket"
    private let potatoBinID = "potatoBin"
    private let potatoPeelerID = "potatoPeeler"
    private let deepFryerID = "deepFryer"
    private let chipsBasketID = "chipsBasket"
    private let spigotID = "spigot"
    private let toiletID = "toilet"
    private let deskID = "desk"
    private let toiletCleanSpriteName = "toilet"
    private let toiletDirtySpriteName = "toilet_dirty"
    private let toiletBowlBrushID = "toiletBowlBrush"
    private let tennisRacketID = "tennisRacket"
    private let bedroomBatID = "bedroomBat"
    private let shovelID = "shovel"
    private let bucketCapacity = 5

    private var snowmobilePriceCoins: Int {
        UTSettings.shared.counts.snowmobilePriceCoins
    }

    private var coinsPerTrenchTile: Int {
        UTSettings.shared.counts.septicTrenchTileRewardCoins
    }

    private var septicCompletionBonusCoins: Int {
        UTSettings.shared.counts.septicCompletionBonusCoins
    }

    private var potatoChipRewardPerPotato: Int {
        UTSettings.shared.counts.potatoChipRewardPerPotato
    }

    private var goatChaseRewardCoins: Int {
        UTSettings.shared.counts.goatChaseRewardCoins
    }

    private var batEscapePenaltyMaxCoins: Int {
        UTSettings.shared.counts.batEscapePenaltyMaxCoins
    }

    private var isBucketCarried = false
    private var bucketPotatoCount = 0
    private var washedPotatoCount = 0
    private var selectedPotatoForLoading = false
    private var selectedPotatoIsWashed = false
    private var peelerHasSlicedPotatoes = false
    private var fryerSlicedPotatoCount = 0
    private var isChipsBasketCarried = false
    private var basketSlicedPotatoCount = 0
    private var chipsBasketContainsChips = false
    private var isToiletBowlBrushCarried = false
    private var isToiletDirty = false
    private var toiletCleanDeadlineMove: Int?
    private var nextToiletDirtyMove = ToiletEventSettings.randomDirtyIntervalMoves()
    private var hasShownToiletPenaltyStartMessage = false
    private var isTennisRacketCarried = false
    private var isShovelCarried = false
    private var ownedSnowmobileIDs: Set<String> = []
    private var selectedOwnedSnowmobileID: String?
    private var mountedSnowmobileID: String?
    private var nextBatSpawnMove = BatEventSettings.randomSpawnIntervalMoves()
    private var batDefeatDeadlineMove: Int?
    private var trenchedSepticTiles: Set<TileCoordinate> = []
    private var hasAwardedSepticCompletionBonus = false
    private var toiletCleanTexture: SKTexture?
    private var toiletDirtyTexture: SKTexture?

    private var isStatusWindowVisible = false
    private var isStudySubjectPromptVisible = false
    private var isStudyBackgroundWindowVisible = false
    private var isDraggingStudyBackgroundScroll = false
    private var lastStudyBackgroundDragY: CGFloat = 0
    private var studyBackgroundScrollOffset: CGFloat = 0
    private var studyBackgroundScrollViewportHeight: CGFloat = 0
    private var studyBackgroundScrollContentHeight: CGFloat = 0
    private var studyBackgroundScrollViewportWidth: CGFloat = 0
    private var isDraggingStatusScroll = false
    private var lastStatusDragY: CGFloat = 0
    private var statusScrollOffset: CGFloat = 0
    private var statusScrollViewportHeight: CGFloat = 0
    private var statusScrollContentHeight: CGFloat = 0
    private var statusScrollViewportWidth: CGFloat = 0
    private var isMapViewMode = false
    private var isDraggingMap = false
    private var lastMapDragPoint = CGPoint.zero
    private var mapModeSavedCameraPosition = CGPoint.zero
    private var mapModeSavedCameraScale: CGFloat = 1
    private let mapViewZoomOutScale: CGFloat = 2.5

    private var moveTarget: CGPoint?
    private var playerSpawnPosition: CGPoint = .zero
    private var completedMoveCount = 0
    private let worldConfig = WorldConfig.current

    private let worldColumns = 104
    private let worldRows = 46
    private let tileSize = CGSize(width: 64, height: 64)
    private let playerMoveSpeed: CGFloat = 500
    private let mountedSnowmobileSpeedMultiplier: CGFloat = 3.0
    private let mountedSnowmobileVerticalOffset: CGFloat = -12
    private let indoorSnowmobileBlockedFloorTiles: Set<String> = ["floor_wood", "floor_linoleum", "floor_carpet"]

    override func willMove(from view: SKView) {
        // Clean up resources when scene is removed
        cachedTexturesByName.removeAll()
        cachedDynamicTextures.removeAll()
        tileGroupsByName.removeAll()
        interactableNodesByID.removeAll()
        interactableConfigsByID.removeAll()
        interactableHomePositionByID.removeAll()
        snowmobileBadgeNodesByID.removeAll()
        decorationNodesByID.removeAll()
        respawnAtMoveByInteractableID.removeAll()
        groundTileMap = nil
        toiletCleanTexture = nil
        toiletDirtyTexture = nil
    }
    
    // This is called once per scene load.
    override func didMove(to view: SKView) {
        backgroundColor = .black
        physicsWorld.gravity = .zero
        toiletCleanTexture = loadTexture(named: toiletCleanSpriteName)
        toiletDirtyTexture = loadTexture(named: toiletDirtySpriteName)

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
        groundTileMap = tileMap

        tileGroupsByName = [:]
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

        buildDecorations(on: objectTileMap)
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
        updateStatusWindowBody()

    }

    override func didSimulatePhysics() {
        if let mountedID = mountedSnowmobileID,
           let snowmobileNode = interactableNodesByID[mountedID] {
            snowmobileNode.position = CGPoint(
                x: player.position.x,
                y: player.position.y + mountedSnowmobileVerticalOffset
            )
            snowmobileNode.zPosition = 20
            player.zPosition = 21
        }
        if isBucketCarried, let bucketNode = interactableNodesByID[bucketID] {
            bucketNode.position = CGPoint(x: player.position.x + 22, y: player.position.y + 8)
        }
        if isChipsBasketCarried, let basketNode = interactableNodesByID[chipsBasketID] {
            basketNode.position = CGPoint(x: player.position.x - 24, y: player.position.y - 8)
        }
        if isTennisRacketCarried, let racketNode = interactableNodesByID[tennisRacketID] {
            racketNode.position = CGPoint(x: player.position.x - 24, y: player.position.y + 10)
        }
        if isToiletBowlBrushCarried, let brushNode = interactableNodesByID[toiletBowlBrushID] {
            brushNode.position = CGPoint(x: player.position.x + 24, y: player.position.y + 10)
        }
        if isShovelCarried, let shovelNode = interactableNodesByID[shovelID] {
            shovelNode.position = CGPoint(x: player.position.x + 2, y: player.position.y - 24)
        }
        if let bucketNode = interactableNodesByID[bucketID] {
            bucketSelectedIndicatorNode?.position = CGPoint(x: bucketNode.position.x, y: bucketNode.position.y + 22)
        }
        updateWarningIcons()
        updateSnowmobileOwnershipVisuals()
        updateBucketSelectedIndicator()
        if !isMapViewMode {
            cameraNode.position = player.position
        }
    }

    override func didChangeSize(_ oldSize: CGSize) {
        super.didChangeSize(oldSize)
        updateWarningIconContainerPosition()
        updateMapCloseButtonPosition()
        settingsDialogNode?.updateLayout(sceneSize: size)
        updateStudyUILayouts()
        if isMapViewMode {
            clampCameraPositionToWorldBounds()
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        let hudLocation = touch.location(in: cameraNode)

        let hudNodes = cameraNode.nodes(at: hudLocation)

        if isMapViewMode {
            isDraggingMap = false
            if hudNodes.contains(where: { $0.name == "mapCloseItem" || $0.parent?.name == "mapCloseItem" }) {
                setMapViewMode(false)
            }
            return
        }

        if settingsDialogNode?.isVisible == true {
            if settingsDialogNode.endDrag() {
                return
            }
            _ = settingsDialogNode.handleTap(hudNodes: hudNodes)
            return
        }

        if isStudySubjectPromptVisible {
            if hudNodes.contains(where: { $0.name == "studySubjectUSHistItem" || $0.parent?.name == "studySubjectUSHistItem" }) {
                openStudyBackgroundWindow(for: "US History")
            } else if hudNodes.contains(where: { $0.name == "studySubjectEnglishItem" || $0.parent?.name == "studySubjectEnglishItem" }) {
                openStudyBackgroundWindow(for: "English")
            } else if hudNodes.contains(where: { $0.name == "studySubjectScienceItem" || $0.parent?.name == "studySubjectScienceItem" }) {
                openStudyBackgroundWindow(for: "Science")
            } else {
                setStudySubjectPromptVisible(false)
            }
            return
        }

        if isStudyBackgroundWindowVisible {
            if hudNodes.contains(where: { $0.name == "studyBackgroundDoneItem" || $0.parent?.name == "studyBackgroundDoneItem" }) {
                setStudyBackgroundWindowVisible(false)
                isDraggingStudyBackgroundScroll = false
                return
            }
            if endStudyBackgroundDrag() {
                return
            }
            return
        }

        if !snowmobileChoicePanelNode.isHidden {
            if hudNodes.contains(where: { $0.name == "snowmobileChoiceMountItem" || $0.parent?.name == "snowmobileChoiceMountItem" }) {
                handleLotOwnedSnowmobileMountChoice()
            } else if hudNodes.contains(where: { $0.name == "snowmobileChoiceSellItem" || $0.parent?.name == "snowmobileChoiceSellItem" }) {
                handleLotOwnedSnowmobileSellChoice()
            } else {
                setSnowmobileChoiceDialogVisible(false)
            }
            return
        }

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
        if hudNodes.contains(where: { $0.name == "menuMove20Item" || $0.parent?.name == "menuMove20Item" }) {
            simulateMoves(20)
            setMenuVisible(false)
            return
        }
        if hudNodes.contains(where: { $0.name == "menuMapItem" || $0.parent?.name == "menuMapItem" }) {
            setMapViewMode(true)
            setMenuVisible(false)
            return
        }
        if hudNodes.contains(where: { $0.name == "menuSettingsItem" || $0.parent?.name == "menuSettingsItem" }) {
            settingsDialogNode.setVisible(true)
            setMenuVisible(false)
            return
        }
        if !menuPanelNode.isHidden {
            setMenuVisible(false)
            return
        }

        if handleSepticDigTap(at: location) {
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
        guard let touch = touches.first else { return }
        let hudLocation = touch.location(in: cameraNode)

        if settingsDialogNode?.isVisible == true {
            settingsDialogNode.beginDrag(at: hudLocation)
            return
        }

        if isStudySubjectPromptVisible {
            return
        }

        if isStudyBackgroundWindowVisible {
            if studyBackgroundScrollCropNode.contains(hudLocation) {
                isDraggingStudyBackgroundScroll = true
                lastStudyBackgroundDragY = hudLocation.y
            }
            return
        }

        if isMapViewMode {
            isDraggingMap = true
            lastMapDragPoint = hudLocation
            return
        }
        guard isStatusWindowVisible else { return }
        if statusScrollCropNode.contains(hudLocation) {
            isDraggingStatusScroll = true
            lastStatusDragY = hudLocation.y
        }
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let hudLocation = touch.location(in: cameraNode)

        if settingsDialogNode?.isVisible == true {
            _ = settingsDialogNode.drag(to: hudLocation)
            return
        }

        if isStudySubjectPromptVisible {
            return
        }

        if isStudyBackgroundWindowVisible, isDraggingStudyBackgroundScroll {
            let deltaY = hudLocation.y - lastStudyBackgroundDragY
            lastStudyBackgroundDragY = hudLocation.y
            setStudyBackgroundScrollOffset(studyBackgroundScrollOffset + deltaY)
            return
        }

        if isMapViewMode, isDraggingMap {
            let deltaX = hudLocation.x - lastMapDragPoint.x
            let deltaY = hudLocation.y - lastMapDragPoint.y
            lastMapDragPoint = hudLocation

            cameraNode.position = CGPoint(
                x: cameraNode.position.x - deltaX * cameraNode.xScale,
                y: cameraNode.position.y - deltaY * cameraNode.yScale
            )
            clampCameraPositionToWorldBounds()
            return
        }

        guard isStatusWindowVisible, isDraggingStatusScroll else { return }
        let deltaY = hudLocation.y - lastStatusDragY
        lastStatusDragY = hudLocation.y
        setStatusScrollOffset(statusScrollOffset + deltaY)
    }

    override func update(_ currentTime: TimeInterval) {
        guard let body = player.physicsBody else { return }
        if isMapViewMode {
            body.velocity = .zero
            return
        }
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

        let moveSpeed = mountedSnowmobileID == nil
            ? playerMoveSpeed
            : playerMoveSpeed * mountedSnowmobileSpeedMultiplier
        let vx = (dx / distance) * moveSpeed
        let vy = (dy / distance) * moveSpeed

        if mountedSnowmobileID != nil {
            let probeDistance = min(distance, max(12, tileSize.width * 0.35))
            let nextProbePoint = CGPoint(
                x: player.position.x + (dx / distance) * probeDistance,
                y: player.position.y + (dy / distance) * probeDistance
            )

            guard isSnowmobileDrivable(at: nextProbePoint) else {
                moveTarget = nil
                body.velocity = .zero
                showMessage("Snowmobiles cannot go inside buildings.")
                return
            }
        }

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
        snowmobileBadgeNodesByID.removeAll()
        makerLoadedIndicatorNode?.removeFromParent()
        makerLoadedIndicatorNode = nil
        bucketSelectedIndicatorNode?.removeFromParent()
        bucketSelectedIndicatorNode = nil

        for config in worldConfig.interactables {
            let center = tileMap.centerOfTile(atColumn: config.tile.column, row: config.tile.row)
            let position = tileMap.convert(center, to: self)

            let node: SKSpriteNode
            if let texture = loadTexture(named: config.spriteName) {
                node = SKSpriteNode(texture: texture, color: .clear, size: config.size)
            } else {
                if config.kind == .chaseGoats {
                    let goatTexture = makeGoatMarkerTexture(size: config.size)
                    node = SKSpriteNode(texture: goatTexture, color: .clear, size: config.size)
                } else if config.kind == .deepFryer {
                    let fryerTexture = makeLabeledMarkerTexture(size: config.size, emoji: "F", color: .darkGray)
                    node = SKSpriteNode(texture: fryerTexture, color: .clear, size: config.size)
                } else if config.kind == .chipsBasket {
                    let basketTexture = makeLabeledMarkerTexture(size: config.size, emoji: "B", color: .systemOrange)
                    node = SKSpriteNode(texture: basketTexture, color: .clear, size: config.size)
                } else if config.kind == .snowmobile {
                    let snowmobileTexture = makeLabeledMarkerTexture(size: config.size, emoji: "S", color: .systemTeal)
                    node = SKSpriteNode(texture: snowmobileTexture, color: .clear, size: config.size)
                } else if config.kind == .toilet {
                    let toiletTexture = makeLabeledMarkerTexture(size: config.size, emoji: "T", color: .white)
                    node = SKSpriteNode(texture: toiletTexture, color: .clear, size: config.size)
                } else if config.kind == .desk {
                    let deskTexture = makeLabeledMarkerTexture(size: config.size, emoji: "D", color: .systemBrown)
                    node = SKSpriteNode(texture: deskTexture, color: .clear, size: config.size)
                } else if config.kind == .toiletBowlBrush {
                    let brushTexture = makeLabeledMarkerTexture(size: config.size, emoji: "B", color: .systemPink)
                    node = SKSpriteNode(texture: brushTexture, color: .clear, size: config.size)
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
                } else if config.kind == .shovel {
                    let shovelTexture = makeLabeledMarkerTexture(size: config.size, emoji: "S", color: .systemGray)
                    node = SKSpriteNode(texture: shovelTexture, color: .clear, size: config.size)
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

            if config.kind == .snowmobile {
                let badge = SKShapeNode(circleOfRadius: 10)
                badge.fillColor = .systemYellow
                badge.strokeColor = .white
                badge.lineWidth = 1.5
                badge.position = CGPoint(x: node.size.width * 0.33, y: node.size.height * 0.33)
                badge.zPosition = 3
                badge.isHidden = true

                let badgeLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
                badgeLabel.text = "$"
                badgeLabel.fontSize = 14
                badgeLabel.fontColor = .white
                badgeLabel.horizontalAlignmentMode = .center
                badgeLabel.verticalAlignmentMode = .center
                badgeLabel.position = CGPoint(x: 0, y: -1)
                badgeLabel.zPosition = 4
                badge.addChild(badgeLabel)

                node.addChild(badge)
                snowmobileBadgeNodesByID[config.id] = badge
            }

            if config.id == potatoPeelerID {
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

        updateToiletVisualState()
        updateSnowmobileOwnershipVisuals()

        updateMakerLoadedIndicator()
        updateBucketSelectedIndicator()
    }

    private func updateSnowmobileOwnershipVisuals() {
        for (id, config) in interactableConfigsByID where config.kind == .snowmobile {
            let owned = ownedSnowmobileIDs.contains(id)

            if let badgeNode = snowmobileBadgeNodesByID[id] as? SKShapeNode {
                badgeNode.isHidden = owned
                badgeNode.fillColor = .systemYellow
            }
        }
    }

    private func buildDecorations(on tileMap: SKTileMapNode) {
        decorationNodesByID.removeAll()

        for config in worldConfig.decorations {
            let center = tileMap.centerOfTile(atColumn: config.tile.column, row: config.tile.row)
            let position = tileMap.convert(center, to: self)

            let node: SKSpriteNode
            // For large text signs, use the dynamic texture path (cached by makeLargeSignTexture) since we have the text content
            if config.kind == .largeTextSign {
                let signTexture = makeLargeSignTexture(size: config.size, text: config.labelText ?? "Sign")
                node = SKSpriteNode(texture: signTexture, color: .clear, size: config.size)
            } else if let texture = loadTexture(named: config.spriteName), texture.size().width > 0, texture.size().height > 0 {
                node = SKSpriteNode(texture: texture, color: .clear, size: config.size)
            } else {
                // Fallback to dynamic texture generation when asset is missing
                let fallbackTexture = makeLabeledMarkerTexture(size: config.size, emoji: "?", color: .systemGray)
                node = SKSpriteNode(texture: fallbackTexture, color: .clear, size: config.size)
            }

            node.name = "decoration:\(config.id)"
            node.position = position
            node.zPosition = 18

            if config.blocksMovement {
                let body = SKPhysicsBody(rectangleOf: node.size)
                body.isDynamic = false
                body.categoryBitMask = PhysicsCategory.wall
                body.collisionBitMask = PhysicsCategory.player
                body.contactTestBitMask = PhysicsCategory.none
                node.physicsBody = body
            }

            addChild(node)
            decorationNodesByID[config.id] = node
        }
    }

    private func makeGoatMarkerTexture(size: CGSize) -> SKTexture {
        makeLabeledMarkerTexture(size: size, emoji: "🐐", color: .systemGreen)
    }

    private func makeLargeSignTexture(size: CGSize, text: String) -> SKTexture {
        // Cache sign textures by size and text content
        let cacheKey = "sign_\(Int(size.width))x\(Int(size.height))_\(text)"
        
        if let cached = cachedDynamicTextures[cacheKey] {
            return cached
        }
        
        let image = UIGraphicsImageRenderer(size: size).image { _ in
            let outerRect = CGRect(origin: .zero, size: size)
            UIColor(red: 0.18, green: 0.12, blue: 0.05, alpha: 0.95).setFill()
            UIBezierPath(roundedRect: outerRect, cornerRadius: size.height * 0.12).fill()

            let innerInset = max(6, min(size.width, size.height) * 0.06)
            let innerRect = outerRect.insetBy(dx: innerInset, dy: innerInset)
            UIColor(red: 0.95, green: 0.86, blue: 0.62, alpha: 1.0).setFill()
            UIBezierPath(roundedRect: innerRect, cornerRadius: size.height * 0.09).fill()

            let paragraph = NSMutableParagraphStyle()
            paragraph.alignment = .center
            paragraph.lineBreakMode = .byWordWrapping

            let fontSize = min(size.width * 0.13, size.height * 0.28)
            let attributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.boldSystemFont(ofSize: fontSize),
                .foregroundColor: UIColor(red: 0.20, green: 0.12, blue: 0.05, alpha: 1.0),
                .paragraphStyle: paragraph
            ]

            let textRect = innerRect.insetBy(dx: innerInset, dy: innerInset * 0.8)
            (text as NSString).draw(in: textRect, withAttributes: attributes)
        }

        let texture = SKTexture(image: image)
        cachedDynamicTextures[cacheKey] = texture
        return texture
    }

    private func makeLabeledMarkerTexture(size: CGSize, emoji: String, color: UIColor) -> SKTexture {
        // Create a cache key based on size, emoji, and color RGBA components
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        var colorKey: String
        if color.getRed(&red, green: &green, blue: &blue, alpha: &alpha) {
            colorKey = String(format: "r%.2fg%.2fb%.2fa%.2f", red, green, blue, alpha)
        } else {
            // Fallback: convert to RGB color space and extract components
            let rgbColor = color.cgColor.converted(to: CGColorSpaceCreateDeviceRGB(), intent: .defaultIntent, options: nil) ?? color.cgColor
            if let components = rgbColor.components, components.count >= 4 {
                colorKey = String(format: "r%.2fg%.2fb%.2fa%.2f", components[0], components[1], components[2], components[3])
            } else {
                // Last resort: use a simple identifier
                colorKey = "fallback_\(emoji)"
            }
        }
        let cacheKey = "marker_\(Int(size.width))x\(Int(size.height))_\(emoji)_\(colorKey)"
        
        if let cached = cachedDynamicTextures[cacheKey] {
            return cached
        }
        
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
        let texture = SKTexture(image: image)
        cachedDynamicTextures[cacheKey] = texture
        return texture
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

    @discardableResult
    private func processInteractableRespawns() -> Bool {
        var intervalMessages: [String] = []

        processToiletEventProgress(messages: &intervalMessages)

        for (interactableID, respawnMove) in respawnAtMoveByInteractableID where completedMoveCount >= respawnMove {
            interactableNodesByID[interactableID]?.isHidden = false
            if interactableConfigsByID[interactableID]?.kind == .chaseGoats {
                intervalMessages.append("Goat returned to the parking lot.")
            }
            respawnAtMoveByInteractableID.removeValue(forKey: interactableID)
        }

        if let batDeadline = batDefeatDeadlineMove,
           completedMoveCount >= batDeadline,
           let batNode = interactableNodesByID[bedroomBatID],
           !batNode.isHidden {
            let previousCoins = GameState.shared.coins
            let penalty = min(previousCoins / 2, batEscapePenaltyMaxCoins)
            _ = GameState.shared.removeCoins(penalty)
            batNode.isHidden = true
            batDefeatDeadlineMove = nil
            nextBatSpawnMove = completedMoveCount + BatEventSettings.randomSpawnIntervalMoves()
            updateCoinLabel()
            intervalMessages.append("Bat escaped. Exterminator called: -\(penalty) coins.")
        }

        if batDefeatDeadlineMove == nil,
           completedMoveCount >= nextBatSpawnMove,
           isPlayerInBarRooms(),
           let batNode = interactableNodesByID[bedroomBatID] {
            batNode.position = interactableHomePositionByID[bedroomBatID] ?? batNode.position
            batNode.isHidden = false
            batDefeatDeadlineMove = completedMoveCount + BatEventSettings.defeatDeadlineMoves
            intervalMessages.append("A bat appeared in the bedroom! Use the tennis racket within \(BatEventSettings.defeatDeadlineMoves) moves.")
        }

        if !intervalMessages.isEmpty {
            showMessage(intervalMessages.joined(separator: "  |  "))
            return true
        }

        return false
    }

    private func updateMakerLoadedIndicator() {
        guard let indicator = makerLoadedIndicatorNode,
              let makerNode = interactableNodesByID[potatoPeelerID] else { return }

        indicator.position = makerNode.position
        indicator.alpha = peelerHasSlicedPotatoes ? 1.0 : 0.0
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
        configureWarningIcons()
        configureMapCloseButton()
        configureSnowmobileChoiceDialog()
        configureStudySubjectPrompt()
        configureStudyBackgroundWindow()
        configureStatusWindow()
        configureSettingsDialog()
    }

    private func configureSettingsDialog() {
        settingsDialogNode = SettingsDialogNode(sceneSize: size)
        settingsDialogNode.zPosition = 760
        settingsDialogNode.onClose = { [weak self] in
            self?.refreshSettingsDependentUI()
        }
        cameraNode.addChild(settingsDialogNode)
    }

    private func refreshSettingsDependentUI() {
        snowmobileChoiceSubtitleLabel?.text = "Sell returns \(snowmobilePriceCoins) coins"
        if isStatusWindowVisible {
            updateStatusWindowBody()
        }
    }

    private func configureSnowmobileChoiceDialog() {
        let backdropSize = CGSize(width: size.width, height: size.height)
        snowmobileChoiceBackdropNode = SKShapeNode(rectOf: backdropSize)
        snowmobileChoiceBackdropNode.name = "snowmobileChoiceBackdrop"
        snowmobileChoiceBackdropNode.fillColor = UIColor.black.withAlphaComponent(0.45)
        snowmobileChoiceBackdropNode.strokeColor = .clear
        snowmobileChoiceBackdropNode.position = .zero
        snowmobileChoiceBackdropNode.zPosition = 740
        snowmobileChoiceBackdropNode.isHidden = true
        cameraNode.addChild(snowmobileChoiceBackdropNode)

        snowmobileChoicePanelNode = SKShapeNode(rectOf: CGSize(width: min(size.width - 90, 460), height: 300), cornerRadius: 14)
        snowmobileChoicePanelNode.name = "snowmobileChoicePanel"
        snowmobileChoicePanelNode.fillColor = UIColor(white: 0.14, alpha: 0.97)
        snowmobileChoicePanelNode.strokeColor = .white
        snowmobileChoicePanelNode.lineWidth = 2
        snowmobileChoicePanelNode.position = .zero
        snowmobileChoicePanelNode.zPosition = 741
        snowmobileChoicePanelNode.isHidden = true
        cameraNode.addChild(snowmobileChoicePanelNode)

        let titleLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
        titleLabel.text = "Owned snowmobile"
        titleLabel.fontSize = 28
        titleLabel.fontColor = .white
        titleLabel.horizontalAlignmentMode = .center
        titleLabel.verticalAlignmentMode = .center
        titleLabel.position = CGPoint(x: 0, y: 104)
        titleLabel.zPosition = 742
        snowmobileChoicePanelNode.addChild(titleLabel)

        snowmobileChoiceSubtitleLabel = SKLabelNode(fontNamed: "AvenirNext-Medium")
        snowmobileChoiceSubtitleLabel.text = "Sell returns \(snowmobilePriceCoins) coins"
        snowmobileChoiceSubtitleLabel.fontSize = 19
        snowmobileChoiceSubtitleLabel.fontColor = UIColor.white.withAlphaComponent(0.9)
        snowmobileChoiceSubtitleLabel.horizontalAlignmentMode = .center
        snowmobileChoiceSubtitleLabel.verticalAlignmentMode = .center
        snowmobileChoiceSubtitleLabel.position = CGPoint(x: 0, y: 74)
        snowmobileChoiceSubtitleLabel.zPosition = 742
        snowmobileChoicePanelNode.addChild(snowmobileChoiceSubtitleLabel)

        let mountButton = SKShapeNode(rectOf: CGSize(width: 180, height: 52), cornerRadius: 8)
        mountButton.name = "snowmobileChoiceMountItem"
        mountButton.fillColor = UIColor.systemBlue.withAlphaComponent(0.9)
        mountButton.strokeColor = .white
        mountButton.lineWidth = 1.5
        mountButton.position = CGPoint(x: 0, y: 24)
        mountButton.zPosition = 742
        snowmobileChoicePanelNode.addChild(mountButton)

        let mountLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
        mountLabel.name = "snowmobileChoiceMountItem"
        mountLabel.text = "Mount"
        mountLabel.fontSize = 22
        mountLabel.fontColor = .white
        mountLabel.horizontalAlignmentMode = .center
        mountLabel.verticalAlignmentMode = .center
        mountLabel.position = .zero
        mountLabel.zPosition = 743
        mountButton.addChild(mountLabel)

        let sellButton = SKShapeNode(rectOf: CGSize(width: 180, height: 52), cornerRadius: 8)
        sellButton.name = "snowmobileChoiceSellItem"
        sellButton.fillColor = UIColor.systemRed.withAlphaComponent(0.9)
        sellButton.strokeColor = .white
        sellButton.lineWidth = 1.5
        sellButton.position = CGPoint(x: 0, y: -42)
        sellButton.zPosition = 742
        snowmobileChoicePanelNode.addChild(sellButton)

        let sellLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
        sellLabel.name = "snowmobileChoiceSellItem"
        sellLabel.text = "Sell"
        sellLabel.fontSize = 22
        sellLabel.fontColor = .white
        sellLabel.horizontalAlignmentMode = .center
        sellLabel.verticalAlignmentMode = .center
        sellLabel.position = .zero
        sellLabel.zPosition = 743
        sellButton.addChild(sellLabel)

        let cancelButton = SKShapeNode(rectOf: CGSize(width: 180, height: 46), cornerRadius: 8)
        cancelButton.name = "snowmobileChoiceCancelItem"
        cancelButton.fillColor = UIColor.darkGray.withAlphaComponent(0.9)
        cancelButton.strokeColor = .white
        cancelButton.lineWidth = 1.5
        cancelButton.position = CGPoint(x: 0, y: -104)
        cancelButton.zPosition = 742
        snowmobileChoicePanelNode.addChild(cancelButton)

        let cancelLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
        cancelLabel.name = "snowmobileChoiceCancelItem"
        cancelLabel.text = "Cancel"
        cancelLabel.fontSize = 20
        cancelLabel.fontColor = .white
        cancelLabel.horizontalAlignmentMode = .center
        cancelLabel.verticalAlignmentMode = .center
        cancelLabel.position = .zero
        cancelLabel.zPosition = 743
        cancelButton.addChild(cancelLabel)
    }

    private func configureStudySubjectPrompt() {
        studySubjectBackdropNode = SKShapeNode(rectOf: CGSize(width: size.width, height: size.height))
        studySubjectBackdropNode.name = "studySubjectBackdrop"
        studySubjectBackdropNode.fillColor = UIColor.black.withAlphaComponent(0.45)
        studySubjectBackdropNode.strokeColor = .clear
        studySubjectBackdropNode.position = .zero
        studySubjectBackdropNode.zPosition = 744
        studySubjectBackdropNode.isHidden = true
        cameraNode.addChild(studySubjectBackdropNode)

        studySubjectPanelNode = SKShapeNode(rectOf: CGSize(width: min(size.width - 100, 460), height: 320), cornerRadius: 14)
        studySubjectPanelNode.name = "studySubjectPanel"
        studySubjectPanelNode.fillColor = UIColor(white: 0.14, alpha: 0.97)
        studySubjectPanelNode.strokeColor = .white
        studySubjectPanelNode.lineWidth = 2
        studySubjectPanelNode.position = .zero
        studySubjectPanelNode.zPosition = 745
        studySubjectPanelNode.isHidden = true
        cameraNode.addChild(studySubjectPanelNode)

        let titleLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
        titleLabel.text = "Study Subject"
        titleLabel.fontSize = 30
        titleLabel.fontColor = .white
        titleLabel.horizontalAlignmentMode = .center
        titleLabel.verticalAlignmentMode = .center
        titleLabel.position = CGPoint(x: 0, y: 126)
        titleLabel.zPosition = 746
        studySubjectPanelNode.addChild(titleLabel)

        func makeSubjectButton(name: String, text: String, y: CGFloat) -> SKShapeNode {
            let button = SKShapeNode(rectOf: CGSize(width: 280, height: 46), cornerRadius: 8)
            button.name = name
            button.fillColor = UIColor.systemBlue.withAlphaComponent(0.9)
            button.strokeColor = .white
            button.lineWidth = 1.5
            button.position = CGPoint(x: 0, y: y)
            button.zPosition = 746

            let label = SKLabelNode(fontNamed: "AvenirNext-Bold")
            label.name = name
            label.text = text
            label.fontSize = 21
            label.fontColor = .white
            label.horizontalAlignmentMode = .center
            label.verticalAlignmentMode = .center
            label.position = .zero
            label.zPosition = 747
            button.addChild(label)
            return button
        }

        studySubjectPanelNode.addChild(makeSubjectButton(name: "studySubjectUSHistItem", text: "US History", y: 58))
        studySubjectPanelNode.addChild(makeSubjectButton(name: "studySubjectEnglishItem", text: "English", y: 2))
        studySubjectPanelNode.addChild(makeSubjectButton(name: "studySubjectScienceItem", text: "Science", y: -54))

        let cancelButton = SKShapeNode(rectOf: CGSize(width: 180, height: 42), cornerRadius: 8)
        cancelButton.name = "studySubjectCancelItem"
        cancelButton.fillColor = UIColor.darkGray.withAlphaComponent(0.9)
        cancelButton.strokeColor = .white
        cancelButton.lineWidth = 1.5
        cancelButton.position = CGPoint(x: 0, y: -120)
        cancelButton.zPosition = 746
        studySubjectPanelNode.addChild(cancelButton)

        let cancelLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
        cancelLabel.name = "studySubjectCancelItem"
        cancelLabel.text = "Cancel"
        cancelLabel.fontSize = 20
        cancelLabel.fontColor = .white
        cancelLabel.horizontalAlignmentMode = .center
        cancelLabel.verticalAlignmentMode = .center
        cancelLabel.position = .zero
        cancelLabel.zPosition = 747
        cancelButton.addChild(cancelLabel)
    }

    private func configureStudyBackgroundWindow() {
        studyBackgroundBackdropNode = SKShapeNode(rectOf: CGSize(width: size.width, height: size.height))
        studyBackgroundBackdropNode.name = "studyBackgroundBackdrop"
        studyBackgroundBackdropNode.fillColor = UIColor.black.withAlphaComponent(0.45)
        studyBackgroundBackdropNode.strokeColor = .clear
        studyBackgroundBackdropNode.position = .zero
        studyBackgroundBackdropNode.zPosition = 746
        studyBackgroundBackdropNode.isHidden = true
        cameraNode.addChild(studyBackgroundBackdropNode)

        // Make the study window taller: use more of the screen height
        studyBackgroundPanelNode = SKShapeNode(rectOf: CGSize(width: min(size.width - 80, 760), height: min(size.height * 0.85, 760)), cornerRadius: 14)
        studyBackgroundPanelNode.name = "studyBackgroundPanel"
        studyBackgroundPanelNode.fillColor = UIColor(white: 0.10, alpha: 0.97)
        studyBackgroundPanelNode.strokeColor = .white
        studyBackgroundPanelNode.lineWidth = 2
        studyBackgroundPanelNode.position = .zero
        studyBackgroundPanelNode.zPosition = 747
        studyBackgroundPanelNode.isHidden = true
        cameraNode.addChild(studyBackgroundPanelNode)

        studyBackgroundTitleLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
        studyBackgroundTitleLabel.text = ""
        studyBackgroundTitleLabel.fontSize = 30
        studyBackgroundTitleLabel.fontColor = .white
        studyBackgroundTitleLabel.horizontalAlignmentMode = .center
        studyBackgroundTitleLabel.verticalAlignmentMode = .center
        studyBackgroundTitleLabel.zPosition = 748
        studyBackgroundPanelNode.addChild(studyBackgroundTitleLabel)

        studyBackgroundScrollCropNode = SKCropNode()
        studyBackgroundScrollCropNode.zPosition = 748
        studyBackgroundPanelNode.addChild(studyBackgroundScrollCropNode)

        let scrollMask = SKSpriteNode(color: .white, size: CGSize(width: 100, height: 100))
        scrollMask.position = .zero
        studyBackgroundScrollCropNode.maskNode = scrollMask

        studyBackgroundScrollContentNode = SKNode()
        studyBackgroundScrollCropNode.addChild(studyBackgroundScrollContentNode)

        studyBackgroundScrollTrackNode = SKShapeNode(rectOf: CGSize(width: 6, height: 100), cornerRadius: 3)
        studyBackgroundScrollTrackNode.fillColor = UIColor.white.withAlphaComponent(0.2)
        studyBackgroundScrollTrackNode.strokeColor = UIColor.white.withAlphaComponent(0.4)
        studyBackgroundScrollTrackNode.lineWidth = 1
        studyBackgroundScrollTrackNode.zPosition = 748
        studyBackgroundPanelNode.addChild(studyBackgroundScrollTrackNode)

        studyBackgroundScrollThumbNode = SKShapeNode(rectOf: CGSize(width: 6, height: 44), cornerRadius: 3)
        studyBackgroundScrollThumbNode.fillColor = UIColor.white.withAlphaComponent(0.85)
        studyBackgroundScrollThumbNode.strokeColor = .white
        studyBackgroundScrollThumbNode.lineWidth = 0.5
        studyBackgroundScrollThumbNode.zPosition = 749
        studyBackgroundPanelNode.addChild(studyBackgroundScrollThumbNode)

        studyBackgroundDoneButtonNode = SKShapeNode(rectOf: CGSize(width: 140, height: 44), cornerRadius: 8)
        studyBackgroundDoneButtonNode.name = "studyBackgroundDoneItem"
        studyBackgroundDoneButtonNode.fillColor = UIColor.systemBlue.withAlphaComponent(0.9)
        studyBackgroundDoneButtonNode.strokeColor = .white
        studyBackgroundDoneButtonNode.lineWidth = 1.5
        studyBackgroundDoneButtonNode.zPosition = 748
        studyBackgroundPanelNode.addChild(studyBackgroundDoneButtonNode)

        let doneLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
        doneLabel.name = "studyBackgroundDoneItem"
        doneLabel.text = "Done"
        doneLabel.fontSize = 22
        doneLabel.fontColor = .white
        doneLabel.horizontalAlignmentMode = .center
        doneLabel.verticalAlignmentMode = .center
        doneLabel.position = .zero
        doneLabel.zPosition = 749
        studyBackgroundDoneButtonNode.addChild(doneLabel)

        updateStudyUILayouts()
    }

    private func updateStudyUILayouts() {
        guard studySubjectBackdropNode != nil,
              studySubjectPanelNode != nil,
              studyBackgroundBackdropNode != nil,
              studyBackgroundPanelNode != nil,
              studyBackgroundTitleLabel != nil,
              studyBackgroundScrollCropNode != nil,
              studyBackgroundScrollTrackNode != nil,
              studyBackgroundScrollThumbNode != nil,
                            studyBackgroundDoneButtonNode != nil,
                            let scrollMask = studyBackgroundScrollCropNode.maskNode as? SKSpriteNode else {
            return
        }

        studySubjectBackdropNode.path = CGPath(rect: CGRect(x: -size.width / 2, y: -size.height / 2, width: size.width, height: size.height), transform: nil)
        let subjectPanelSize = CGSize(width: min(size.width - 100, 460), height: 320)
        studySubjectPanelNode.path = CGPath(roundedRect: CGRect(x: -subjectPanelSize.width / 2, y: -subjectPanelSize.height / 2, width: subjectPanelSize.width, height: subjectPanelSize.height), cornerWidth: 14, cornerHeight: 14, transform: nil)

        studyBackgroundBackdropNode.path = CGPath(rect: CGRect(x: -size.width / 2, y: -size.height / 2, width: size.width, height: size.height), transform: nil)
        // Make the study window taller: use more of the screen height
        let panelSize = CGSize(width: min(size.width - 80, 760), height: min(size.height * 0.85, 760))
        studyBackgroundPanelNode.path = CGPath(roundedRect: CGRect(x: -panelSize.width / 2, y: -panelSize.height / 2, width: panelSize.width, height: panelSize.height), cornerWidth: 14, cornerHeight: 14, transform: nil)

        studyBackgroundTitleLabel.position = CGPoint(x: 0, y: panelSize.height / 2 + 1000)

        studyBackgroundScrollViewportWidth = panelSize.width - 84
        studyBackgroundScrollViewportHeight = panelSize.height - 96

        studyBackgroundScrollCropNode.position = CGPoint(x: -10, y: 10)
        scrollMask.size = CGSize(width: studyBackgroundScrollViewportWidth, height: studyBackgroundScrollViewportHeight)

        let trackSize = CGSize(width: 6, height: studyBackgroundScrollViewportHeight)
        studyBackgroundScrollTrackNode.path = CGPath(roundedRect: CGRect(x: -trackSize.width / 2, y: -trackSize.height / 2, width: trackSize.width, height: trackSize.height), cornerWidth: 3, cornerHeight: 3, transform: nil)
        studyBackgroundScrollTrackNode.position = CGPoint(x: studyBackgroundScrollViewportWidth / 2 + 12 + studyBackgroundScrollCropNode.position.x, y: studyBackgroundScrollCropNode.position.y)

        studyBackgroundDoneButtonNode.position = CGPoint(x: 0, y: -panelSize.height / 2 + 34)

        setStudyBackgroundScrollOffset(studyBackgroundScrollOffset)
    }

    private func setStudySubjectPromptVisible(_ visible: Bool) {
        isStudySubjectPromptVisible = visible
        studySubjectBackdropNode.isHidden = !visible
        studySubjectPanelNode.isHidden = !visible
    }

    private func setStudyBackgroundWindowVisible(_ visible: Bool) {
        isStudyBackgroundWindowVisible = visible
        if !visible {
            isDraggingStudyBackgroundScroll = false
        }
        studyBackgroundBackdropNode.isHidden = !visible
        studyBackgroundPanelNode.isHidden = !visible
    }

    private func endStudyBackgroundDrag() -> Bool {
        if isDraggingStudyBackgroundScroll {
            isDraggingStudyBackgroundScroll = false
            return true
        }
        return false
    }

    private func openStudyBackgroundWindow(for subject: String) {
        setStudySubjectPromptVisible(false)

        let matchingBackgrounds = quizQuestions
            .filter { $0.subject == subject }
            .compactMap { $0.background?.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        renderStudyBackgroundParagraphs(matchingBackgrounds)
        setStudyBackgroundWindowVisible(true)
    }

    private func renderStudyBackgroundParagraphs(_ paragraphs: [String]) {
        studyBackgroundScrollContentNode.removeAllChildren()

        let fontName = "AvenirNext-Medium"
        let fontSize: CGFloat = 21
        let lineHeight: CGFloat = 27
        let topPadding: CGFloat = 8
        let bottomPadding: CGFloat = 8
        let maxCharsPerLine = max(40, Int(studyBackgroundScrollViewportWidth / 11))
        let textX = -studyBackgroundScrollViewportWidth / 2 + 8

        var renderedLines: [String] = []
        if paragraphs.isEmpty {
            renderedLines.append("No study notes available for this subject.")
        } else {
            for (index, paragraph) in paragraphs.enumerated() {
                renderedLines.append(contentsOf: wrappedLines(paragraph, maxCharacters: maxCharsPerLine))
                if index < paragraphs.count - 1 {
                    renderedLines.append("")
                }
            }
        }

        let contentHeight = topPadding + bottomPadding + CGFloat(renderedLines.count) * lineHeight
        studyBackgroundScrollContentHeight = max(contentHeight, studyBackgroundScrollViewportHeight)

        let topY = studyBackgroundScrollContentHeight / 2 - topPadding
        for (index, lineText) in renderedLines.enumerated() {
            let lineNode = SKLabelNode(fontNamed: fontName)
            lineNode.text = lineText
            lineNode.fontSize = fontSize
            lineNode.fontColor = .white
            lineNode.horizontalAlignmentMode = .left
            lineNode.verticalAlignmentMode = .top
            lineNode.position = CGPoint(x: textX, y: topY - CGFloat(index) * lineHeight)
            lineNode.zPosition = 748
            studyBackgroundScrollContentNode.addChild(lineNode)
        }

        studyBackgroundScrollOffset = 0
        setStudyBackgroundScrollOffset(0)
        updateStudyBackgroundScrollIndicator()
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

    private func setStudyBackgroundScrollOffset(_ offset: CGFloat) {
        let maxOffset = max(0, studyBackgroundScrollContentHeight - studyBackgroundScrollViewportHeight)
        studyBackgroundScrollOffset = min(max(0, offset), maxOffset)
        studyBackgroundScrollContentNode.position = CGPoint(
            x: 0,
            y: (studyBackgroundScrollViewportHeight - studyBackgroundScrollContentHeight) / 2 + studyBackgroundScrollOffset
        )
        updateStudyBackgroundScrollIndicator()
    }

    private func updateStudyBackgroundScrollIndicator() {
        let maxOffset = max(0, studyBackgroundScrollContentHeight - studyBackgroundScrollViewportHeight)
        guard maxOffset > 0 else {
            studyBackgroundScrollTrackNode.isHidden = true
            studyBackgroundScrollThumbNode.isHidden = true
            return
        }

        studyBackgroundScrollTrackNode.isHidden = false
        studyBackgroundScrollThumbNode.isHidden = false

        let visibleRatio = studyBackgroundScrollViewportHeight / studyBackgroundScrollContentHeight
        let thumbHeight = max(30, studyBackgroundScrollViewportHeight * visibleRatio)
        studyBackgroundScrollThumbNode.path = CGPath(
            roundedRect: CGRect(x: -3, y: -thumbHeight / 2, width: 6, height: thumbHeight),
            cornerWidth: 3,
            cornerHeight: 3,
            transform: nil
        )

        let trackTopY = studyBackgroundScrollTrackNode.position.y + studyBackgroundScrollViewportHeight / 2
        let travelRange = studyBackgroundScrollViewportHeight - thumbHeight
        let progress = studyBackgroundScrollOffset / maxOffset
        let thumbCenterY = trackTopY - thumbHeight / 2 - (travelRange * progress)
        studyBackgroundScrollThumbNode.position = CGPoint(x: studyBackgroundScrollTrackNode.position.x, y: thumbCenterY)
    }

    private func setSnowmobileChoiceDialogVisible(_ visible: Bool, snowmobileID: String? = nil) {
        if visible {
            pendingLotSnowmobileID = snowmobileID
            snowmobileChoiceSubtitleLabel?.text = "Sell returns \(snowmobilePriceCoins) coins"
        } else {
            pendingLotSnowmobileID = nil
        }

        snowmobileChoiceBackdropNode.isHidden = !visible
        snowmobileChoicePanelNode.isHidden = !visible
    }

    private func handleLotOwnedSnowmobileMountChoice() {
        guard let snowmobileID = pendingLotSnowmobileID,
              ownedSnowmobileIDs.contains(snowmobileID) else {
            setSnowmobileChoiceDialogVisible(false)
            return
        }

        guard isSnowmobileDrivable(at: player.position) else {
            setSnowmobileChoiceDialogVisible(false)
            showMessage("Snowmobile can only be mounted outdoors.")
            return
        }

        mountedSnowmobileID = snowmobileID
        selectedOwnedSnowmobileID = snowmobileID
        updateMountedSnowmobileUI()
        setSnowmobileChoiceDialogVisible(false)
        showMessage("Mounted snowmobile.")
    }

    private func handleLotOwnedSnowmobileSellChoice() {
        guard let snowmobileID = pendingLotSnowmobileID,
              ownedSnowmobileIDs.contains(snowmobileID) else {
            setSnowmobileChoiceDialogVisible(false)
            return
        }

        ownedSnowmobileIDs.remove(snowmobileID)
        if selectedOwnedSnowmobileID == snowmobileID {
            selectedOwnedSnowmobileID = nil
        }
        if mountedSnowmobileID == snowmobileID {
            mountedSnowmobileID = nil
            updateMountedSnowmobileUI()
        }

        GameState.shared.addCoins(snowmobilePriceCoins)
        updateCoinLabel()
        updateSnowmobileOwnershipVisuals()
        setSnowmobileChoiceDialogVisible(false)
        showMessage("Sold snowmobile back for \(snowmobilePriceCoins) coins.")
    }

    private func configureMapCloseButton() {
        mapCloseButtonNode = SKShapeNode(rectOf: CGSize(width: 140, height: 40), cornerRadius: 8)
        mapCloseButtonNode.name = "mapCloseItem"
        mapCloseButtonNode.fillColor = UIColor.systemBlue.withAlphaComponent(0.9)
        mapCloseButtonNode.strokeColor = .white
        mapCloseButtonNode.lineWidth = 1.5
        mapCloseButtonNode.zPosition = 530
        mapCloseButtonNode.isHidden = true
        cameraNode.addChild(mapCloseButtonNode)

        mapCloseLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
        mapCloseLabel.name = "mapCloseItem"
        mapCloseLabel.text = "Close Map"
        mapCloseLabel.fontSize = 21
        mapCloseLabel.fontColor = .white
        mapCloseLabel.horizontalAlignmentMode = .center
        mapCloseLabel.verticalAlignmentMode = .center
        mapCloseLabel.position = .zero
        mapCloseLabel.zPosition = 531
        mapCloseButtonNode.addChild(mapCloseLabel)

        updateMapCloseButtonPosition()
    }

    private func updateMapCloseButtonPosition() {
        guard mapCloseButtonNode != nil else { return }

        let safeAreaInsets = view?.safeAreaInsets ?? .zero
        let rightInset = safeAreaInsets.right + 20
        let topInset = safeAreaInsets.top + 20
        mapCloseButtonNode.position = CGPoint(
            x: size.width / 2 - rightInset - 70,
            y: size.height / 2 - topInset - 20
        )
    }

    private func configureWarningIcons() {
        warningIconContainerNode = SKNode()
        warningIconContainerNode.zPosition = 515
        cameraNode.addChild(warningIconContainerNode)
        updateWarningIconContainerPosition()

        let iconSize = CGSize(width: 24, height: 24)

        if let batTexture = loadTexture(named: "bedroom_bat_marker") {
            warningBatIconNode = SKSpriteNode(texture: batTexture, color: .clear, size: iconSize)
        } else {
            let fallbackTexture = makeLabeledMarkerTexture(size: iconSize, emoji: "🦇", color: .systemPurple)
            warningBatIconNode = SKSpriteNode(texture: fallbackTexture, color: .clear, size: iconSize)
        }
        warningBatIconNode.name = "warningBatIcon"
        warningBatIconNode.isHidden = true
        warningIconContainerNode.addChild(warningBatIconNode)

        if let toiletDirtyTexture {
            warningToiletIconNode = SKSpriteNode(texture: toiletDirtyTexture, color: .clear, size: iconSize)
        } else {
            let fallbackTexture = makeLabeledMarkerTexture(size: iconSize, emoji: "!", color: .systemBrown)
            warningToiletIconNode = SKSpriteNode(texture: fallbackTexture, color: .clear, size: iconSize)
        }
        warningToiletIconNode.name = "warningToiletIcon"
        warningToiletIconNode.isHidden = true
        warningIconContainerNode.addChild(warningToiletIconNode)

        updateWarningIcons()
    }

    private func updateWarningIconContainerPosition() {
        guard warningIconContainerNode != nil else { return }

        let safeAreaInsets = view?.safeAreaInsets ?? .zero
        let leftInset = max(38, safeAreaInsets.left + 16)
        let bottomInset = max(22, safeAreaInsets.bottom + 12)

        warningIconContainerNode.position = CGPoint(
            x: -size.width / 2 + leftInset,
            y: -size.height / 2 + bottomInset
        )
    }

    private func updateWarningIcons() {
        var activeIcons: [SKSpriteNode] = []

        if batDefeatDeadlineMove != nil {
            activeIcons.append(warningBatIconNode)
        }

        if isToiletDirty {
            activeIcons.append(warningToiletIconNode)
        }

        let spacing: CGFloat = 30
        for (index, icon) in activeIcons.enumerated() {
            icon.isHidden = false
            icon.position = CGPoint(x: CGFloat(index) * spacing, y: 0)
        }

        if !activeIcons.contains(warningBatIconNode) {
            warningBatIconNode.isHidden = true
        }
        if !activeIcons.contains(warningToiletIconNode) {
            warningToiletIconNode.isHidden = true
        }
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

        // Slightly narrower panel so it stays on-screen; compute X so panel sits left of the hamburger button
        let menuPanelWidth: CGFloat = 190
        let menuPanelHeight: CGFloat = 264
        menuPanelNode = SKShapeNode(rectOf: CGSize(width: menuPanelWidth, height: menuPanelHeight), cornerRadius: 9)
        menuPanelNode.name = "menuPanel"
        menuPanelNode.fillColor = UIColor.black.withAlphaComponent(0.6)
        menuPanelNode.strokeColor = .white
        menuPanelNode.lineWidth = 1.5
        // Compute the hamburger button X (same as menuButtonNode.position.x above)
        let menuButtonX = rightX - 18
        // Place the panel so its right edge is 8pt left of the hamburger button (safe gap)
        var panelCenterX = (menuButtonX - 8) - (menuPanelWidth / 2)
        // Clamp to screen bounds (prevent panel from moving off the left/right edges)
        let maxRightCenterX = (size.width / 2) - 8 - (menuPanelWidth / 2)
        let minLeftCenterX = (-size.width / 2) + 8 + (menuPanelWidth / 2)
        panelCenterX = min(panelCenterX, maxRightCenterX)
        panelCenterX = max(panelCenterX, minLeftCenterX)

        menuPanelNode.position = CGPoint(x: panelCenterX, y: topY - 133)
        menuPanelNode.zPosition = 520
        menuPanelNode.isHidden = true
        cameraNode.addChild(menuPanelNode)

        // Helper to create an invisible button with a label child. The button keeps the existing "menu...Item" names
        func makeMenuButton(name: String, labelText: String, y: CGFloat) -> SKShapeNode {
            let buttonSize = CGSize(width: menuPanelWidth - 28, height: 56)
            let button = SKShapeNode(rectOf: buttonSize, cornerRadius: 8)
            button.name = name
            button.fillColor = .clear
            button.strokeColor = .clear
            button.position = CGPoint(x: 0, y: y)
            button.zPosition = 521

            let label = SKLabelNode(fontNamed: "AvenirNext-Bold")
            // Keep a distinct label name to avoid collisions, but touch logic matches parent name
            label.name = name + "Label"
            label.text = labelText
            label.fontSize = 30
            label.fontColor = .white
            label.verticalAlignmentMode = .center
            label.horizontalAlignmentMode = .center
            label.position = .zero
            label.zPosition = 522
            button.addChild(label)

            return button
        }

        // Create menu buttons (invisible targets) and add them to the panel
        let statusButton = makeMenuButton(name: "menuStatusItem", labelText: "Status", y: 88)
        menuPanelNode.addChild(statusButton)

        let settingsButton = makeMenuButton(name: "menuSettingsItem", labelText: "Settings", y: 44)
        menuPanelNode.addChild(settingsButton)

        let resetButton = makeMenuButton(name: "menuResetItem", labelText: "Reset", y: 0)
        menuPanelNode.addChild(resetButton)

        let move20Button = makeMenuButton(name: "menuMove20Item", labelText: "Move 20", y: -44)
        menuPanelNode.addChild(move20Button)

        let mapButton = makeMenuButton(name: "menuMapItem", labelText: "Map", y: -88)
        menuPanelNode.addChild(mapButton)
    }

    private func setMapViewMode(_ enabled: Bool) {
        if enabled == isMapViewMode { return }

        if enabled {
            mapModeSavedCameraPosition = cameraNode.position
            mapModeSavedCameraScale = cameraNode.xScale
            isMapViewMode = true
            isDraggingMap = false
            moveTarget = nil
            player.physicsBody?.velocity = .zero
            cameraNode.setScale(mapViewZoomOutScale)
            clampCameraPositionToWorldBounds()
            mapCloseButtonNode.isHidden = false
            showMessage("Map mode: drag to pan, then tap Close Map.")
            return
        }

        isMapViewMode = false
        isDraggingMap = false
        cameraNode.position = mapModeSavedCameraPosition
        cameraNode.setScale(mapModeSavedCameraScale)
        mapCloseButtonNode.isHidden = true
    }

    private func clampCameraPositionToWorldBounds() {
        let worldWidth = CGFloat(worldColumns) * tileSize.width
        let worldHeight = CGFloat(worldRows) * tileSize.height
        let halfWorldWidth = worldWidth * 0.5
        let halfWorldHeight = worldHeight * 0.5

        let halfViewWidth = (size.width * cameraNode.xScale) * 0.5
        let halfViewHeight = (size.height * cameraNode.yScale) * 0.5

        let minX = -halfWorldWidth + halfViewWidth
        let maxX = halfWorldWidth - halfViewWidth
        let minY = -halfWorldHeight + halfViewHeight
        let maxY = halfWorldHeight - halfViewHeight

        let clampedX: CGFloat = minX <= maxX ? min(max(cameraNode.position.x, minX), maxX) : 0
        let clampedY: CGFloat = minY <= maxY ? min(max(cameraNode.position.y, minY), maxY) : 0

        cameraNode.position = CGPoint(x: clampedX, y: clampedY)
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

        let scrollTrackSize = CGSize(width: 6, height: statusScrollViewportHeight)
        statusScrollTrackNode = SKShapeNode(rectOf: scrollTrackSize, cornerRadius: 3)
        statusScrollTrackNode.fillColor = UIColor.white.withAlphaComponent(0.2)
        statusScrollTrackNode.strokeColor = UIColor.white.withAlphaComponent(0.4)
        statusScrollTrackNode.lineWidth = 1
        statusScrollTrackNode.position = CGPoint(x: statusScrollViewportWidth / 2 + 12, y: statusScrollCropNode.position.y)
        statusScrollTrackNode.zPosition = 702
        statusPanelNode.addChild(statusScrollTrackNode)

        statusScrollThumbNode = SKShapeNode(rectOf: CGSize(width: 6, height: 44), cornerRadius: 3)
        statusScrollThumbNode.fillColor = UIColor.white.withAlphaComponent(0.85)
        statusScrollThumbNode.strokeColor = .white
        statusScrollThumbNode.lineWidth = 0.5
        statusScrollThumbNode.position = statusScrollTrackNode.position
        statusScrollThumbNode.zPosition = 703
        statusPanelNode.addChild(statusScrollThumbNode)

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
        statusDoneLabel.text = "Close"
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

        let toiletStatusText: String
        if isToiletDirty {
            if let deadline = toiletCleanDeadlineMove {
                toiletStatusText = "Dirty (clean in \(max(0, deadline - completedMoveCount)) moves)"
            } else {
                toiletStatusText = "Dirty"
            }
        } else {
            toiletStatusText = "Clean (next in avg \(ToiletEventSettings.dirtyIntervalMoves), range \(ToiletEventSettings.minDirtyIntervalMoves)-\(ToiletEventSettings.maxDirtyIntervalMoves))"
        }

        let currentMoveSpeed = mountedSnowmobileID == nil
            ? Int(playerMoveSpeed)
            : Int(playerMoveSpeed * mountedSnowmobileSpeedMultiplier)
        let movementModeText = mountedSnowmobileID == nil ? "On foot" : "Mounted"

        var statusLines = [
            "Coins: \(GameState.shared.coins)",
            "Moves: \(completedMoveCount)",
            "Snowmobiles owned: \(ownedSnowmobileIDs.count)/6",
            "Mounted snowmobile: \(mountedSnowmobileID == nil ? "No" : "Yes")",
            "Move speed: \(currentMoveSpeed) (\(movementModeText))",
            "Bucket carried: \(isBucketCarried ? "Yes" : "No")",
            "Bucket potatoes: \(bucketPotatoCount)/\(bucketCapacity)",
            "Washed in bucket: \(washedPotatoCount)",
            "Potato selected: \(selectedPotatoForLoading ? "Yes" : "No")",
            "Peeler has slices: \(peelerHasSlicedPotatoes ? "Yes" : "No")",
            "Basket carried: \(isChipsBasketCarried ? "Yes" : "No")",
            "Basket slices: \(basketSlicedPotatoCount)",
            "Basket has chips: \(chipsBasketContainsChips ? "Yes" : "No")",
            "Fryer slices: \(fryerSlicedPotatoCount)",
            "Toilet dirty: \(isToiletDirty ? "Yes" : "No")",
            "Brush carried: \(isToiletBowlBrushCarried ? "Yes" : "No")",
            "Toilet event: \(toiletStatusText)",
            "Racket carried: \(isTennisRacketCarried ? "Yes" : "No")",
            "Shovel carried: \(isShovelCarried ? "Yes" : "No")",
            "Septic trenches: \(trenchedSepticTiles.count)/\(worldConfig.septicDigTiles.count)",
            "Bat event: \(batStatusText)",
            "Goat respawn: \(goatRespawnText)"
        ]
        if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
            statusLines.append("Version: " + version)
        }
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
        updateStatusScrollIndicator()
    }

    private func setStatusScrollOffset(_ offset: CGFloat) {
        let maxOffset = max(0, statusScrollContentHeight - statusScrollViewportHeight)
        statusScrollOffset = min(max(0, offset), maxOffset)
        statusScrollContentNode.position = CGPoint(
            x: 0,
            y: (statusScrollViewportHeight - statusScrollContentHeight) / 2 + statusScrollOffset
        )
        updateStatusScrollIndicator()
    }

    private func updateStatusScrollIndicator() {
        let maxOffset = max(0, statusScrollContentHeight - statusScrollViewportHeight)
        guard maxOffset > 0 else {
            statusScrollTrackNode.isHidden = true
            statusScrollThumbNode.isHidden = true
            return
        }

        statusScrollTrackNode.isHidden = false
        statusScrollThumbNode.isHidden = false

        let visibleRatio = statusScrollViewportHeight / statusScrollContentHeight
        let thumbHeight = max(24, statusScrollViewportHeight * visibleRatio)
        statusScrollThumbNode.path = CGPath(
            roundedRect: CGRect(x: -3, y: -thumbHeight / 2, width: 6, height: thumbHeight),
            cornerWidth: 3,
            cornerHeight: 3,
            transform: nil
        )

        let trackTopY = statusScrollTrackNode.position.y + statusScrollViewportHeight / 2
        let travelRange = statusScrollViewportHeight - thumbHeight
        let progress = statusScrollOffset / maxOffset
        let thumbCenterY = trackTopY - thumbHeight / 2 - (travelRange * progress)
        statusScrollThumbNode.position = CGPoint(x: statusScrollTrackNode.position.x, y: thumbCenterY)
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

        if mountedSnowmobileID != nil, config.kind != .snowmobile {
            showMessage("Dismount snowmobile first.")
            return
        }

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
        case .chipsBasket:
            handleChipsBasketInteraction(node: node)
            return
        case .snowmobile:
            handleSnowmobileInteraction(interactableID: interactableID)
            return
        case .toilet:
            handleToiletInteraction()
            return
        case .desk:
            handleDeskInteraction()
            return
        case .toiletBowlBrush:
            handleToiletBowlBrushInteraction(node: node)
            return
        case .deepFryer:
            handleDeepFryerInteraction()
            return
        case .spigot:
            handleSpigotInteraction()
            return
        case .potatoChips:
            handlePotatoPeelerInteraction()
            return
        case .tennisRacket:
            handleTennisRacketInteraction(node: node)
            return
        case .bedroomBat:
            handleBedroomBatInteraction(node: node)
            return
        case .shovel:
            handleShovelInteraction(node: node)
            return
        case .chaseGoats:
            node.isHidden = true
            let respawnAfterMoves = Int.random(in: UTSettings.shared.counts.goatRespawnMinMoves...UTSettings.shared.counts.goatRespawnMaxMoves)
            respawnAtMoveByInteractableID[interactableID] = completedMoveCount + respawnAfterMoves
            GameState.shared.addCoins(goatChaseRewardCoins)
            updateCoinLabel()
            showMessage("Chased goats off cars! +\(goatChaseRewardCoins) coins")
            return
        }
    }

    private func handleDeskInteraction() {
        setMenuVisible(false)
        setStatusWindowVisible(false)
        setStudyBackgroundWindowVisible(false)
        setStudySubjectPromptVisible(true)
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

        let nearPeeler = isPlayerNearInteractable(withID: potatoPeelerID)
        if nearPeeler && bucketPotatoCount > 0 {
            guard washedPotatoCount > 0 else {
                showMessage("Potatoes must be washed at the spigot first.")
                return
            }
            if peelerHasSlicedPotatoes {
                showMessage("Potato peeler already has slices. Use basket to collect them.")
                return
            }
            bucketPotatoCount -= 1
            washedPotatoCount -= 1
            selectedPotatoForLoading = true
            selectedPotatoIsWashed = true
            showMessage("Selected washed potato for peeler (\(bucketPotatoCount)/\(bucketCapacity) left, washed \(washedPotatoCount)).")
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

    private func handlePotatoPeelerInteraction() {
        if peelerHasSlicedPotatoes {
            showMessage("Potato peeler has slices ready. Put them in the basket.")
            return
        }

        guard isBucketCarried else {
            showMessage("Bring the bucket to the potato peeler.")
            return
        }

        if selectedPotatoForLoading {
            guard selectedPotatoIsWashed else {
                showMessage("Selected potato must be washed first.")
                return
            }
            selectedPotatoForLoading = false
            selectedPotatoIsWashed = false
            peelerHasSlicedPotatoes = true
            updateMakerLoadedIndicator()
            showMessage("Potato peeled and sliced. Move slices into basket.")
            return
        }

        showMessage("Select a washed potato from the bucket first.")
    }

    private func handleChipsBasketInteraction(node: SKSpriteNode) {
        if !isChipsBasketCarried {
            isChipsBasketCarried = true
            showMessage("Picked up basket.")
            return
        }

        if isPlayerNearInteractable(withID: potatoPeelerID) {
            guard peelerHasSlicedPotatoes else {
                showMessage("No sliced potatoes ready in peeler.")
                return
            }
            guard !chipsBasketContainsChips else {
                showMessage("Basket already has finished chips.")
                return
            }

            peelerHasSlicedPotatoes = false
            basketSlicedPotatoCount += 1
            updateMakerLoadedIndicator()
            showMessage("Added sliced potato to basket (\(basketSlicedPotatoCount) total).")
            return
        }

        isChipsBasketCarried = false
        node.position = player.position
        showMessage("Dropped basket.")
    }

    private func handleDeepFryerInteraction() {
        guard isChipsBasketCarried else {
            showMessage("Bring the basket to the deep fryer.")
            return
        }

        if basketSlicedPotatoCount > 0 && fryerSlicedPotatoCount == 0 {
            fryerSlicedPotatoCount = basketSlicedPotatoCount
            basketSlicedPotatoCount = 0
            showMessage("Put \(fryerSlicedPotatoCount) sliced potato\(fryerSlicedPotatoCount == 1 ? "" : "es") into deep fryer.")
            return
        }

        if fryerSlicedPotatoCount > 0 && !chipsBasketContainsChips {
            let friedPotatoCount = fryerSlicedPotatoCount
            fryerSlicedPotatoCount = 0
            chipsBasketContainsChips = true
            let rewardCoins = potatoChipRewardPerPotato * friedPotatoCount
            GameState.shared.addCoins(rewardCoins)
            updateCoinLabel()
            showMessage("Fried chips from \(friedPotatoCount) potato\(friedPotatoCount == 1 ? "" : "es") returned to basket. +\(rewardCoins) coins")
            chipsBasketContainsChips = false
            return
        }

        if chipsBasketContainsChips {
            showMessage("Basket already holds finished chips.")
            return
        }

        showMessage("Put sliced potatoes into the fryer first.")
    }

    private func handleSnowmobileInteraction(interactableID: String) {
        guard let snowmobileConfig = interactableConfigsByID[interactableID] else { return }

        if let mountedID = mountedSnowmobileID {
            guard mountedID == interactableID else {
                showMessage("Already mounted on another snowmobile.")
                return
            }
            attemptDismountSnowmobile()
            return
        }

        guard tileRegionContains(worldConfig.carrollSalesRegion, tile: snowmobileConfig.tile),
              isPlayerInCarrollSalesArea() else {
            if ownedSnowmobileIDs.contains(interactableID) {
                guard isSnowmobileDrivable(at: player.position) else {
                    showMessage("Snowmobile can only be mounted outdoors.")
                    return
                }

                mountedSnowmobileID = interactableID
                selectedOwnedSnowmobileID = interactableID
                updateMountedSnowmobileUI()
                showMessage("Mounted snowmobile.")
                return
            }

            showMessage("Buy/sell snowmobiles inside Carroll's Snowmobile Sales area.")
            return
        }

        if ownedSnowmobileIDs.contains(interactableID) {
            setSnowmobileChoiceDialogVisible(true, snowmobileID: interactableID)
            return
        }

        guard GameState.shared.coins >= snowmobilePriceCoins else {
            showMessage("Need \(snowmobilePriceCoins) coins to buy this snowmobile.")
            return
        }

        _ = GameState.shared.removeCoins(snowmobilePriceCoins)
        ownedSnowmobileIDs.insert(interactableID)
        selectedOwnedSnowmobileID = interactableID
        updateCoinLabel()
        updateSnowmobileOwnershipVisuals()
        showMessage("Bought snowmobile for \(snowmobilePriceCoins) coins.")
    }

    private func attemptDismountSnowmobile() {
        guard let mountedID = mountedSnowmobileID,
              let currentTile = tileCoordinate(for: player.position) else {
            mountedSnowmobileID = nil
            updateMountedSnowmobileUI()
            return
        }

        let neighborOffsets: [(Int, Int)] = [
            (0, 1),
            (1, 0),
            (0, -1),
            (-1, 0)
        ]

        for (dc, dr) in neighborOffsets {
            let tile = TileCoordinate(column: currentTile.column + dc, row: currentTile.row + dr)
            guard tile.column >= 0, tile.column < worldColumns,
                  tile.row >= 0, tile.row < worldRows,
                  !worldConfig.wallTiles.contains(tile),
                  let dismountPoint = scenePointForTile(tile) else {
                continue
            }

            player.position = dismountPoint
            player.physicsBody?.velocity = .zero
            moveTarget = nil
            mountedSnowmobileID = nil
            selectedOwnedSnowmobileID = mountedID
            updateMountedSnowmobileUI()
            showMessage("Dismounted snowmobile.")
            return
        }

        showMessage("No space to dismount here.")
    }

    private func handleToiletBowlBrushInteraction(node: SKSpriteNode) {
        if isToiletBowlBrushCarried {
            isToiletBowlBrushCarried = false
            node.position = player.position
            showMessage("Dropped toilet bowl brush.")
            return
        }

        isToiletBowlBrushCarried = true
        showMessage("Picked up toilet bowl brush.")
    }

    private func handleToiletInteraction() {
        guard isToiletDirty else {
            showMessage("The toilet is already clean.")
            return
        }

        guard isToiletBowlBrushCarried else {
            showMessage("Pick up the toilet bowl brush first.")
            return
        }

        isToiletDirty = false
        toiletCleanDeadlineMove = nil
        hasShownToiletPenaltyStartMessage = false
        nextToiletDirtyMove = completedMoveCount + ToiletEventSettings.randomDirtyIntervalMoves()
        updateToiletVisualState()

        GameState.shared.addCoins(ToiletEventSettings.cleanRewardCoins)
        updateCoinLabel()
        showMessage("Toilet cleaned. +\(ToiletEventSettings.cleanRewardCoins) coins")
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

    private func handleShovelInteraction(node: SKSpriteNode) {
        if isShovelCarried {
            isShovelCarried = false
            node.position = player.position
            showMessage("Dropped shovel.")
            return
        }

        isShovelCarried = true
        showMessage("Picked up shovel.")
    }

    private func handleSepticDigTap(at scenePoint: CGPoint) -> Bool {
        guard let tappedTile = tileCoordinate(for: scenePoint),
              worldConfig.septicDigTiles.contains(tappedTile) else {
            return false
        }

        guard isShovelCarried else {
            showMessage("Pick up the shovel in the cellar first.")
            return true
        }

        if trenchedSepticTiles.contains(tappedTile) {
            showMessage("That trench tile is already dug.")
            return true
        }

        guard let digCenter = scenePointForTile(tappedTile) else {
            return true
        }

        let dx = digCenter.x - player.position.x
        let dy = digCenter.y - player.position.y
        let distance = hypot(dx, dy)
        if distance > 96 {
            showMessage("Move closer to dig this tile.")
            return true
        }

        applyTrench(at: tappedTile)
        trenchedSepticTiles.insert(tappedTile)
        GameState.shared.addCoins(coinsPerTrenchTile)
        updateCoinLabel()

        if trenchedSepticTiles.count == worldConfig.septicDigTiles.count && !hasAwardedSepticCompletionBonus {
            hasAwardedSepticCompletionBonus = true
            GameState.shared.addCoins(septicCompletionBonusCoins)
            updateCoinLabel()
            showMessage("Septic trench complete! +\(coinsPerTrenchTile + septicCompletionBonusCoins) coins")
        } else {
            showMessage("Dug trench tile! +\(coinsPerTrenchTile) coin")
        }

        return true
    }

    private func processToiletEventProgress(messages: inout [String]) {

        if !isToiletDirty,
           completedMoveCount >= nextToiletDirtyMove,
           isPlayerInBarRooms() {
            isToiletDirty = true
            toiletCleanDeadlineMove = completedMoveCount + ToiletEventSettings.cleanDeadlineMoves
            hasShownToiletPenaltyStartMessage = false
            updateToiletVisualState()
            messages.append("The toilet became dirty! Clean it with the brush within \(ToiletEventSettings.cleanDeadlineMoves) moves.")
        }

        guard isToiletDirty,
              let deadline = toiletCleanDeadlineMove,
              completedMoveCount > deadline else {
            return
        }

        if !hasShownToiletPenaltyStartMessage {
            hasShownToiletPenaltyStartMessage = true
            messages.append("Toilet is overdue. Losing \(ToiletEventSettings.overduePenaltyCoinsPerMove) coin\(ToiletEventSettings.overduePenaltyCoinsPerMove == 1 ? "" : "s") per move until cleaned.")
        }

        let penalty = ToiletEventSettings.overduePenaltyCoinsPerMove
        if penalty > 0 {
            let previousCoins = GameState.shared.coins
            let remainingCoins = GameState.shared.removeCoins(penalty)
            if remainingCoins != previousCoins {
                updateCoinLabel()
            }
        }
    }

    private func simulateMoves(_ count: Int) {
        guard count > 0 else { return }
        moveTarget = nil
        player.physicsBody?.velocity = .zero
        var showedEventMessage = false

        for _ in 0..<count {
            completedMoveCount += 1
            if processInteractableRespawns() {
                showedEventMessage = true
            }
        }

        updateStatusWindowBody()
        if !showedEventMessage {
            showMessage("Simulated \(count) moves.")
        }
    }

    private func scenePointForTile(_ tile: TileCoordinate) -> CGPoint? {
        guard let map = groundTileMap else { return nil }
        let localCenter = map.centerOfTile(atColumn: tile.column, row: tile.row)
        return map.convert(localCenter, to: self)
    }

    private func updateToiletVisualState() {
        guard let toiletNode = interactableNodesByID[toiletID],
              let toiletConfig = interactableConfigsByID[toiletID] else { return }

        let texture = isToiletDirty ? toiletDirtyTexture : toiletCleanTexture
        if let texture {
            toiletNode.texture = texture
            toiletNode.size = toiletConfig.size
            toiletNode.colorBlendFactor = 0
            return
        }

        let markerTexture = makeLabeledMarkerTexture(
            size: toiletConfig.size,
            emoji: isToiletDirty ? "!" : "T",
            color: isToiletDirty ? .systemBrown : .white
        )
        toiletNode.texture = markerTexture
        toiletNode.size = toiletConfig.size
        toiletNode.colorBlendFactor = 0
    }

    private func loadTexture(named name: String) -> SKTexture? {
        if let cachedTexture = cachedTexturesByName[name] {
            return cachedTexture
        }

        let texture = SKTexture(imageNamed: name)
        // Check if texture is valid - missing images may have non-zero size but invalid data
        // A valid texture should have both width and height > 0
        guard texture.size() != .zero, texture.size().width > 0, texture.size().height > 0 else {
            return nil
        }

        // Limit cache size to prevent unbounded growth
        // If cache gets too large, remove oldest entries (simple FIFO approach)
        if cachedTexturesByName.count > 50 {
            // Remove first 10 entries to make room
            let keysToRemove = Array(cachedTexturesByName.keys.prefix(10))
            for key in keysToRemove {
                cachedTexturesByName.removeValue(forKey: key)
            }
        }
        
        cachedTexturesByName[name] = texture
        return texture
    }

    private func applyTrench(at tile: TileCoordinate) {
        guard let map = groundTileMap,
              let trenchGroup = tileGroupsByName["septic_trench"] else { return }
        map.setTileGroup(trenchGroup, forColumn: tile.column, row: tile.row)
    }

    private func resetSepticDigTiles() {
        guard let map = groundTileMap,
              let defaultGroup = tileGroupsByName[worldConfig.defaultFloorTileName] else { return }
        for tile in worldConfig.septicDigTiles {
            map.setTileGroup(defaultGroup, forColumn: tile.column, row: tile.row)
        }
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
            region.tileName != "floor_carroll_sales" &&
            playerTile.column >= region.region.minColumn &&
            playerTile.column < region.region.maxColumnExclusive &&
            playerTile.row >= region.region.minRow &&
            playerTile.row < region.region.maxRowExclusive
        })
    }

    private func isPlayerInCarrollSalesArea() -> Bool {
        guard let playerTile = tileCoordinate(for: player.position) else { return false }
        return tileRegionContains(worldConfig.carrollSalesRegion, tile: playerTile)
    }

    private func isSnowmobileDrivable(at scenePoint: CGPoint) -> Bool {
        guard let tile = tileCoordinate(for: scenePoint),
              let map = groundTileMap else { return false }

        guard let floorTileName = map.tileGroup(atColumn: tile.column, row: tile.row)?.name else {
            return false
        }

        return !indoorSnowmobileBlockedFloorTiles.contains(floorTileName)
    }

    private func updateMountedSnowmobileUI() {
        let isMounted = mountedSnowmobileID != nil
        player.alpha = 1.0
        player.zPosition = isMounted ? 21 : 20
    }

    private func tileRegionContains(_ region: TileRegion, tile: TileCoordinate) -> Bool {
        tile.column >= region.minColumn &&
        tile.column < region.maxColumnExclusive &&
        tile.row >= region.minRow &&
        tile.row < region.maxRowExclusive
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
        isMapViewMode = false
        isDraggingMap = false
        cameraNode.setScale(1)
        mapCloseButtonNode?.isHidden = true
        setSnowmobileChoiceDialogVisible(false)
        player.position = playerSpawnPosition
        cameraNode.position = playerSpawnPosition
        completedMoveCount = 0
        respawnAtMoveByInteractableID.removeAll()
        isBucketCarried = false
        bucketPotatoCount = 0
        washedPotatoCount = 0
        selectedPotatoForLoading = false
        selectedPotatoIsWashed = false
        peelerHasSlicedPotatoes = false
        fryerSlicedPotatoCount = 0
        isChipsBasketCarried = false
        basketSlicedPotatoCount = 0
        chipsBasketContainsChips = false
        isToiletBowlBrushCarried = false
        isToiletDirty = false
        toiletCleanDeadlineMove = nil
        nextToiletDirtyMove = ToiletEventSettings.randomDirtyIntervalMoves()
        hasShownToiletPenaltyStartMessage = false
        // Restore visual state of the toilet to match the reset logical state
        updateToiletVisualState()
        isTennisRacketCarried = false
        isShovelCarried = false
        ownedSnowmobileIDs.removeAll()
        selectedOwnedSnowmobileID = nil
        mountedSnowmobileID = nil
        updateMountedSnowmobileUI()
        updateSnowmobileOwnershipVisuals()
        nextBatSpawnMove = BatEventSettings.randomSpawnIntervalMoves()
        batDefeatDeadlineMove = nil
        trenchedSepticTiles.removeAll()
        hasAwardedSepticCompletionBonus = false
        resetSepticDigTiles()
        updateMakerLoadedIndicator()
        for (_, interactableNode) in interactableNodesByID {
            interactableNode.isHidden = false
        }
        for (id, homePosition) in interactableHomePositionByID {
            interactableNodesByID[id]?.position = homePosition
        }
        interactableNodesByID[bedroomBatID]?.isHidden = true

        GameState.shared.resetCoins()
        GameState.shared.addCoins(200)
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
