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

enum ZLayer {
    // World-space render order (low -> high): floor, tile objects, decorations/interactables, player.
    static let worldFloor: CGFloat = -10
    static let worldFloorOverlay: CGFloat = -5
    static let worldObjects: CGFloat = 10
    static let decoration: CGFloat = 18
    static let interactable: CGFloat = 20

    // Player uses two layers so mounted state can reliably draw above same-depth interactables.
    static let playerBase: CGFloat = 20
    static let playerMounted: CGFloat = 21
    static let debugLabel: CGFloat = 30

    // HUD/menu/dialog layers are attached to cameraNode and draw above world-space content.
    static let hud: CGFloat = 500
    static let warningHUD: CGFloat = 515
    static let menuButton: CGFloat = 520
    static let menuPanel: CGFloat = 520
    static let menuPanelButton: CGFloat = 521
    static let menuPanelLabel: CGFloat = 522
    static let mapCloseButton: CGFloat = 530
    static let mapCloseLabel: CGFloat = 531

    static let snowmobileBackdrop: CGFloat = 740
    static let snowmobilePanel: CGFloat = 741
    static let snowmobilePanelControl: CGFloat = 742
    static let snowmobilePanelLabel: CGFloat = 743

    static let scrollTextDialog: CGFloat = 742
    static let studyBackdrop: CGFloat = 744
    static let studyPanel: CGFloat = 745
    static let studyPanelControl: CGFloat = 746
    static let studyPanelLabel: CGFloat = 747
    static let quizDialog: CGFloat = 748
    static let searsCatalogDialog: CGFloat = 749

    static let resetBackdrop: CGFloat = 750
    static let resetPanel: CGFloat = 751
    static let resetPanelControl: CGFloat = 752
    static let resetPanelLabel: CGFloat = 753

    static let settingsDialog: CGFloat = 760
    static let bearAttackOverlay: CGFloat = 900
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
        "vehicle_assembly_area",
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
    private static let requiredSnowmobileCount = 6

    private enum FacingDirection {
        case up
        case down
        case left
        case right

        var tileOffset: (dc: Int, dr: Int) {
            switch self {
            case .up:
                return (0, 1)
            case .down:
                return (0, -1)
            case .left:
                return (-1, 0)
            case .right:
                return (1, 0)
            }
        }
    }

    private static let introShownDefaultsKey = "ut.intro.shown"

    private let introDialogParagraphs: [String] = [
        "You are a family member who lives and works at Cramer's Little Valley bar.",
        "A global disaster is pending, and only you can prevent calamity. To save the world, you must build a huge snowmobile (assembled from 6 regular snowmobiles) and travel to China to set off atomic tubes that will save the world. This will require a lot of resources, so first you must work at the bar to earn coins - all while going to high school and getting good grades.",
        "Game hints:",
        "- Move by tapping on the place you want to be.",
        "- Interact with an object by moving right next to it, and tapping on it.",
        "- Get a bird's-eye view of the world by using the map, available through the menu at the upper right of the screen.",
        "- Pay attention to tasks assigned to you. Small icons at the lower left of the screen remind you of the tasks that you must perform soon to avoid penalty."
    ]

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

    private enum FoodOrderEventSettings {
        static var minSpawnIntervalMoves: Int {
            UTSettings.shared.counts.foodOrderMinMoves
        }

        static var maxSpawnIntervalMoves: Int {
            UTSettings.shared.counts.foodOrderMaxMoves
        }

        static var deliverDeadlineMoves: Int {
            UTSettings.shared.counts.foodOrderDeliverDeadlineMoves
        }

        static var nonDeliveryPenaltyCoins: Int {
            UTSettings.shared.counts.foodOrderNonDeliveryPenaltyCoins
        }

        static func randomSpawnIntervalMoves() -> Int {
            Int.random(in: minSpawnIntervalMoves...maxSpawnIntervalMoves)
        }
    }

    private enum HUDMessageLayout {
        static let maxLines = 3
        static let horizontalMargin: CGFloat = 32
        static let minPreferredWidth: CGFloat = 220
        static let topPadding: CGFloat = 56
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
    private var scrollTextDialogNode: ScrollTextDialogNode!
    private var studySubjectBackdropNode: SKShapeNode!
    private var studySubjectPanelNode: SKShapeNode!
    private var quizDialogNode: QuizDialogNode!
    var searsCatalogBackdropNode: SKShapeNode!
    var searsCatalogPanelNode: SKShapeNode!
    var searsCatalogAlertBackdropNode: SKShapeNode!
    var searsCatalogItemCheckboxNode: SKLabelNode!
    var searsCatalogAlertPanelNode: SKShapeNode!
    var searsCatalogAlertMessageLabel: SKLabelNode!
    var searsCatalogItemChecked = false
    var isSearsCatalogDialogVisible = false
    var isSearsCatalogAlertVisible = false
    private var resetConfirmBackdropNode: SKShapeNode!
    private var resetConfirmPanelNode: SKShapeNode!
    private var snowmobileChoiceBackdropNode: SKShapeNode!
    private var snowmobileChoicePanelNode: SKShapeNode!
    private var snowmobileChoiceSubtitleLabel: SKLabelNode!
    private var pendingLotSnowmobileID: String?
    private var warningIconContainerNode: SKNode!
    private var warningBatIconNode: SKSpriteNode!
    private var warningSnowmobileIconNode: SKSpriteNode!
    private var warningToiletIconNode: SKSpriteNode!
    private var warningFoodOrderIconNode: SKSpriteNode!
    private var warningTrenchIconNode: SKSpriteNode!
    private var makerLoadedIndicatorNode: SKShapeNode?
    private var bucketSelectedIndicatorNode: SKShapeNode?
    private var bucketPotatoIconNode: SKSpriteNode?
    private var traySlicesIconNode: SKSpriteNode?
    private var fryerChipsIconNode: SKSpriteNode?
    private var basketChipsIconNode: SKSpriteNode?
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
    private let trayID = "tray"
    private let chipsBasketID = "chipsBasket"
    private let spigotID = "spigot"
    private let toiletID = "toilet"
    private let toiletCleanSpriteName = "toilet"
    private let toiletDirtySpriteName = "toilet_dirty"
    private let toiletBowlBrushID = "toiletBowlBrush"
    private let tennisRacketID = "tennisRacket"
    private let bedroomBatID = "bedroomBat"
    private let shovelID = "shovel"
    private let mailboxID = "mailbox"
    private let barCustomerID = "barCustomer"
    private let envelopeID = "envelope"
    private let goatChaseSpotID = "goatChaseSpot"
    private let parkingCarDecorationIDs = ["parkingCarSedan", "parkingCarPickupTruck", "parkingCarStationWagon"]
    private let bucketCapacity = 5
    let searsCatalogRaftPriceCoins = 50

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

    private var hasPendingSnowmobileTask: Bool {
        ownedSnowmobileIDs.count < Self.requiredSnowmobileCount
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
    private var isTrayCarried = false
    private var traySlicedPotatoCount = 0
    private var isChipsBasketCarried = false
    private var chipsBasketChipCount = 0
    private var isToiletBowlBrushCarried = false
    private var isToiletDirty = false
    private var toiletCleanDeadlineMove: Int?
    private var nextToiletDirtyMove = ToiletEventSettings.randomDirtyIntervalMoves()
    private var hasShownToiletPenaltyStartMessage = false
    private var isTennisRacketCarried = false
    private var isShovelCarried = false
    private var isEnvelopeCarried = false
    private var carriedRaftID: String?
    private var riddenRaftID: String?
    private var pendingRaftDeliveryMoves: [Int] = []
    private var nextRaftSequenceID = 1
    private var ownedSnowmobileIDs: Set<String> = []
    private var selectedOwnedSnowmobileID: String?
    private var mountedSnowmobileID: String?
    private var nextBatSpawnMove = BatEventSettings.randomSpawnIntervalMoves()
    private var batDefeatDeadlineMove: Int?
    private var nextFoodOrderMove = FoodOrderEventSettings.randomSpawnIntervalMoves()
    private var foodOrderDeadlineMove: Int?
    private var hasShownFirstSuccessfulChipDeliveryMessage = false
    private var trenchedSepticTiles: Set<TileCoordinate> = []
    private var hasAwardedSepticCompletionBonus = false
    private var toiletCleanTexture: SKTexture?
    private var toiletDirtyTexture: SKTexture?

    private var isStatusWindowVisible = false
    private var isPendingTasksWindowVisible = false
    private var isStudySubjectPromptVisible = false
    private var isMapViewMode = false
    private var isDraggingMap = false
    private var lastMapDragPoint = CGPoint.zero
    private var mapModeSavedCameraPosition = CGPoint.zero
    private var mapModeSavedCameraScale: CGFloat = 1
    private let mapViewZoomOutScale: CGFloat = 2.5

    private var moveTarget: CGPoint?
    private var moveTargetArrivalDistance: CGFloat = 12
    private var bestMoveTargetDistance: CGFloat?
    private var stalledMoveFrameCount = 0
    private let stalledMoveFrameLimit = 8
    private let stalledMoveDistanceEpsilon: CGFloat = 0.5
    private var lastMoveDirection: FacingDirection = .down
    private var lastUpdateTime: TimeInterval = 0
    private var isSaveDirty = false
    private var lastAutosaveTimestamp: TimeInterval = 0
    private let autosaveIntervalSeconds: TimeInterval = 2.0
    private var hasAttemptedSaveRestore = false
    private var playerSpawnPosition: CGPoint = .zero
    private var completedMoveCount = 0
    private var isBearAttackInProgress = false
    private let worldConfig = WorldConfig.current
    private lazy var teacherDeskSubjectByID: [String: String] = {
        var map: [String: String] = [:]
        for desk in worldConfig.teachersDesks {
            map[desk.interactableID] = desk.subject.quizSubjectName
        }
        return map
    }()

    private var worldColumns: Int { worldConfig.recommendedWorldColumns }
    private let worldRows = 70
    private let tileSize = CGSize(width: 64, height: 64)
    private let playerMoveSpeed: CGFloat = 500
    private let mountedSnowmobileSpeedMultiplier: CGFloat = 4.0
    private let mountedSnowmobileVerticalOffset: CGFloat = -12
    private let mountedRaftSpeedMultiplier: CGFloat = 1.15
    private let carriedRaftVerticalOffset: CGFloat = -28
    private let indoorSnowmobileBlockedFloorTiles: Set<String> = ["floor_wood", "floor_linoleum", "floor_carpet"]
    private var bearProximityColumns: Int { UTSettings.shared.counts.bearProximityColumns }
    private var bearProximityRows: Int { UTSettings.shared.counts.bearProximityRows }
    private let walkingBobAmplitude: CGFloat = 2.5
    private let walkingBobCyclesPerSecond: CGFloat = 3.5
    private var walkingBobPhase: CGFloat = 0
    private var walkingBobOffsetY: CGFloat = 0
    private var previousPlayerPositionForWalkAnimation: CGPoint?
    private var walkingAnimationDeltaTime: CGFloat = 1.0 / 60.0

    private var raftSize: CGSize {
        CGSize(width: tileSize.width * 2, height: tileSize.height * 2)
    }

    private func clearMoveTarget() {
        moveTarget = nil
        moveTargetArrivalDistance = 12
        bestMoveTargetDistance = nil
        stalledMoveFrameCount = 0
    }

    private func setMoveTarget(_ point: CGPoint, arrivalDistance: CGFloat = 12) {
        moveTarget = point
        moveTargetArrivalDistance = max(1, arrivalDistance)
        bestMoveTargetDistance = nil
        stalledMoveFrameCount = 0
    }

    func markSaveDirty() {
        isSaveDirty = true
    }

    private func updateLastMoveDirection(from movementDelta: CGVector) {
        let threshold: CGFloat = 0.2
        guard abs(movementDelta.dx) > threshold || abs(movementDelta.dy) > threshold else {
            return
        }

        if abs(movementDelta.dx) >= abs(movementDelta.dy) {
            lastMoveDirection = movementDelta.dx >= 0 ? .right : .left
        } else {
            lastMoveDirection = movementDelta.dy >= 0 ? .up : .down
        }
    }

    private func tileCanContainDroppedObject(_ tile: TileCoordinate, droppingInteractableID: String) -> Bool {
        guard tile.column >= 0,
              tile.column < worldColumns,
              tile.row >= 0,
              tile.row < worldRows else {
            return false
        }

        if worldConfig.wallTiles.contains(tile) {
            return false
        }

        if worldConfig.decorations.contains(where: { $0.blocksMovement && $0.tile == tile }) {
            return false
        }

        for (id, node) in interactableNodesByID {
            if id == droppingInteractableID || node.isHidden {
                continue
            }
            guard let occupiedTile = tileCoordinate(for: node.position) else {
                continue
            }
            if occupiedTile == tile {
                return false
            }
        }

        return true
    }

    private func candidateDropTiles(from originTile: TileCoordinate) -> [TileCoordinate] {
        let forward = lastMoveDirection.tileOffset
        let right = (dc: forward.dr, dr: -forward.dc)
        let left = (dc: -forward.dr, dr: forward.dc)
        let behind = (dc: -forward.dc, dr: -forward.dr)

        let offsets = [forward, right, left, behind]
        return offsets.map { offset in
            TileCoordinate(column: originTile.column + offset.dc, row: originTile.row + offset.dr)
        }
    }

    private func dropCarriedObject(_ node: SKSpriteNode, interactableID: String) {
        let startPosition = player.position
        node.removeAllActions()
        node.position = startPosition

        guard let playerTile = tileCoordinate(for: player.position) else {
            return
        }

        let targetTile = candidateDropTiles(from: playerTile).first(where: { tileCanContainDroppedObject($0, droppingInteractableID: interactableID) })
        guard let targetTile,
              let targetPosition = scenePointForTile(targetTile) else {
            return
        }

        let slide = SKAction.move(to: targetPosition, duration: 0.16)
        slide.timingMode = .easeOut
        node.run(slide)
    }

    private func updateWalkingAnimation(deltaTime: CGFloat, movementDelta: CGVector, isWalkingOnFoot: Bool) {
        let movementDistance = hypot(movementDelta.dx, movementDelta.dy)
        guard isWalkingOnFoot, movementDistance > 0.25 else {
            walkingBobOffsetY = 0
            player.setVisualVerticalOffset(0)
            return
        }

        walkingBobPhase += deltaTime * walkingBobCyclesPerSecond * (.pi * 2)
        if walkingBobPhase > (.pi * 2) {
            walkingBobPhase.formTruncatingRemainder(dividingBy: (.pi * 2))
        }

        let wave = sin(walkingBobPhase)
        walkingBobOffsetY = wave * walkingBobAmplitude

        player.setVisualVerticalOffset(walkingBobOffsetY)
    }

    private func savedPoint(from point: CGPoint) -> SavedPoint {
        SavedPoint(x: Double(point.x), y: Double(point.y))
    }

    private func point(from savedPoint: SavedPoint) -> CGPoint {
        CGPoint(x: savedPoint.x, y: savedPoint.y)
    }

    private func isWallBlocked(at scenePoint: CGPoint) -> Bool {
        guard let tile = tileCoordinate(for: scenePoint) else { return true }
        return worldConfig.wallTiles.contains(tile)
    }

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
        tileMap.zPosition = ZLayer.worldFloor
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
        buildRiverOverlay(on: tileMap)
        
        // Second tile layer for walls, furniture, etc.
        let objectTileMap = SKTileMapNode(
            tileSet: tileSet,
            columns: worldColumns,
            rows: worldRows,
            tileSize: tileSize
        )
        objectTileMap.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        objectTileMap.position = .zero
        objectTileMap.zPosition = ZLayer.worldObjects   // above the floor
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
        player.zPosition = ZLayer.playerBase
        addChild(player)
        previousPlayerPositionForWalkAnimation = player.position

        // --- CAMERA ---
        cameraNode = SKCameraNode()
        camera = cameraNode
        addChild(cameraNode)

        // Make sure the camera starts on the player immediately
        cameraNode.position = player.position

        configureHUD()
        updateCoinLabel()
        updateStatusWindowBody()
        restoreGameFromDiskIfAvailable()
        if interactableNodesByID[goatChaseSpotID]?.isHidden == false {
            placeGoatOnRandomParkingCar()
        }
        presentIntroIfFirstRun()

    }

    override func didSimulatePhysics() {
        if let ridingRaftID = riddenRaftID,
           let raftNode = interactableNodesByID[ridingRaftID] {
            raftNode.position = player.position
            raftNode.zPosition = ZLayer.interactable
            player.zPosition = ZLayer.playerMounted
        }

        if let mountedID = mountedSnowmobileID,
           let snowmobileNode = interactableNodesByID[mountedID] {
            snowmobileNode.position = CGPoint(
                x: player.position.x,
                y: player.position.y + mountedSnowmobileVerticalOffset
            )
            // Mounted snowmobile stays at interactable depth; rider is one layer above it.
            snowmobileNode.zPosition = ZLayer.interactable
            player.zPosition = ZLayer.playerMounted
        } else {
            // On foot, player returns to normal world actor depth.
            player.zPosition = ZLayer.playerBase
        }
        if isBucketCarried, let bucketNode = interactableNodesByID[bucketID] {
            bucketNode.position = CGPoint(x: player.position.x + 22, y: player.position.y + 8)
        }
        if isTrayCarried, let trayNode = interactableNodesByID[trayID] {
            trayNode.position = CGPoint(x: player.position.x - 22, y: player.position.y + 8)
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
        if isEnvelopeCarried, let envelopeNode = interactableNodesByID[envelopeID] {
            envelopeNode.position = CGPoint(x: player.position.x + 24, y: player.position.y - 4)
            envelopeNode.isHidden = false
        }
        if let raftID = carriedRaftID,
           let raftNode = interactableNodesByID[raftID],
           riddenRaftID != raftID {
            raftNode.position = CGPoint(x: player.position.x, y: player.position.y + carriedRaftVerticalOffset)
            raftNode.isHidden = false
        }
        if let bucketNode = interactableNodesByID[bucketID] {
            bucketSelectedIndicatorNode?.position = CGPoint(x: bucketNode.position.x, y: bucketNode.position.y + 22)
        }
        updateWarningIcons()
        checkBearProximity()
        if isPendingTasksWindowVisible {
            updatePendingTasksWindowBody()
        }
        updateSnowmobileOwnershipVisuals()
        updateBucketSelectedIndicator()
        updateBucketPotatoIcon()
        updateFoodStateIcons()
        clampPlayerPositionToWorldBounds()

        let previousPosition = previousPlayerPositionForWalkAnimation ?? player.position
        let movementDelta = CGVector(
            dx: player.position.x - previousPosition.x,
            dy: player.position.y - previousPosition.y
        )
        updateLastMoveDirection(from: movementDelta)
        let isWalkingOnFoot = mountedSnowmobileID == nil && !isMapViewMode && moveTarget != nil
        updateWalkingAnimation(
            deltaTime: walkingAnimationDeltaTime,
            movementDelta: movementDelta,
            isWalkingOnFoot: isWalkingOnFoot
        )
        previousPlayerPositionForWalkAnimation = player.position

        if !isMapViewMode {
            cameraNode.position = player.position
        }
    }

    private func clampPlayerPositionToWorldBounds() {
        let halfWorldWidth = CGFloat(worldColumns) * tileSize.width * 0.5
        let halfWorldHeight = CGFloat(worldRows) * tileSize.height * 0.5
        let clampedX = min(max(player.position.x, -halfWorldWidth), halfWorldWidth)
        let clampedY = min(max(player.position.y, -halfWorldHeight), halfWorldHeight)
        if clampedX != player.position.x || clampedY != player.position.y {
            player.position = CGPoint(x: clampedX, y: clampedY)
            player.physicsBody?.velocity = .zero
        }
    }

    override func didChangeSize(_ oldSize: CGSize) {
        super.didChangeSize(oldSize)
        updateMessageLabelLayout()
        updateWarningIconContainerPosition()
        updateMapCloseButtonPosition()
        settingsDialogNode?.updateLayout(sceneSize: size)
        scrollTextDialogNode?.updateLayout(sceneSize: size)
        quizDialogNode?.updateLayout(sceneSize: size)
        configureSearsCatalogDialog()
        if isMapViewMode {
            clampCameraPositionToWorldBounds()
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard !isBearAttackInProgress else { return }
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

        if scrollTextDialogNode?.isVisible == true {
            if scrollTextDialogNode.endDrag() {
                return
            }
            _ = scrollTextDialogNode.handleTap(hudNodes: hudNodes)
            return
        }

        if quizDialogNode?.isVisible == true {
            _ = quizDialogNode.handleTap(hudNodes: hudNodes)
            return
        }

        if handleSearsCatalogHUDTap(hudNodes: hudNodes) {
            return
        }

        if isStudySubjectPromptVisible {
            if hudNodes.contains(where: { $0.name == "studySubjectUSHistItem" || $0.parent?.name == "studySubjectUSHistItem" }) {
                openStudyBackgroundWindow(for: "US History")
            } else if hudNodes.contains(where: { $0.name == "studySubjectEnglishItem" || $0.parent?.name == "studySubjectEnglishItem" }) {
                openStudyBackgroundWindow(for: "English")
            } else if hudNodes.contains(where: { $0.name == "studySubjectMathItem" || $0.parent?.name == "studySubjectMathItem" }) {
                openStudyBackgroundWindow(for: "Mathematics")
            } else if hudNodes.contains(where: { $0.name == "studySubjectScienceItem" || $0.parent?.name == "studySubjectScienceItem" }) {
                openStudyBackgroundWindow(for: "Science")
            } else {
                setStudySubjectPromptVisible(false)
            }
            return
        }

        if !resetConfirmPanelNode.isHidden {
            if hudNodes.contains(where: { $0.name == "resetConfirmYesItem" || $0.parent?.name == "resetConfirmYesItem" }) {
                setResetConfirmationVisible(false)
                resetGameToInitialState()
                setMenuVisible(false)
            } else {
                setResetConfirmationVisible(false)
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

        if warningIconStackContains(hudLocation) {
            setPendingTasksWindowVisible(true)
            setMenuVisible(false)
            return
        }

        if hudNodes.contains(where: { $0.name == "hamburgerButton" || $0.parent?.name == "hamburgerButton" }) {
            setMenuVisible(menuPanelNode.isHidden)
            return
        }
        if hudNodes.contains(where: { $0.name == "menuIntroItem" || $0.parent?.name == "menuIntroItem" }) {
            openIntroWindow()
            setMenuVisible(false)
            return
        }
        if hudNodes.contains(where: { $0.name == "menuStatusItem" || $0.parent?.name == "menuStatusItem" }) {
            setStatusWindowVisible(true)
            setMenuVisible(false)
            return
        }
        if hudNodes.contains(where: { $0.name == "menuResetItem" || $0.parent?.name == "menuResetItem" }) {
            setResetConfirmationVisible(true)
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
            markSaveDirty()
            return
        }

        if let interactableID = interactableID(at: location) {
            clearMoveTarget()
            player.physicsBody?.velocity = .zero
            performInteractionIfPossible(interactableID: interactableID)
            markSaveDirty()
            return
        }

        setMenuVisible(false)
        setMoveTarget(location)
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard !isBearAttackInProgress else { return }
        guard let touch = touches.first else { return }
        let hudLocation = touch.location(in: cameraNode)

        if settingsDialogNode?.isVisible == true {
            settingsDialogNode.beginDrag(at: hudLocation)
            return
        }

        if scrollTextDialogNode?.isVisible == true {
            scrollTextDialogNode.beginDrag(at: hudLocation)
            return
        }

        if quizDialogNode?.isVisible == true {
            return
        }

        if shouldBlockWorldInputForSearsModal() {
            return
        }

        if isStudySubjectPromptVisible {
            return
        }

        if !resetConfirmPanelNode.isHidden {
            return
        }

        if isMapViewMode {
            isDraggingMap = true
            lastMapDragPoint = hudLocation
            return
        }
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard !isBearAttackInProgress else { return }
        guard let touch = touches.first else { return }
        let hudLocation = touch.location(in: cameraNode)

        if settingsDialogNode?.isVisible == true {
            _ = settingsDialogNode.drag(to: hudLocation)
            return
        }

        if scrollTextDialogNode?.isVisible == true {
            _ = scrollTextDialogNode.drag(to: hudLocation)
            return
        }

        if quizDialogNode?.isVisible == true {
            return
        }

        if shouldBlockWorldInputForSearsModal() {
            return
        }

        if isStudySubjectPromptVisible {
            return
        }

        if !resetConfirmPanelNode.isHidden {
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
    }

    override func update(_ currentTime: TimeInterval) {
        guard let body = player.physicsBody else { return }

        let deltaTime: CGFloat
        if lastUpdateTime > 0 {
            let rawDelta = currentTime - lastUpdateTime
            deltaTime = CGFloat(min(max(rawDelta, 1.0 / 120.0), 1.0 / 20.0))
        } else {
            deltaTime = 1.0 / 60.0
        }
        lastUpdateTime = currentTime
        walkingAnimationDeltaTime = deltaTime

        if isSaveDirty, currentTime - lastAutosaveTimestamp >= autosaveIntervalSeconds {
            saveGameStateNow()
            lastAutosaveTimestamp = currentTime
        }

        if isMapViewMode {
            body.velocity = .zero
            return
        }
        guard let target = moveTarget else {
            body.velocity = .zero
            bestMoveTargetDistance = nil
            stalledMoveFrameCount = 0
            return
        }

        let dx = target.x - player.position.x
        let dy = target.y - player.position.y
        let distance = hypot(dx, dy)

        if distance < moveTargetArrivalDistance {
            clearMoveTarget()
            body.velocity = .zero
            completedMoveCount += 1
            processInteractableRespawns()
            markSaveDirty()
            return
        }

        if let ridingRaftID = riddenRaftID {
            bestMoveTargetDistance = nil
            stalledMoveFrameCount = 0

            guard let raftNode = interactableNodesByID[ridingRaftID] else {
                riddenRaftID = nil
                body.velocity = .zero
                return
            }

            let playerTile = tileCoordinate(for: player.position)
            let targetTile = tileCoordinate(for: target)
                let shoreTapDistance = hypot(target.x - player.position.x, target.y - player.position.y)
            if let playerTile, let targetTile,
                    isRiverTile(playerTile),
               !isRiverTile(targetTile),
               canDismountRaftToShore(from: playerTile),
                    shoreTapDistance <= (tileSize.width * 1.75),
               !isWallBlocked(at: target) {
                riddenRaftID = nil
                player.position = target
                body.velocity = .zero
                clearMoveTarget()
                showMessage("Exited raft.")
                return
            }

            let moveSpeed = playerMoveSpeed * mountedRaftSpeedMultiplier
            let stepDistance = min(distance, moveSpeed * deltaTime)
            let nextProbePoint = CGPoint(
                x: player.position.x + (dx / distance) * stepDistance,
                y: player.position.y + (dy / distance) * stepDistance
            )

            guard let nextTile = tileCoordinate(for: nextProbePoint), isRiverTile(nextTile) else {
                clearMoveTarget()
                body.velocity = .zero
                showMessage("Raft can only move in the river.")
                return
            }

            raftNode.position = nextProbePoint
            player.position = nextProbePoint
            body.velocity = .zero

            let remainingDx = target.x - player.position.x
            let remainingDy = target.y - player.position.y
            let remainingDistance = hypot(remainingDx, remainingDy)
            if remainingDistance < moveTargetArrivalDistance {
                clearMoveTarget()
                completedMoveCount += 1
                processInteractableRespawns()
                markSaveDirty()
            }
            return
        }

        if mountedSnowmobileID != nil {
            bestMoveTargetDistance = nil
            stalledMoveFrameCount = 0

            let moveSpeed = playerMoveSpeed * mountedSnowmobileSpeedMultiplier
            let stepDistance = min(distance, moveSpeed * deltaTime)
            let nextProbePoint = CGPoint(
                x: player.position.x + (dx / distance) * stepDistance,
                y: player.position.y + (dy / distance) * stepDistance
            )

            guard !isWallBlocked(at: nextProbePoint) else {
                clearMoveTarget()
                body.velocity = .zero
                return
            }

            guard let nextTile = tileCoordinate(for: nextProbePoint), !isRiverTile(nextTile) else {
                clearMoveTarget()
                body.velocity = .zero
                showMessage("Snowmobiles cannot enter the river.")
                return
            }

            guard isSnowmobileDrivable(at: nextProbePoint) else {
                clearMoveTarget()
                body.velocity = .zero
                showMessage("Snowmobiles cannot go inside buildings.")
                return
            }

            player.position = nextProbePoint
            body.velocity = .zero

            let remainingDx = target.x - player.position.x
            let remainingDy = target.y - player.position.y
            let remainingDistance = hypot(remainingDx, remainingDy)
            if remainingDistance < moveTargetArrivalDistance {
                clearMoveTarget()
                completedMoveCount += 1
                processInteractableRespawns()
                markSaveDirty()
            }
            return
        }

        if let bestDistance = bestMoveTargetDistance {
            if distance < bestDistance - stalledMoveDistanceEpsilon {
                bestMoveTargetDistance = distance
                stalledMoveFrameCount = 0
            } else {
                stalledMoveFrameCount += 1
                if stalledMoveFrameCount >= stalledMoveFrameLimit {
                    clearMoveTarget()
                    body.velocity = .zero
                    return
                }
            }
        } else {
            bestMoveTargetDistance = distance
        }

        let moveSpeed = playerMoveSpeed
        let stepDistance = min(distance, moveSpeed * deltaTime)
        let nextProbePoint = CGPoint(
            x: player.position.x + (dx / distance) * stepDistance,
            y: player.position.y + (dy / distance) * stepDistance
        )
        if let nextTile = tileCoordinate(for: nextProbePoint), isRiverTile(nextTile) {
            clearMoveTarget()
            body.velocity = .zero
            showMessage("You can enter the river only by stepping into a raft.")
            return
        }

        let vx = (dx / distance) * moveSpeed
        let vy = (dy / distance) * moveSpeed
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
        label.zPosition = ZLayer.debugLabel
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
        bucketPotatoIconNode?.removeFromParent()
        bucketPotatoIconNode = nil
        traySlicesIconNode?.removeFromParent()
        traySlicesIconNode = nil
        fryerChipsIconNode?.removeFromParent()
        fryerChipsIconNode = nil
        basketChipsIconNode?.removeFromParent()
        basketChipsIconNode = nil

        for config in worldConfig.interactables {
            let center = tileMap.centerOfTile(atColumn: config.tile.column, row: config.tile.row)
            let basePosition = tileMap.convert(center, to: self)
            let placementOffset = interactablePlacementOffset(for: config)
            let position = CGPoint(x: basePosition.x + placementOffset.x, y: basePosition.y + placementOffset.y)

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
                } else if config.kind == .tray {
                    let trayTexture = makeLabeledMarkerTexture(size: config.size, emoji: "T", color: .systemGray)
                    node = SKSpriteNode(texture: trayTexture, color: .clear, size: config.size)
                } else if config.kind == .chipsBasket {
                    let basketTexture = makeLabeledMarkerTexture(size: config.size, emoji: "B", color: .systemOrange)
                    node = SKSpriteNode(texture: basketTexture, color: .clear, size: config.size)
                } else if config.kind == .snowmobile {
                    let snowmobileTexture = makeLabeledMarkerTexture(size: config.size, emoji: "S", color: .systemTeal)
                    node = SKSpriteNode(texture: snowmobileTexture, color: .clear, size: config.size)
                } else if config.kind == .toilet {
                    let toiletTexture = makeLabeledMarkerTexture(size: config.size, emoji: "T", color: .white)
                    node = SKSpriteNode(texture: toiletTexture, color: .clear, size: config.size)
                } else if config.kind == .studyGuide {
                    let guideTexture = makeLabeledMarkerTexture(size: config.size, emoji: "📘", color: .systemBlue)
                    node = SKSpriteNode(texture: guideTexture, color: .clear, size: config.size)
                } else if config.kind == .searsCatalog {
                    let catalogTexture = makeLabeledMarkerTexture(size: config.size, emoji: "📕", color: .systemRed)
                    node = SKSpriteNode(texture: catalogTexture, color: .clear, size: config.size)
                } else if config.kind == .mailbox {
                    let mailboxTexture = makeLabeledMarkerTexture(size: config.size, emoji: "M", color: .systemBlue)
                    node = SKSpriteNode(texture: mailboxTexture, color: .clear, size: config.size)
                } else if config.kind == .envelope {
                    let envelopeTexture = makeLabeledMarkerTexture(size: config.size, emoji: "E", color: .systemYellow)
                    node = SKSpriteNode(texture: envelopeTexture, color: .clear, size: config.size)
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
                } else if config.kind == .raft {
                    let raftTexture = makeLabeledMarkerTexture(size: config.size, emoji: "R", color: .systemBrown)
                    node = SKSpriteNode(texture: raftTexture, color: .clear, size: config.size)
                } else {
                    node = SKSpriteNode(color: .systemYellow, size: config.size)
                }
            }

            node.name = "interactable:\(config.id)"
            node.position = position
            node.zPosition = ZLayer.interactable

            let body = SKPhysicsBody(rectangleOf: node.size)
            body.isDynamic = false
            if config.kind == .mailbox || config.kind == .barCustomer {
                body.categoryBitMask = PhysicsCategory.wall
                body.collisionBitMask = PhysicsCategory.player
                body.contactTestBitMask = PhysicsCategory.none
            } else {
                body.categoryBitMask = PhysicsCategory.interactable
                body.collisionBitMask = PhysicsCategory.none
                body.contactTestBitMask = PhysicsCategory.player
            }
            node.physicsBody = body

            addChild(node)
            interactableNodesByID[config.id] = node
            interactableConfigsByID[config.id] = config
            interactableHomePositionByID[config.id] = position

            if config.id == bedroomBatID {
                node.isHidden = true
            }
            if config.id == envelopeID {
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

                let iconSize = CGSize(width: max(12, node.size.width * 0.3), height: max(12, node.size.height * 0.3))
                let iconNode: SKSpriteNode
                if let potatoTexture = loadTexture(named: "potato_icon") {
                    iconNode = SKSpriteNode(texture: potatoTexture, color: .clear, size: iconSize)
                } else {
                    let fallbackTexture = makeLabeledMarkerTexture(size: iconSize, emoji: "🥔", color: .systemBrown)
                    iconNode = SKSpriteNode(texture: fallbackTexture, color: .clear, size: iconSize)
                }
                iconNode.name = "bucketPotatoIcon"
                iconNode.position = CGPoint(x: 0, y: -node.size.height * 0.12)
                iconNode.zPosition = 5
                iconNode.isHidden = true
                node.addChild(iconNode)
                bucketPotatoIconNode = iconNode
            } else if config.id == trayID {
                let iconSize = CGSize(width: max(12, node.size.width * 0.34), height: max(12, node.size.height * 0.34))
                let iconNode: SKSpriteNode
                if let texture = loadTexture(named: "potato_slices_icon") {
                    iconNode = SKSpriteNode(texture: texture, color: .clear, size: iconSize)
                } else {
                    let fallbackTexture = makeLabeledMarkerTexture(size: iconSize, emoji: "🥔", color: .systemOrange)
                    iconNode = SKSpriteNode(texture: fallbackTexture, color: .clear, size: iconSize)
                }
                iconNode.name = "traySlicesIcon"
                iconNode.position = CGPoint(x: 0, y: 0)
                iconNode.zPosition = 5
                iconNode.isHidden = true
                node.addChild(iconNode)
                traySlicesIconNode = iconNode
            } else if config.id == chipsBasketID {
                let iconSize = CGSize(width: max(12, node.size.width * 0.34), height: max(12, node.size.height * 0.34))
                let iconNode: SKSpriteNode
                if let texture = loadTexture(named: "potato_chips_icon") {
                    iconNode = SKSpriteNode(texture: texture, color: .clear, size: iconSize)
                } else {
                    let fallbackTexture = makeLabeledMarkerTexture(size: iconSize, emoji: "🍟", color: .systemYellow)
                    iconNode = SKSpriteNode(texture: fallbackTexture, color: .clear, size: iconSize)
                }
                iconNode.name = "basketChipsIcon"
                iconNode.position = CGPoint(x: 0, y: 0)
                iconNode.zPosition = 5
                iconNode.isHidden = true
                node.addChild(iconNode)
                basketChipsIconNode = iconNode
            } else if config.id == deepFryerID {
                let iconSize = CGSize(width: max(14, node.size.width * 0.2), height: max(14, node.size.width * 0.2))
                let iconNode: SKSpriteNode
                if let texture = loadTexture(named: "potato_chips_icon") {
                    iconNode = SKSpriteNode(texture: texture, color: .clear, size: iconSize)
                } else {
                    let fallbackTexture = makeLabeledMarkerTexture(size: iconSize, emoji: "🍟", color: .systemYellow)
                    iconNode = SKSpriteNode(texture: fallbackTexture, color: .clear, size: iconSize)
                }
                iconNode.name = "fryerChipsIcon"
                iconNode.position = CGPoint(x: 0, y: node.size.height * 0.2)
                iconNode.zPosition = 5
                iconNode.isHidden = true
                node.addChild(iconNode)
                fryerChipsIconNode = iconNode
            }
        }

        updateToiletVisualState()
        updateSnowmobileOwnershipVisuals()

        updateMakerLoadedIndicator()
        updateBucketSelectedIndicator()
        updateBucketPotatoIcon()
        updateFoodStateIcons()
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

    private func interactablePlacementOffset(for config: InteractableConfig) -> CGPoint {
        let deskItemOffsetX = tileSize.width * 0.28

        switch config.id {
        case "studyGuide":
            return CGPoint(x: -deskItemOffsetX, y: 0)
        case "searsCatalog":
            return CGPoint(x: deskItemOffsetX, y: 0)
        default:
            return .zero
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
            node.zPosition = ZLayer.decoration

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

    private func placeGoatOnRandomParkingCar() {
        guard let goatNode = interactableNodesByID[goatChaseSpotID] else { return }
        let availableCars = parkingCarDecorationIDs.compactMap { decorationNodesByID[$0] }
        guard let carNode = availableCars.randomElement() else { return }

        let carTopOffset = carNode.size.height * 0.22
        goatNode.position = CGPoint(x: carNode.position.x, y: carNode.position.y + carTopOffset)
        interactableHomePositionByID[goatChaseSpotID] = goatNode.position
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
        processFoodOrderEventProgress(messages: &intervalMessages)
        processPendingRaftDeliveries(messages: &intervalMessages)

        for (interactableID, respawnMove) in respawnAtMoveByInteractableID where completedMoveCount >= respawnMove {
            if interactableID == goatChaseSpotID {
                placeGoatOnRandomParkingCar()
            }
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

    private func processFoodOrderEventProgress(messages: inout [String]) {
        if let deadline = foodOrderDeadlineMove,
           completedMoveCount > deadline {
            let configuredPenalty = FoodOrderEventSettings.nonDeliveryPenaltyCoins
            _ = GameState.shared.removeCoins(configuredPenalty)
            updateCoinLabel()
            foodOrderDeadlineMove = nil
            scheduleNextFoodOrder()
            messages.append("You failed to deliver food in time. You've been fined \(configuredPenalty) coins, and the job was reassigned to your sister.")
            markSaveDirty()
        }

        if foodOrderDeadlineMove == nil,
           completedMoveCount >= nextFoodOrderMove,
           isPlayerInBarRooms() {
            foodOrderDeadlineMove = completedMoveCount + FoodOrderEventSettings.deliverDeadlineMoves
            messages.append("New food order! Deliver chips to the bar customer within \(FoodOrderEventSettings.deliverDeadlineMoves) moves.")
            markSaveDirty()
        }
    }

    func scheduleRaftDelivery() {
        let minMoves = UTSettings.shared.counts.raftDeliveryMinMoves
        let maxMoves = UTSettings.shared.counts.raftDeliveryMaxMoves
        let deliveryMove = completedMoveCount + Int.random(in: minMoves...maxMoves)
        pendingRaftDeliveryMoves.append(deliveryMove)
        pendingRaftDeliveryMoves.sort()
        markSaveDirty()
    }

    private func processPendingRaftDeliveries(messages: inout [String]) {
        guard !pendingRaftDeliveryMoves.isEmpty else { return }

        var deliveredCount = 0
        pendingRaftDeliveryMoves.removeAll { deliveryMove in
            guard completedMoveCount >= deliveryMove else { return false }
            if spawnDeliveredRaftNearMailbox() {
                deliveredCount += 1
            }
            return true
        }

        if deliveredCount > 0 {
            for _ in 0..<deliveredCount {
                messages.append("Your raft has been delivered")
            }
            markSaveDirty()
        }
    }

    private func spawnDeliveredRaftNearMailbox() -> Bool {
        guard let mailboxConfig = interactableConfigsByID[mailboxID] else {
            return false
        }

        let startColumn = mailboxConfig.tile.column + 1
        let row = mailboxConfig.tile.row

        for column in startColumn..<(worldColumns - 1) {
            let candidateTile = TileCoordinate(column: column, row: row)
            if canPlaceRaftFootprint(at: candidateTile) {
                let raftID = "raft_\(nextRaftSequenceID)"
                nextRaftSequenceID += 1
                let raftConfig = InteractableConfig(
                    id: raftID,
                    kind: .raft,
                    spriteName: "raft",
                    tile: candidateTile,
                    size: raftSize,
                    rewardCoins: 0,
                    interactionRange: 120
                )
                addDynamicInteractable(raftConfig)
                return true
            }
        }

        return false
    }

    private func canPlaceRaftFootprint(at tile: TileCoordinate) -> Bool {
        let footprintTiles = [
            tile,
            TileCoordinate(column: tile.column + 1, row: tile.row),
            TileCoordinate(column: tile.column, row: tile.row + 1),
            TileCoordinate(column: tile.column + 1, row: tile.row + 1)
        ]

        for footprintTile in footprintTiles {
            guard footprintTile.column >= 0,
                  footprintTile.column < worldColumns,
                  footprintTile.row >= 0,
                  footprintTile.row < worldRows else {
                return false
            }

            if worldConfig.wallTiles.contains(footprintTile) {
                return false
            }

            if worldConfig.decorations.contains(where: { $0.blocksMovement && $0.tile == footprintTile }) {
                return false
            }

            for (_, node) in interactableNodesByID where !node.isHidden {
                guard let occupiedTile = tileCoordinate(for: node.position) else { continue }
                if occupiedTile == footprintTile {
                    return false
                }
            }
        }

        return true
    }

    private func addDynamicInteractable(_ config: InteractableConfig) {
        guard let position = scenePointForTile(config.tile) else { return }

        let node: SKSpriteNode
        if let texture = loadTexture(named: config.spriteName) {
            node = SKSpriteNode(texture: texture, color: .clear, size: config.size)
        } else {
            let fallback = makeLabeledMarkerTexture(size: config.size, emoji: "R", color: .systemBrown)
            node = SKSpriteNode(texture: fallback, color: .clear, size: config.size)
        }

        node.name = "interactable:\(config.id)"
        node.position = position
        node.zPosition = ZLayer.interactable

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

    private func updateBucketPotatoIcon() {
        bucketPotatoIconNode?.isHidden = bucketPotatoCount <= 0
    }

    private func syncChipsBasketState() {
        chipsBasketChipCount = max(0, chipsBasketChipCount)
    }

    private func scheduleNextFoodOrder() {
        nextFoodOrderMove = completedMoveCount + FoodOrderEventSettings.randomSpawnIntervalMoves()
    }

    private func updateFoodStateIcons() {
        syncChipsBasketState()
        traySlicesIconNode?.isHidden = traySlicedPotatoCount <= 0
        fryerChipsIconNode?.isHidden = fryerSlicedPotatoCount <= 0
        basketChipsIconNode?.isHidden = chipsBasketChipCount <= 0
    }

    private func configureHUD() {
        coinLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
        coinLabel.fontSize = 28
        coinLabel.fontColor = .white
        coinLabel.horizontalAlignmentMode = .left
        coinLabel.verticalAlignmentMode = .top
        coinLabel.position = CGPoint(x: -size.width / 2 + 20, y: size.height / 2 - 20)
        coinLabel.zPosition = ZLayer.hud
        cameraNode.addChild(coinLabel)

        messageLabel = SKLabelNode(fontNamed: "AvenirNext-Medium")
        messageLabel.fontSize = 20
        messageLabel.fontColor = .white
        messageLabel.horizontalAlignmentMode = .center
        messageLabel.verticalAlignmentMode = .top
        messageLabel.numberOfLines = HUDMessageLayout.maxLines
        messageLabel.zPosition = ZLayer.hud
        messageLabel.alpha = 0
        cameraNode.addChild(messageLabel)
        updateMessageLabelLayout()

        configureMenu()
        configureResetConfirmationDialog()
        configureWarningIcons()
        configureMapCloseButton()
        configureSnowmobileChoiceDialog()
        configureScrollTextDialog()
        configureStudySubjectPrompt()
        configureQuizDialog()
        configureSearsCatalogDialog()
        configureSettingsDialog()
    }

    private func updateMessageLabelLayout() {
        guard messageLabel != nil else { return }
        let safeAreaInsets = view?.safeAreaInsets ?? .zero
        let availableWidth = max(0, size.width - safeAreaInsets.left - safeAreaInsets.right)
        let preferredWidth = max(HUDMessageLayout.minPreferredWidth, 
          availableWidth - (HUDMessageLayout.horizontalMargin * 2))

        messageLabel.preferredMaxLayoutWidth = preferredWidth
        messageLabel.position = CGPoint(
            x: (safeAreaInsets.left - safeAreaInsets.right) * 0.5,
            y: size.height / 2 - safeAreaInsets.top - HUDMessageLayout.topPadding
        )
    }

    private func configureScrollTextDialog() {
        scrollTextDialogNode = ScrollTextDialogNode(sceneSize: size)
        scrollTextDialogNode.zPosition = ZLayer.scrollTextDialog
        scrollTextDialogNode.onClose = { [weak self] in
            self?.isStatusWindowVisible = false
            self?.isPendingTasksWindowVisible = false
        }
        cameraNode.addChild(scrollTextDialogNode)
    }

    private func configureSettingsDialog() {
        settingsDialogNode = SettingsDialogNode(sceneSize: size)
        settingsDialogNode.zPosition = ZLayer.settingsDialog
        settingsDialogNode.onAvatarChanged = { [weak self] in
            self?.player?.refreshAvatarTexture()
            self?.markSaveDirty()
        }
        settingsDialogNode.onClose = { [weak self] in
            self?.refreshSettingsDependentUI()
        }
        cameraNode.addChild(settingsDialogNode)
    }

    private func refreshSettingsDependentUI() {
        player?.refreshAvatarTexture()
        snowmobileChoiceSubtitleLabel?.text = "Sell returns \(snowmobilePriceCoins) coins"
        if isStatusWindowVisible {
            updateStatusWindowBody()
        }
    }

    // MARK: - Reset Confirmation Dialog
    private func configureResetConfirmationDialog() {
        resetConfirmBackdropNode = SKShapeNode(rectOf: CGSize(width: size.width, height: size.height))
        resetConfirmBackdropNode.name = "resetConfirmBackdrop"
        resetConfirmBackdropNode.fillColor = UIColor.black.withAlphaComponent(0.45)
        resetConfirmBackdropNode.strokeColor = .clear
        resetConfirmBackdropNode.position = .zero
        resetConfirmBackdropNode.zPosition = ZLayer.resetBackdrop
        resetConfirmBackdropNode.isHidden = true
        cameraNode.addChild(resetConfirmBackdropNode)

        resetConfirmPanelNode = SKShapeNode(rectOf: CGSize(width: min(size.width - 90, 460), height: 250), cornerRadius: 14)
        resetConfirmPanelNode.name = "resetConfirmPanel"
        resetConfirmPanelNode.fillColor = UIColor(white: 0.14, alpha: 0.97)
        resetConfirmPanelNode.strokeColor = .white
        resetConfirmPanelNode.lineWidth = 2
        resetConfirmPanelNode.position = .zero
        resetConfirmPanelNode.zPosition = ZLayer.resetPanel
        resetConfirmPanelNode.isHidden = true
        cameraNode.addChild(resetConfirmPanelNode)

        let titleLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
        titleLabel.text = "Reset Progress?"
        titleLabel.fontSize = 30
        titleLabel.fontColor = .white
        titleLabel.horizontalAlignmentMode = .center
        titleLabel.verticalAlignmentMode = .center
        titleLabel.position = CGPoint(x: 0, y: 70)
        titleLabel.zPosition = ZLayer.resetPanelControl
        resetConfirmPanelNode.addChild(titleLabel)

        let messageLabel = SKLabelNode(fontNamed: "AvenirNext-Medium")
        messageLabel.text = "This cannot be undone."
        messageLabel.fontSize = 20
        messageLabel.fontColor = UIColor.white.withAlphaComponent(0.9)
        messageLabel.horizontalAlignmentMode = .center
        messageLabel.verticalAlignmentMode = .center
        messageLabel.position = CGPoint(x: 0, y: 36)
        messageLabel.zPosition = ZLayer.resetPanelControl
        resetConfirmPanelNode.addChild(messageLabel)

        let yesButton = SKShapeNode(rectOf: CGSize(width: 170, height: 50), cornerRadius: 8)
        yesButton.name = "resetConfirmYesItem"
        yesButton.fillColor = UIColor.systemRed.withAlphaComponent(0.9)
        yesButton.strokeColor = .white
        yesButton.lineWidth = 1.5
        yesButton.position = CGPoint(x: 0, y: -16)
        yesButton.zPosition = ZLayer.resetPanelControl
        resetConfirmPanelNode.addChild(yesButton)

        let yesLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
        yesLabel.name = "resetConfirmYesItem"
        yesLabel.text = "Reset"
        yesLabel.fontSize = 22
        yesLabel.fontColor = .white
        yesLabel.horizontalAlignmentMode = .center
        yesLabel.verticalAlignmentMode = .center
        yesLabel.position = .zero
        yesLabel.zPosition = ZLayer.resetPanelLabel
        yesButton.addChild(yesLabel)

        let cancelButton = SKShapeNode(rectOf: CGSize(width: 170, height: 46), cornerRadius: 8)
        cancelButton.name = "resetConfirmCancelItem"
        cancelButton.fillColor = UIColor.darkGray.withAlphaComponent(0.9)
        cancelButton.strokeColor = .white
        cancelButton.lineWidth = 1.5
        cancelButton.position = CGPoint(x: 0, y: -80)
        cancelButton.zPosition = ZLayer.resetPanelControl
        resetConfirmPanelNode.addChild(cancelButton)

        let cancelLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
        cancelLabel.name = "resetConfirmCancelItem"
        cancelLabel.text = "Cancel"
        cancelLabel.fontSize = 20
        cancelLabel.fontColor = .white
        cancelLabel.horizontalAlignmentMode = .center
        cancelLabel.verticalAlignmentMode = .center
        cancelLabel.position = .zero
        cancelLabel.zPosition = ZLayer.resetPanelLabel
        cancelButton.addChild(cancelLabel)
    }

    private func setResetConfirmationVisible(_ visible: Bool) {
        resetConfirmBackdropNode.isHidden = !visible
        resetConfirmPanelNode.isHidden = !visible
    }

    // MARK: - Snowmobile Choice Dialog
    private func configureSnowmobileChoiceDialog() {
        let backdropSize = CGSize(width: size.width, height: size.height)
        snowmobileChoiceBackdropNode = SKShapeNode(rectOf: backdropSize)
        snowmobileChoiceBackdropNode.name = "snowmobileChoiceBackdrop"
        snowmobileChoiceBackdropNode.fillColor = UIColor.black.withAlphaComponent(0.45)
        snowmobileChoiceBackdropNode.strokeColor = .clear
        snowmobileChoiceBackdropNode.position = .zero
        snowmobileChoiceBackdropNode.zPosition = ZLayer.snowmobileBackdrop
        snowmobileChoiceBackdropNode.isHidden = true
        cameraNode.addChild(snowmobileChoiceBackdropNode)

        snowmobileChoicePanelNode = SKShapeNode(rectOf: CGSize(width: min(size.width - 90, 460), height: 300), cornerRadius: 14)
        snowmobileChoicePanelNode.name = "snowmobileChoicePanel"
        snowmobileChoicePanelNode.fillColor = UIColor(white: 0.14, alpha: 0.97)
        snowmobileChoicePanelNode.strokeColor = .white
        snowmobileChoicePanelNode.lineWidth = 2
        snowmobileChoicePanelNode.position = .zero
        snowmobileChoicePanelNode.zPosition = ZLayer.snowmobilePanel
        snowmobileChoicePanelNode.isHidden = true
        cameraNode.addChild(snowmobileChoicePanelNode)

        let titleLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
        titleLabel.text = "Owned snowmobile"
        titleLabel.fontSize = 28
        titleLabel.fontColor = .white
        titleLabel.horizontalAlignmentMode = .center
        titleLabel.verticalAlignmentMode = .center
        titleLabel.position = CGPoint(x: 0, y: 104)
        titleLabel.zPosition = ZLayer.snowmobilePanelControl
        snowmobileChoicePanelNode.addChild(titleLabel)

        snowmobileChoiceSubtitleLabel = SKLabelNode(fontNamed: "AvenirNext-Medium")
        snowmobileChoiceSubtitleLabel.text = "Sell returns \(snowmobilePriceCoins) coins"
        snowmobileChoiceSubtitleLabel.fontSize = 19
        snowmobileChoiceSubtitleLabel.fontColor = UIColor.white.withAlphaComponent(0.9)
        snowmobileChoiceSubtitleLabel.horizontalAlignmentMode = .center
        snowmobileChoiceSubtitleLabel.verticalAlignmentMode = .center
        snowmobileChoiceSubtitleLabel.position = CGPoint(x: 0, y: 74)
        snowmobileChoiceSubtitleLabel.zPosition = ZLayer.snowmobilePanelControl
        snowmobileChoicePanelNode.addChild(snowmobileChoiceSubtitleLabel)

        let mountButton = SKShapeNode(rectOf: CGSize(width: 180, height: 52), cornerRadius: 8)
        mountButton.name = "snowmobileChoiceMountItem"
        mountButton.fillColor = UIColor.systemBlue.withAlphaComponent(0.9)
        mountButton.strokeColor = .white
        mountButton.lineWidth = 1.5
        mountButton.position = CGPoint(x: 0, y: 24)
        mountButton.zPosition = ZLayer.snowmobilePanelControl
        snowmobileChoicePanelNode.addChild(mountButton)

        let mountLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
        mountLabel.name = "snowmobileChoiceMountItem"
        mountLabel.text = "Mount"
        mountLabel.fontSize = 22
        mountLabel.fontColor = .white
        mountLabel.horizontalAlignmentMode = .center
        mountLabel.verticalAlignmentMode = .center
        mountLabel.position = .zero
        mountLabel.zPosition = ZLayer.snowmobilePanelLabel
        mountButton.addChild(mountLabel)

        let sellButton = SKShapeNode(rectOf: CGSize(width: 180, height: 52), cornerRadius: 8)
        sellButton.name = "snowmobileChoiceSellItem"
        sellButton.fillColor = UIColor.systemRed.withAlphaComponent(0.9)
        sellButton.strokeColor = .white
        sellButton.lineWidth = 1.5
        sellButton.position = CGPoint(x: 0, y: -42)
        sellButton.zPosition = ZLayer.snowmobilePanelControl
        snowmobileChoicePanelNode.addChild(sellButton)

        let sellLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
        sellLabel.name = "snowmobileChoiceSellItem"
        sellLabel.text = "Sell"
        sellLabel.fontSize = 22
        sellLabel.fontColor = .white
        sellLabel.horizontalAlignmentMode = .center
        sellLabel.verticalAlignmentMode = .center
        sellLabel.position = .zero
        sellLabel.zPosition = ZLayer.snowmobilePanelLabel
        sellButton.addChild(sellLabel)

        let cancelButton = SKShapeNode(rectOf: CGSize(width: 180, height: 46), cornerRadius: 8)
        cancelButton.name = "snowmobileChoiceCancelItem"
        cancelButton.fillColor = UIColor.darkGray.withAlphaComponent(0.9)
        cancelButton.strokeColor = .white
        cancelButton.lineWidth = 1.5
        cancelButton.position = CGPoint(x: 0, y: -104)
        cancelButton.zPosition = ZLayer.snowmobilePanelControl
        snowmobileChoicePanelNode.addChild(cancelButton)

        let cancelLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
        cancelLabel.name = "snowmobileChoiceCancelItem"
        cancelLabel.text = "Cancel"
        cancelLabel.fontSize = 20
        cancelLabel.fontColor = .white
        cancelLabel.horizontalAlignmentMode = .center
        cancelLabel.verticalAlignmentMode = .center
        cancelLabel.position = .zero
        cancelLabel.zPosition = ZLayer.snowmobilePanelLabel
        cancelButton.addChild(cancelLabel)
    }

    private func configureStudySubjectPrompt() {
        studySubjectBackdropNode = SKShapeNode(rectOf: CGSize(width: size.width, height: size.height))
        studySubjectBackdropNode.name = "studySubjectBackdrop"
        studySubjectBackdropNode.fillColor = UIColor.black.withAlphaComponent(0.45)
        studySubjectBackdropNode.strokeColor = .clear
        studySubjectBackdropNode.position = .zero
        studySubjectBackdropNode.zPosition = ZLayer.studyBackdrop
        studySubjectBackdropNode.isHidden = true
        cameraNode.addChild(studySubjectBackdropNode)

        let panelWidth = min(size.width - 60, 560)
        let panelHeight: CGFloat = 330
        studySubjectPanelNode = SKShapeNode(rectOf: CGSize(width: panelWidth, height: panelHeight), cornerRadius: 14)
        studySubjectPanelNode.name = "studySubjectPanel"
        studySubjectPanelNode.fillColor = UIColor(white: 0.14, alpha: 0.97)
        studySubjectPanelNode.strokeColor = .white
        studySubjectPanelNode.lineWidth = 2
        studySubjectPanelNode.position = .zero
        studySubjectPanelNode.zPosition = ZLayer.studyPanel
        studySubjectPanelNode.isHidden = true
        cameraNode.addChild(studySubjectPanelNode)

        let titleLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
        titleLabel.text = "Study Subject"
        titleLabel.fontSize = 30
        titleLabel.fontColor = .white
        titleLabel.horizontalAlignmentMode = .center
        titleLabel.verticalAlignmentMode = .center
        titleLabel.position = CGPoint(x: 0, y: 126)
        titleLabel.zPosition = ZLayer.studyPanelControl
        studySubjectPanelNode.addChild(titleLabel)

        func makeSubjectButton(name: String, text: String, y: CGFloat) -> SKShapeNode {
            let buttonWidth = (panelWidth - 72) / 2
            let button = SKShapeNode(rectOf: CGSize(width: buttonWidth, height: 46), cornerRadius: 8)
            button.name = name
            button.fillColor = UIColor.systemBlue.withAlphaComponent(0.9)
            button.strokeColor = .white
            button.lineWidth = 1.5
            button.position = CGPoint(x: 0, y: y)
            button.zPosition = ZLayer.studyPanelControl

            let label = SKLabelNode(fontNamed: "AvenirNext-Bold")
            label.name = name
            label.text = text
            label.fontSize = 21
            label.fontColor = .white
            label.horizontalAlignmentMode = .center
            label.verticalAlignmentMode = .center
            label.position = .zero
            label.zPosition = ZLayer.studyPanelLabel
            button.addChild(label)
            return button
        }

        let buttonWidth = (panelWidth - 72) / 2
        let columnOffset = (buttonWidth / 2) + 12
        let topRowY: CGFloat = 58
        let bottomRowY: CGFloat = -4

        let usHistoryButton = makeSubjectButton(name: "studySubjectUSHistItem", text: "US History", y: topRowY)
        usHistoryButton.position.x = -columnOffset
        studySubjectPanelNode.addChild(usHistoryButton)

        let englishButton = makeSubjectButton(name: "studySubjectEnglishItem", text: "English", y: topRowY)
        englishButton.position.x = columnOffset
        studySubjectPanelNode.addChild(englishButton)

        let mathButton = makeSubjectButton(name: "studySubjectMathItem", text: "Mathematics", y: bottomRowY)
        mathButton.position.x = -columnOffset
        studySubjectPanelNode.addChild(mathButton)

        let scienceButton = makeSubjectButton(name: "studySubjectScienceItem", text: "Science", y: bottomRowY)
        scienceButton.position.x = columnOffset
        studySubjectPanelNode.addChild(scienceButton)

        let cancelButton = SKShapeNode(rectOf: CGSize(width: 180, height: 42), cornerRadius: 8)
        cancelButton.name = "studySubjectCancelItem"
        cancelButton.fillColor = UIColor.darkGray.withAlphaComponent(0.9)
        cancelButton.strokeColor = .white
        cancelButton.lineWidth = 1.5
        cancelButton.position = CGPoint(x: 0, y: -118)
        cancelButton.zPosition = ZLayer.studyPanelControl
        studySubjectPanelNode.addChild(cancelButton)

        let cancelLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
        cancelLabel.name = "studySubjectCancelItem"
        cancelLabel.text = "Cancel"
        cancelLabel.fontSize = 20
        cancelLabel.fontColor = .white
        cancelLabel.horizontalAlignmentMode = .center
        cancelLabel.verticalAlignmentMode = .center
        cancelLabel.position = .zero
        cancelLabel.zPosition = ZLayer.studyPanelLabel
        cancelButton.addChild(cancelLabel)
    }

    private func configureQuizDialog() {
        quizDialogNode = QuizDialogNode(sceneSize: size)
        quizDialogNode.zPosition = ZLayer.quizDialog
        quizDialogNode.onClose = { [weak self] in
            self?.markSaveDirty()
        }
        quizDialogNode.onSubmit = { [weak self] session, correctCount in
            let updatedStats = GameState.shared.addQuizResults(
                subject: session.subject,
                answered: session.questions.count,
                correct: correctCount
            )
            GameState.shared.clearStudyGuideOpened(for: session.subject)
            self?.markSaveDirty()
            return updatedStats
        }
        cameraNode.addChild(quizDialogNode)
    }

    func setQuizDialogVisible(_ visible: Bool) {
        quizDialogNode?.setVisible(visible)
    }

    private func startQuiz(for subject: String) {
        guard GameState.shared.hasOpenedStudyGuide(for: subject) else {
            showMessage("Read the \(subject) study guide before taking this quiz.")
            return
        }

        guard let session = QuizEngine.makeSession(subject: subject, from: quizQuestions) else {
            showMessage("Not enough quiz questions for \(subject).")
            return
        }

        setMenuVisible(false)
        setStatusWindowVisible(false)
        setStudySubjectPromptVisible(false)
        scrollTextDialogNode?.setVisible(false)
        setSnowmobileChoiceDialogVisible(false)

        setQuizDialogVisible(true)
        quizDialogNode.startQuiz(session: session)
    }

    // MARK: - Intro & Study Dialog Flows
    func setStudySubjectPromptVisible(_ visible: Bool) {
        isStudySubjectPromptVisible = visible
        studySubjectBackdropNode.isHidden = !visible
        studySubjectPanelNode.isHidden = !visible
    }

    private func openIntroWindow() {
        setQuizDialogVisible(false)
        setStudySubjectPromptVisible(false)
        setStatusWindowVisible(false)
        scrollTextDialogNode.configure(title: "Introduction", lines: introDialogParagraphs, paragraphSpacing: 0.5)
        scrollTextDialogNode.setVisible(true)
    }

    private func presentIntroIfFirstRun() {
        let defaults = UserDefaults.standard
        guard defaults.bool(forKey: Self.introShownDefaultsKey) == false else { return }
        defaults.set(true, forKey: Self.introShownDefaultsKey)
        openIntroWindow()
    }

    private func openStudyBackgroundWindow(for subject: String) {
        setQuizDialogVisible(false)
        setStudySubjectPromptVisible(false)

        let matchingBackgrounds = quizQuestions
            .filter { $0.subject == subject }
            .compactMap { $0.background?.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        let paragraphs = matchingBackgrounds.isEmpty
            ? ["No study notes available for this subject."]
            : matchingBackgrounds
        scrollTextDialogNode.configure(title: "Study Guide", lines: paragraphs, paragraphSpacing: 0.5)
        scrollTextDialogNode.setVisible(true)
        GameState.shared.markStudyGuideOpened(for: subject)
        markSaveDirty()
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

    // MARK: - Map Controls
    private func configureMapCloseButton() {
        mapCloseButtonNode = SKShapeNode(rectOf: CGSize(width: 140, height: 40), cornerRadius: 8)
        mapCloseButtonNode.name = "mapCloseItem"
        mapCloseButtonNode.fillColor = UIColor.systemBlue.withAlphaComponent(0.9)
        mapCloseButtonNode.strokeColor = .white
        mapCloseButtonNode.lineWidth = 1.5
        mapCloseButtonNode.zPosition = ZLayer.mapCloseButton
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
        mapCloseLabel.zPosition = ZLayer.mapCloseLabel
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

    // MARK: - Warning Icons
    private func configureWarningIcons() {
        warningIconContainerNode = SKNode()
        warningIconContainerNode.name = "warningIconContainer"
        warningIconContainerNode.zPosition = ZLayer.warningHUD
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

        if let snowmobileTexture = loadTexture(named: "snowmobile1") {
            warningSnowmobileIconNode = SKSpriteNode(texture: snowmobileTexture, color: .clear, size: iconSize)
        } else {
            let fallbackTexture = makeLabeledMarkerTexture(size: iconSize, emoji: "S", color: .systemTeal)
            warningSnowmobileIconNode = SKSpriteNode(texture: fallbackTexture, color: .clear, size: iconSize)
        }
        warningSnowmobileIconNode.name = "warningSnowmobileIcon"
        warningSnowmobileIconNode.isHidden = true
        warningIconContainerNode.addChild(warningSnowmobileIconNode)

        if let toiletDirtyTexture {
            warningToiletIconNode = SKSpriteNode(texture: toiletDirtyTexture, color: .clear, size: iconSize)
        } else {
            let fallbackTexture = makeLabeledMarkerTexture(size: iconSize, emoji: "!", color: .systemBrown)
            warningToiletIconNode = SKSpriteNode(texture: fallbackTexture, color: .clear, size: iconSize)
        }
        warningToiletIconNode.name = "warningToiletIcon"
        warningToiletIconNode.isHidden = true
        warningIconContainerNode.addChild(warningToiletIconNode)

        if let foodOrderTexture = loadTexture(named: "food_order_warning") {
            warningFoodOrderIconNode = SKSpriteNode(texture: foodOrderTexture, color: .clear, size: iconSize)
        } else {
            let fallbackTexture = makeLabeledMarkerTexture(size: iconSize, emoji: "🍟", color: .systemOrange)
            warningFoodOrderIconNode = SKSpriteNode(texture: fallbackTexture, color: .clear, size: iconSize)
        }
        warningFoodOrderIconNode.name = "warningFoodOrderIcon"
        warningFoodOrderIconNode.isHidden = true
        warningIconContainerNode.addChild(warningFoodOrderIconNode)

        if let shovelTexture = loadTexture(named: "shovel_marker") {
            warningTrenchIconNode = SKSpriteNode(texture: shovelTexture, color: .clear, size: iconSize)
        } else {
            let fallbackTexture = makeLabeledMarkerTexture(size: iconSize, emoji: "⛏️", color: .systemBrown)
            warningTrenchIconNode = SKSpriteNode(texture: fallbackTexture, color: .clear, size: iconSize)
        }
        warningTrenchIconNode.name = "warningTrenchIcon"
        warningTrenchIconNode.isHidden = true
        warningIconContainerNode.addChild(warningTrenchIconNode)

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

    private func activeWarningIcons() -> [SKSpriteNode] {
        var icons: [SKSpriteNode] = []

        if batDefeatDeadlineMove != nil {
            icons.append(warningBatIconNode)
        }

        if hasPendingSnowmobileTask {
            icons.append(warningSnowmobileIconNode)
        }

        if isToiletDirty {
            icons.append(warningToiletIconNode)
        }

        if foodOrderDeadlineMove != nil {
            icons.append(warningFoodOrderIconNode)
        }

        if hasShownFirstSuccessfulChipDeliveryMessage && trenchedSepticTiles.count < worldConfig.septicDigTiles.count {
            icons.append(warningTrenchIconNode)
        }

        return icons
    }

    private func warningIconStackContains(_ hudLocation: CGPoint) -> Bool {
        let activeIcons = activeWarningIcons()
        guard !activeIcons.isEmpty else { return false }

        return activeIcons.contains { icon in
            let center = CGPoint(
                x: warningIconContainerNode.position.x + icon.position.x,
                y: warningIconContainerNode.position.y + icon.position.y
            )
            let hitInset: CGFloat = 8
            let hitRect = CGRect(
                x: center.x - (icon.size.width * 0.5) - hitInset,
                y: center.y - (icon.size.height * 0.5) - hitInset,
                width: icon.size.width + (hitInset * 2),
                height: icon.size.height + (hitInset * 2)
            )
            return hitRect.contains(hudLocation)
        }
    }

    private func updateWarningIcons() {
        let activeIcons = activeWarningIcons()

        let spacing: CGFloat = 30
        for (index, icon) in activeIcons.enumerated() {
            icon.isHidden = false
            icon.position = CGPoint(x: CGFloat(index) * spacing, y: 0)
        }

        if !activeIcons.contains(warningBatIconNode) {
            warningBatIconNode.isHidden = true
        }
        if !activeIcons.contains(warningSnowmobileIconNode) {
            warningSnowmobileIconNode.isHidden = true
        }
        if !activeIcons.contains(warningToiletIconNode) {
            warningToiletIconNode.isHidden = true
        }
        if !activeIcons.contains(warningFoodOrderIconNode) {
            warningFoodOrderIconNode.isHidden = true
        }
        if !activeIcons.contains(warningTrenchIconNode) {
            warningTrenchIconNode.isHidden = true
        }
    }

    // MARK: - Menu
    private func configureMenu() {
        let rightX = size.width / 2 - 20
        let topY = size.height / 2 - 20

        menuButtonNode = SKShapeNode(rectOf: CGSize(width: 36, height: 30), cornerRadius: 6)
        menuButtonNode.name = "hamburgerButton"
        menuButtonNode.fillColor = UIColor.darkGray.withAlphaComponent(0.65)
        menuButtonNode.strokeColor = .white
        menuButtonNode.lineWidth = 1.5
        menuButtonNode.position = CGPoint(x: rightX - 18, y: topY - 15)
        menuButtonNode.zPosition = ZLayer.menuButton
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
        let menuPanelHeight: CGFloat = 316
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
        menuPanelNode.zPosition = ZLayer.menuPanel
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
            button.zPosition = ZLayer.menuPanelButton

            let label = SKLabelNode(fontNamed: "AvenirNext-Bold")
            // Keep a distinct label name to avoid collisions, but touch logic matches parent name
            label.name = name + "Label"
            label.text = labelText
            label.fontSize = 30
            label.fontColor = .white
            label.verticalAlignmentMode = .center
            label.horizontalAlignmentMode = .center
            label.position = .zero
            label.zPosition = ZLayer.menuPanelLabel
            button.addChild(label)

            return button
        }

        // Create menu buttons (invisible targets) and add them to the panel
        let introButton = makeMenuButton(name: "menuIntroItem", labelText: "Intro", y: 110)
        menuPanelNode.addChild(introButton)

        let statusButton = makeMenuButton(name: "menuStatusItem", labelText: "Status", y: 66)
        menuPanelNode.addChild(statusButton)

        let settingsButton = makeMenuButton(name: "menuSettingsItem", labelText: "Settings", y: 22)
        menuPanelNode.addChild(settingsButton)

        let resetButton = makeMenuButton(name: "menuResetItem", labelText: "Reset", y: -22)
        menuPanelNode.addChild(resetButton)

        let move20Button = makeMenuButton(name: "menuMove20Item", labelText: "Move 20", y: -66)
        menuPanelNode.addChild(move20Button)

        let mapButton = makeMenuButton(name: "menuMapItem", labelText: "Map", y: -110)
        menuPanelNode.addChild(mapButton)
    }

    private func setMapViewMode(_ enabled: Bool) {
        if enabled == isMapViewMode { return }

        if enabled {
            mapModeSavedCameraPosition = cameraNode.position
            mapModeSavedCameraScale = cameraNode.xScale
            isMapViewMode = true
            isDraggingMap = false
            clearMoveTarget()
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

    // MARK: - Status Dialog
    func setStatusWindowVisible(_ visible: Bool) {
        isStatusWindowVisible = visible
        if visible {
            isPendingTasksWindowVisible = false
            updateStatusWindowBody()
            scrollTextDialogNode.setVisible(true)
        } else {
            scrollTextDialogNode.setVisible(false)
        }
    }

    private func setPendingTasksWindowVisible(_ visible: Bool) {
        isPendingTasksWindowVisible = visible
        if visible {
            isStatusWindowVisible = false
            updatePendingTasksWindowBody()
            if !pendingTaskLines().isEmpty {
                scrollTextDialogNode.setVisible(true)
            }
        } else if !isStatusWindowVisible {
            scrollTextDialogNode.setVisible(false)
        }
    }

    private func updateStatusWindowBody() {
        guard isStatusWindowVisible else { return }
        let statusLines = makeStatusLines()
        scrollTextDialogNode.configure(title: "Status", lines: statusLines, paragraphSpacing: 0.0, closeButtonTitle: "Close")
    }

    private func pendingTaskLines() -> [String] {
        var lines: [String] = []

        if let batDeadline = batDefeatDeadlineMove {
            let remainingMoves = max(0, batDeadline - completedMoveCount)
            lines.append("Kill the bat (\(remainingMoves) moves before penalty)")
        }

        if isToiletDirty {
            let remainingMoves = max(0, (toiletCleanDeadlineMove ?? completedMoveCount) - completedMoveCount)
            lines.append("Clean the toilet (\(remainingMoves) moves before penalty)")
        }

        if let foodDeadline = foodOrderDeadlineMove {
            let remainingMoves = max(0, foodDeadline - completedMoveCount)
            lines.append("Deliver food order (\(remainingMoves) moves before penalty)")
        }

        if hasPendingSnowmobileTask {
            lines.append("Buy snowmobiles (\(ownedSnowmobileIDs.count) of \(Self.requiredSnowmobileCount) bought)")
        }

        if hasShownFirstSuccessfulChipDeliveryMessage && trenchedSepticTiles.count < worldConfig.septicDigTiles.count {
            lines.append("Dig a trench between the septic systems")
        }

        return lines
    }

    private func updatePendingTasksWindowBody() {
        guard isPendingTasksWindowVisible else { return }
        let lines = pendingTaskLines()
        guard !lines.isEmpty else {
            setPendingTasksWindowVisible(false)
            return
        }
        scrollTextDialogNode.configure(title: "Pending Tasks", lines: lines, paragraphSpacing: 0.0, closeButtonTitle: "Close")
    }

    private func makeStatusLines() -> [String] {
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
            toiletStatusText = "Clean (next dirty in \(max(0, nextToiletDirtyMove - completedMoveCount)) moves)"
        }

        let foodOrderStatusText: String
        if let deadline = foodOrderDeadlineMove {
            foodOrderStatusText = "Active (deliver in \(max(0, deadline - completedMoveCount)) moves)"
        } else {
            foodOrderStatusText = "Waiting (next in \(max(0, nextFoodOrderMove - completedMoveCount)) moves, range \(FoodOrderEventSettings.minSpawnIntervalMoves)-\(FoodOrderEventSettings.maxSpawnIntervalMoves))"
        }

        let currentMoveSpeed = mountedSnowmobileID == nil
            ? Int(playerMoveSpeed)
            : Int(playerMoveSpeed * mountedSnowmobileSpeedMultiplier)
        let movementModeText = mountedSnowmobileID == nil ? "On foot" : "Mounted"

        var statusLines = [
            "Coins: \(GameState.shared.coins)",
            "Moves: \(completedMoveCount)",
            "Snowmobiles owned: \(ownedSnowmobileIDs.count)/\(Self.requiredSnowmobileCount)",
            "Mounted snowmobile: \(mountedSnowmobileID == nil ? "No" : "Yes")",
            "Move speed: \(currentMoveSpeed) (\(movementModeText))",
            "Bucket carried: \(isBucketCarried ? "Yes" : "No")",
            "Bucket potatoes: \(bucketPotatoCount)/\(bucketCapacity)",
            "Washed in bucket: \(washedPotatoCount)",
            "Potato selected: \(selectedPotatoForLoading ? "Yes" : "No")",
            "Peeler has slices: \(peelerHasSlicedPotatoes ? "Yes" : "No")",
            "Tray carried: \(isTrayCarried ? "Yes" : "No")",
            "Tray slices: \(traySlicedPotatoCount)",
            "Basket carried: \(isChipsBasketCarried ? "Yes" : "No")",
            "Basket has chips: \(chipsBasketChipCount > 0 ? "Yes" : "No")",
            "Basket chip count: \(chipsBasketChipCount)",
            "Fryer chips: \(fryerSlicedPotatoCount)",
            "Food order: \(foodOrderStatusText)",
            "Toilet dirty: \(isToiletDirty ? "Yes" : "No")",
            "Brush carried: \(isToiletBowlBrushCarried ? "Yes" : "No")",
            "Toilet event: \(toiletStatusText)",
            "Racket carried: \(isTennisRacketCarried ? "Yes" : "No")",
            "Shovel carried: \(isShovelCarried ? "Yes" : "No")",
            "Envelope carried: \(isEnvelopeCarried ? "Yes" : "No")",
            "Septic trenches: \(trenchedSepticTiles.count)/\(worldConfig.septicDigTiles.count)",
            "Bat event: \(batStatusText)",
            "Goat respawn: \(goatRespawnText)"
        ]

        statusLines.append(contentsOf: QuizStatusFormatter.makeStatusLines { subject in
            GameState.shared.quizTotals(for: subject)
        } studiedProvider: { subject in
            GameState.shared.hasOpenedStudyGuide(for: subject)
        })

        if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
            if let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String {
                statusLines.append("Version: " + version + " (" + build + ")")
            } else {
                statusLines.append("Version: " + version)
            }
        }
        return statusLines
    }

    func setMenuVisible(_ visible: Bool) {
        menuPanelNode.isHidden = !visible
        if visible {
            menuButtonNode.fillColor = UIColor.systemBlue.withAlphaComponent(0.65)
            menuButtonNode.strokeColor = .systemYellow
        } else {
            menuButtonNode.fillColor = UIColor.darkGray.withAlphaComponent(0.65)
            menuButtonNode.strokeColor = .white
        }
    }

    func updateCoinLabel() {
        coinLabel.text = "Coins: \(GameState.shared.coins)"
    }

    private func minimumReachableDistance(to node: SKSpriteNode) -> CGFloat {
        let playerRadius = min(player.size.width, player.size.height) * 0.38
        let interactableRadius = max(node.size.width, node.size.height) * 0.5
        let desiredGap: CGFloat = 8
        return playerRadius + interactableRadius + desiredGap
    }

    private func effectiveInteractionRange(for config: InteractableConfig, node: SKSpriteNode) -> CGFloat {
        max(config.interactionRange, minimumReachableDistance(to: node) + 12)
    }

    private func movePlayerNearInteractable(_ node: SKSpriteNode) {
        let dx = node.position.x - player.position.x
        let dy = node.position.y - player.position.y
        let distance = hypot(dx, dy)
        guard distance > 0.001 else { return }
        let standOffDistance = minimumReachableDistance(to: node)

        let directionX = dx / distance
        let directionY = dy / distance
        let target = CGPoint(
            x: node.position.x - directionX * standOffDistance,
            y: node.position.y - directionY * standOffDistance
        )
        setMoveTarget(target, arrivalDistance: 8)
    }

    private func performInteractionIfPossible(interactableID: String) {
        guard let config = interactableConfigsByID[interactableID],
              let node = interactableNodesByID[interactableID] else { return }

        if mountedSnowmobileID != nil, config.kind != .snowmobile {
            showMessage("Dismount snowmobile first.")
            return
        }

        if riddenRaftID != nil, config.kind != .raft {
            showMessage("Exit raft before interacting with that object.")
            return
        }

        let dx = node.position.x - player.position.x
        let dy = node.position.y - player.position.y
        let distance = hypot(dx, dy)

        let interactionRange = effectiveInteractionRange(for: config, node: node)
        if distance > interactionRange {
            movePlayerNearInteractable(node)
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
        case .tray:
            handleTrayInteraction(node: node)
            return
        case .snowmobile:
            handleSnowmobileInteraction(interactableID: interactableID)
            return
        case .toilet:
            handleToiletInteraction()
            return
        case .studyGuide:
            handleStudyGuideInteraction()
            return
        case .searsCatalog:
            handleSearsCatalogInteraction()
            return
        case .mailbox:
            handleMailboxInteraction()
            return
        case .barCustomer:
            handleBarCustomerInteraction()
            return
        case .envelope:
            handleEnvelopeInteraction()
            return
        case .teachersDesk:
            handleTeachersDeskInteraction(interactableID: interactableID)
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
        case .raft:
            handleRaftInteraction(interactableID: interactableID, node: node)
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

    private func handleStudyGuideInteraction() {
        setMenuVisible(false)
        setStatusWindowVisible(false)
        setQuizDialogVisible(false)
        scrollTextDialogNode?.setVisible(false)
        setStudySubjectPromptVisible(true)
    }

    func isEnvelopeOutstanding() -> Bool {
        if isEnvelopeCarried {
            return true
        }
        return interactableNodesByID[envelopeID]?.isHidden == false
    }

    func isEnvelopeCurrentlyCarried() -> Bool {
        isEnvelopeCarried
    }

    func isEnvelopeVisibleForPickup() -> Bool {
        guard let envelopeNode = interactableNodesByID[envelopeID] else {
            return false
        }
        return !envelopeNode.isHidden
    }

    func setEnvelopeCarried(_ carried: Bool) {
        isEnvelopeCarried = carried
    }

    func hideEnvelopeAndResetHomePosition() {
        guard let envelopeNode = interactableNodesByID[envelopeID] else {
            return
        }
        envelopeNode.isHidden = true
        if let homePosition = interactableHomePositionByID[envelopeID] {
            envelopeNode.position = homePosition
        }
    }

    func createEnvelopeAndCarry() {
        guard let envelopeNode = interactableNodesByID[envelopeID] else { return }
        envelopeNode.isHidden = false
        isEnvelopeCarried = true
    }

    private func handleTeachersDeskInteraction(interactableID: String) {
        guard let subject = teacherDeskSubjectByID[interactableID] else {
            showMessage("No quiz subject assigned to this classroom.")
            return
        }
        startQuiz(for: subject)
    }

    private func handleBucketInteraction(node: SKSpriteNode) {
        if !isBucketCarried {
            isBucketCarried = true
            showMessage("Picked up bucket (\(bucketPotatoCount)/\(bucketCapacity), washed \(washedPotatoCount)).")
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
        dropCarriedObject(node, interactableID: bucketID)
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
            showMessage("Potato peeler has slices ready. Put them on the tray.")
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
            showMessage("Potato peeled and sliced. Move slices onto the tray.")
            return
        }

        showMessage("Select a washed potato from the bucket first.")
    }

    private func handleTrayInteraction(node: SKSpriteNode) {
        if !isTrayCarried {
            isTrayCarried = true
            showMessage("Picked up tray.")
            return
        }

        if isPlayerNearInteractable(withID: potatoPeelerID) {
            guard peelerHasSlicedPotatoes else {
                showMessage("No sliced potatoes ready in peeler.")
                return
            }

            peelerHasSlicedPotatoes = false
            traySlicedPotatoCount += 1
            updateMakerLoadedIndicator()
            updateFoodStateIcons()
            showMessage("Added sliced potato to tray (\(traySlicedPotatoCount) total).")
            return
        }

        isTrayCarried = false
        dropCarriedObject(node, interactableID: trayID)
        showMessage("Dropped tray.")
    }

    private func handleChipsBasketInteraction(node: SKSpriteNode) {
        if !isChipsBasketCarried {
            isChipsBasketCarried = true
            showMessage("Picked up basket.")
            return
        }

        if chipsBasketChipCount > 0 {
            chipsBasketChipCount = 0
            updateFoodStateIcons()
            showMessage("Emptied chips from basket.")
            return
        }

        isChipsBasketCarried = false
        dropCarriedObject(node, interactableID: chipsBasketID)
        showMessage("Dropped basket.")
    }

    private func handleDeepFryerInteraction() {
        if traySlicedPotatoCount > 0 {
            guard isTrayCarried else {
                showMessage("Bring the tray with slices to the deep fryer.")
                return
            }

            fryerSlicedPotatoCount += traySlicedPotatoCount
            let movedSlices = traySlicedPotatoCount
            traySlicedPotatoCount = 0
            updateFoodStateIcons()
            showMessage("Fried \(movedSlices) sliced potato\(movedSlices == 1 ? "" : "es") into chips.")
            return
        }

        if fryerSlicedPotatoCount > 0 {
            guard isChipsBasketCarried else {
                showMessage("Carry the basket to collect chips from the fryer.")
                return
            }
            guard chipsBasketChipCount == 0 else {
                showMessage("Basket already has chips.")
                return
            }

            let chipCount = fryerSlicedPotatoCount
            fryerSlicedPotatoCount = 0
            chipsBasketChipCount = chipCount
            updateFoodStateIcons()
            showMessage("Moved \(chipCount) chip batch\(chipCount == 1 ? "" : "es") to basket.")
            return
        }

        if isTrayCarried {
            showMessage("Tray has no slices to fry.")
            return
        }

        showMessage("Load sliced potatoes onto the tray first.")
    }

    private func handleBarCustomerInteraction() {
        guard isChipsBasketCarried else {
            showMessage("Carry the chips basket before serving the customer.")
            return
        }

        guard chipsBasketChipCount > 0 else {
            showMessage("Your basket has no chips to deliver.")
            return
        }

        guard foodOrderDeadlineMove != nil else {
            showMessage("No active food order right now.")
            return
        }

        let deliveredChipCount = chipsBasketChipCount
        chipsBasketChipCount = 0
        foodOrderDeadlineMove = nil
        scheduleNextFoodOrder()

        let rewardCoins = potatoChipRewardPerPotato * deliveredChipCount
        GameState.shared.addCoins(rewardCoins)
        updateCoinLabel()
        updateFoodStateIcons()
        let baseMessage = "Delivered food order. +\(rewardCoins) coins"
        if hasShownFirstSuccessfulChipDeliveryMessage {
            showMessage(baseMessage)
        } else {
            hasShownFirstSuccessfulChipDeliveryMessage = true
            showMessage(baseMessage + "\nNext goal: Earn money to buy a snowblower by digging a trench between the septic systems.")
        }
        markSaveDirty()
    }

    private func handleSnowmobileInteraction(interactableID: String) {
        guard let snowmobileConfig = interactableConfigsByID[interactableID] else { return }

        if riddenRaftID != nil {
            showMessage("Exit raft before using a snowmobile.")
            return
        }

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
            clearMoveTarget()
            mountedSnowmobileID = nil
            selectedOwnedSnowmobileID = mountedID
            updateMountedSnowmobileUI()
            showMessage("Dismounted snowmobile.")
            return
        }

        showMessage("No space to dismount here.")
    }

    private func handleRaftInteraction(interactableID: String, node: SKSpriteNode) {
        if riddenRaftID == interactableID {
            showMessage("Tap shore to exit the raft.")
            return
        }

        if carriedRaftID == interactableID {
            if placeCarriedRaftIntoRiverIfPossible(raftID: interactableID, node: node) {
                showMessage("Placed raft in the river.")
            } else {
                dropCarriedObject(node, interactableID: interactableID)
                showMessage("Dropped raft.")
            }
            return
        }

        if mountedSnowmobileID != nil {
            showMessage("Dismount snowmobile first.")
            return
        }

        guard let raftTile = tileCoordinate(for: node.position) else {
            return
        }

        if isRiverTile(raftTile) {
            riddenRaftID = interactableID
            carriedRaftID = nil
            player.position = node.position
            clearMoveTarget()
            player.physicsBody?.velocity = .zero
            showMessage("Entered raft.")
            markSaveDirty()
            return
        }

        if carriedRaftID == nil {
            carriedRaftID = interactableID
            riddenRaftID = nil
            node.isHidden = false
            showMessage("Picked up raft.")
            markSaveDirty()
            return
        }

        showMessage("You are already carrying another raft.")
    }

    private func placeCarriedRaftIntoRiverIfPossible(raftID: String, node: SKSpriteNode) -> Bool {
        guard let playerTile = tileCoordinate(for: player.position) else {
            return false
        }

        let candidates = candidateDropTiles(from: playerTile)
        for tile in candidates where isRiverTile(tile) {
            guard canPlaceRaftFootprint(at: tile), let targetPosition = scenePointForTile(tile) else {
                continue
            }
            carriedRaftID = nil
            node.removeAllActions()
            node.position = targetPosition
            node.isHidden = false
            interactableHomePositionByID[raftID] = targetPosition
            markSaveDirty()
            return true
        }

        return false
    }

    private func handleToiletBowlBrushInteraction(node: SKSpriteNode) {
        if isToiletBowlBrushCarried {
            isToiletBowlBrushCarried = false
            dropCarriedObject(node, interactableID: toiletBowlBrushID)
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
            dropCarriedObject(node, interactableID: tennisRacketID)
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
            dropCarriedObject(node, interactableID: shovelID)
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
        clearMoveTarget()
        player.physicsBody?.velocity = .zero
        var showedEventMessage = false

        for _ in 0..<count {
            completedMoveCount += 1
            if processInteractableRespawns() {
                showedEventMessage = true
            }
        }

        updateStatusWindowBody()
        markSaveDirty()
        if !showedEventMessage {
            showMessage("Simulated \(count) moves.")
        }
    }

    private func makeSaveSnapshot() -> GameSaveSnapshot {
        var interactablePositionsByID: [String: SavedPoint] = [:]
        var hiddenInteractableIDs: [String] = []

        for (id, node) in interactableNodesByID {
            if shouldPersistInteractablePosition(for: id) {
                interactablePositionsByID[id] = savedPoint(from: node.position)
            }
            if node.isHidden {
                hiddenInteractableIDs.append(id)
            }
        }

        return GameSaveSnapshot(
            schemaVersion: 1,
            appVersion: (Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String) ?? "0",
            savedAt: Date(),
            coins: GameState.shared.coins,
            completedMoveCount: completedMoveCount,
            playerPosition: savedPoint(from: player.position),
            interactablePositionsByID: interactablePositionsByID,
            hiddenInteractableIDs: hiddenInteractableIDs,
            respawnAtMoveByInteractableID: respawnAtMoveByInteractableID,
            isBucketCarried: isBucketCarried,
            bucketPotatoCount: bucketPotatoCount,
            washedPotatoCount: washedPotatoCount,
            selectedPotatoForLoading: selectedPotatoForLoading,
            selectedPotatoIsWashed: selectedPotatoIsWashed,
            peelerHasSlicedPotatoes: peelerHasSlicedPotatoes,
            fryerSlicedPotatoCount: fryerSlicedPotatoCount,
            isTrayCarried: isTrayCarried,
            traySlicedPotatoCount: traySlicedPotatoCount,
            isChipsBasketCarried: isChipsBasketCarried,
            basketSlicedPotatoCount: 0,
            chipsBasketChipCount: chipsBasketChipCount,
            chipsBasketContainsChips: chipsBasketChipCount > 0,
            isToiletBowlBrushCarried: isToiletBowlBrushCarried,
            isTennisRacketCarried: isTennisRacketCarried,
            isShovelCarried: isShovelCarried,
            isEnvelopeCarried: isEnvelopeCarried,
            carriedRaftID: carriedRaftID,
            riddenRaftID: riddenRaftID,
            pendingRaftDeliveryMoves: pendingRaftDeliveryMoves,
            nextRaftSequenceID: nextRaftSequenceID,
            ownedSnowmobileIDs: Array(ownedSnowmobileIDs),
            selectedOwnedSnowmobileID: selectedOwnedSnowmobileID,
            mountedSnowmobileID: mountedSnowmobileID,
            isToiletDirty: isToiletDirty,
            toiletCleanDeadlineMove: toiletCleanDeadlineMove,
            nextToiletDirtyMove: nextToiletDirtyMove,
            hasShownToiletPenaltyStartMessage: hasShownToiletPenaltyStartMessage,
            studyGuideOpenedBySubject: GameState.shared.studyGuideOpenedBySubject,
            nextBatSpawnMove: nextBatSpawnMove,
            batDefeatDeadlineMove: batDefeatDeadlineMove,
            nextFoodOrderMove: nextFoodOrderMove,
            foodOrderDeadlineMove: foodOrderDeadlineMove,
            hasShownFirstSuccessfulChipDeliveryMessage: hasShownFirstSuccessfulChipDeliveryMessage,
            trenchedSepticTiles: Array(trenchedSepticTiles),
            hasAwardedSepticCompletionBonus: hasAwardedSepticCompletionBonus
        )
    }

    private func applySaveSnapshot(_ snapshot: GameSaveSnapshot) {
        GameState.shared.setCoins(snapshot.coins)
        completedMoveCount = max(0, snapshot.completedMoveCount)
        player.position = point(from: snapshot.playerPosition)

        ensureDynamicRaftsExist(for: snapshot)

        for (id, savedPosition) in snapshot.interactablePositionsByID {
            if !shouldPersistInteractablePosition(for: id) {
                continue
            }
            interactableNodesByID[id]?.position = point(from: savedPosition)
        }

        let hiddenIDs = Set(snapshot.hiddenInteractableIDs)
        for (id, node) in interactableNodesByID {
            if id == envelopeID {
                if let wasEnvelopeCarried = snapshot.isEnvelopeCarried {
                    node.isHidden = wasEnvelopeCarried ? false : hiddenIDs.contains(id)
                } else {
                    node.isHidden = true
                }
                continue
            }
            node.isHidden = hiddenIDs.contains(id)
        }

        respawnAtMoveByInteractableID = snapshot.respawnAtMoveByInteractableID

        isBucketCarried = snapshot.isBucketCarried
        bucketPotatoCount = max(0, min(bucketCapacity, snapshot.bucketPotatoCount))
        washedPotatoCount = max(0, min(bucketPotatoCount, snapshot.washedPotatoCount))
        selectedPotatoForLoading = snapshot.selectedPotatoForLoading
        selectedPotatoIsWashed = snapshot.selectedPotatoIsWashed
        peelerHasSlicedPotatoes = snapshot.peelerHasSlicedPotatoes
        fryerSlicedPotatoCount = max(0, snapshot.fryerSlicedPotatoCount)
        isTrayCarried = snapshot.isTrayCarried ?? false
        traySlicedPotatoCount = max(0, snapshot.traySlicedPotatoCount ?? 0)
        isChipsBasketCarried = snapshot.isChipsBasketCarried
        chipsBasketChipCount = max(
            0,
            snapshot.chipsBasketChipCount
                ?? (snapshot.chipsBasketContainsChips ? max(1, snapshot.basketSlicedPotatoCount) : 0)
        )
        isToiletBowlBrushCarried = snapshot.isToiletBowlBrushCarried
        isTennisRacketCarried = snapshot.isTennisRacketCarried
        isShovelCarried = snapshot.isShovelCarried
        isEnvelopeCarried = snapshot.isEnvelopeCarried ?? false
        carriedRaftID = snapshot.carriedRaftID
        riddenRaftID = snapshot.riddenRaftID
        pendingRaftDeliveryMoves = snapshot.pendingRaftDeliveryMoves ?? []
        nextRaftSequenceID = max(1, snapshot.nextRaftSequenceID ?? nextRaftSequenceID)

        if isEnvelopeCarried {
            interactableNodesByID[envelopeID]?.isHidden = false
        }
        if let carriedRaftID,
           let raftNode = interactableNodesByID[carriedRaftID] {
            raftNode.isHidden = false
        }

        ownedSnowmobileIDs = Set(snapshot.ownedSnowmobileIDs)
        selectedOwnedSnowmobileID = snapshot.selectedOwnedSnowmobileID
        mountedSnowmobileID = snapshot.mountedSnowmobileID

        isToiletDirty = snapshot.isToiletDirty
        toiletCleanDeadlineMove = snapshot.toiletCleanDeadlineMove
        nextToiletDirtyMove = max(0, snapshot.nextToiletDirtyMove)
        hasShownToiletPenaltyStartMessage = snapshot.hasShownToiletPenaltyStartMessage
        GameState.shared.setStudyGuideOpenedBySubject(snapshot.studyGuideOpenedBySubject)

        nextBatSpawnMove = max(0, snapshot.nextBatSpawnMove)
        batDefeatDeadlineMove = snapshot.batDefeatDeadlineMove
        nextFoodOrderMove = max(0, snapshot.nextFoodOrderMove ?? nextFoodOrderMove)
        foodOrderDeadlineMove = snapshot.foodOrderDeadlineMove
        hasShownFirstSuccessfulChipDeliveryMessage = snapshot.hasShownFirstSuccessfulChipDeliveryMessage ?? false

        trenchedSepticTiles = Set(snapshot.trenchedSepticTiles.filter { worldConfig.septicDigTiles.contains($0) })
        hasAwardedSepticCompletionBonus = snapshot.hasAwardedSepticCompletionBonus

        resetSepticDigTiles()
        for tile in trenchedSepticTiles {
            applyTrench(at: tile)
        }

        updateMountedSnowmobileUI()
        updateSnowmobileOwnershipVisuals()
        updateToiletVisualState()
        updateMakerLoadedIndicator()
        updateBucketSelectedIndicator()
        updateBucketPotatoIcon()
        updateFoodStateIcons()
        updateCoinLabel()
        updateStatusWindowBody()

        clearMoveTarget()
    }

    private func shouldPersistInteractablePosition(for id: String) -> Bool {
        if id == "studyGuide" || id == "searsCatalog" || id == mailboxID || id == barCustomerID {
            return false
        }

        if interactableConfigsByID[id]?.kind == .teachersDesk {
            return false
        }

        return id != potatoPeelerID &&
            id != deepFryerID &&
            id != potatoBinID &&
            id != toiletID
    }

    private func ensureDynamicRaftsExist(for snapshot: GameSaveSnapshot) {
        let positionedRaftIDs = snapshot.interactablePositionsByID.keys.filter { $0.hasPrefix("raft_") }
        let hiddenRaftIDs = snapshot.hiddenInteractableIDs.filter { $0.hasPrefix("raft_") }
        let allRaftIDs = Set(positionedRaftIDs).union(hiddenRaftIDs)
        let maxExistingSequence = allRaftIDs.compactMap { id -> Int? in
            guard let suffix = id.split(separator: "_").last else { return nil }
            return Int(suffix)
        }.max() ?? 0
        nextRaftSequenceID = max(nextRaftSequenceID, maxExistingSequence + 1)

        for raftID in allRaftIDs where interactableNodesByID[raftID] == nil {
            let raftConfig = InteractableConfig(
                id: raftID,
                kind: .raft,
                spriteName: "raft",
                tile: TileCoordinate(column: 0, row: 0),
                size: raftSize,
                rewardCoins: 0,
                interactionRange: 120
            )
            addDynamicInteractable(raftConfig)
        }

        for raftID in allRaftIDs {
            if let savedPoint = snapshot.interactablePositionsByID[raftID] {
                let point = point(from: savedPoint)
                interactableNodesByID[raftID]?.position = point
                interactableHomePositionByID[raftID] = point
            }
        }
    }

    private func restoreGameFromDiskIfAvailable() {
        guard !hasAttemptedSaveRestore else { return }
        hasAttemptedSaveRestore = true

        guard let snapshot = SaveManager.shared.loadSnapshot() else { return }
        applySaveSnapshot(snapshot)
    }

    func saveGameStateNow() {
        let snapshot = makeSaveSnapshot()
        if SaveManager.shared.saveSnapshot(snapshot) {
            isSaveDirty = false
        }
    }

    private func scenePointForTile(_ tile: TileCoordinate) -> CGPoint? {
        guard let map = groundTileMap else { return nil }
        let localCenter = map.centerOfTile(atColumn: tile.column, row: tile.row)
        return map.convert(localCenter, to: self)
    }

    private func buildRiverOverlay(on tileMap: SKTileMapNode) {
        guard let river = worldConfig.riverOverlay else { return }

        let riverHeight = CGFloat(river.heightTiles) * tileSize.height
        guard riverHeight > 0 else { return }

        let totalRiverWidth = CGFloat(river.maxColumnExclusive - river.minColumn) * tileSize.width
        guard totalRiverWidth > 0 else { return }

        let bendTexture = loadTexture(named: river.rightEdgeSpriteName)
        let bendWidth: CGFloat
        // bendMultiplier is the height multiplier to apply to the bend texture to make it match the river height
        let bendMultiplier = (2804.0/1493.0)
        let bendHeight = riverHeight * bendMultiplier
        if let bendTexture {
            let bendTextureSize = bendTexture.size()
            bendWidth = riverHeight * (bendTextureSize.width / max(1, bendTextureSize.height)) * bendMultiplier
        } else {
            bendWidth = 0
        }

        let repeatedWidth = max(0, totalRiverWidth - bendWidth)

        let baseCenter = tileMap.centerOfTile(atColumn: river.minColumn, row: river.bottomRow)
        let baseScenePoint = tileMap.convert(baseCenter, to: self)
        let leftEdge = baseScenePoint.x - (tileSize.width * 0.5)
        let bottomEdge = baseScenePoint.y - (tileSize.height * 0.5)
        let centerY = bottomEdge + (riverHeight * 0.5)
        let bendY = bottomEdge + (riverHeight * 0.5) * bendMultiplier

        if repeatedWidth > 0,
           let repeatedTexture = loadTexture(named: river.repeatedSpriteName) {
            let sourceSize = repeatedTexture.size()
            let repeatedSegmentWidth = max(1, riverHeight * (sourceSize.width / max(1, sourceSize.height)))

            var remainingWidth = repeatedWidth
            var cursorX = leftEdge
            var segmentIndex = 0

            while remainingWidth > 0.5 {
                let segmentWidth = min(repeatedSegmentWidth, remainingWidth)
                let segmentNode = SKSpriteNode(
                    texture: repeatedTexture,
                    color: .clear,
                    size: CGSize(width: segmentWidth, height: riverHeight)
                )
                segmentNode.name = "riverOverlayRepeated_\(segmentIndex)"
                segmentNode.position = CGPoint(x: cursorX + (segmentWidth * 0.5), y: centerY)
                segmentNode.zPosition = ZLayer.worldFloorOverlay
                addChild(segmentNode)

                cursorX += segmentWidth
                remainingWidth -= segmentWidth
                segmentIndex += 1
            }
        }

        if let bendTexture, bendWidth > 0 {
            let bendNode = SKSpriteNode(texture: bendTexture, color: .clear, size: CGSize(width: bendWidth, height: bendHeight))
            bendNode.name = "riverOverlayBend"
            bendNode.position = CGPoint(x: leftEdge + repeatedWidth + (bendWidth * 0.5), y: bendY)
            bendNode.zPosition = ZLayer.worldFloorOverlay
            addChild(bendNode)
        }
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
        let interactionRange = effectiveInteractionRange(for: config, node: node)
        return hypot(dx, dy) <= interactionRange
    }

    private func isPlayerInBarRooms() -> Bool {
        guard let playerTile = tileCoordinate(for: player.position) else { return false }
        return worldConfig.barInteriorRegions.contains(where: { region in
            tileRegionContains(region, tile: playerTile)
        })
    }

    private func isPlayerInCarrollSalesArea() -> Bool {
        guard let playerTile = tileCoordinate(for: player.position) else { return false }
        return tileRegionContains(worldConfig.carrollSalesRegion, tile: playerTile)
    }

    private func checkBearProximity() {
                guard !isBearAttackInProgress,
                            mountedSnowmobileID == nil,
              let playerTile = tileCoordinate(for: player.position) else {
            return
        }

        let bearTile = worldConfig.bearDecorationTile
        let deltaColumns = abs(playerTile.column - bearTile.column)
        let deltaRows = abs(playerTile.row - bearTile.row)

        guard deltaColumns <= bearProximityColumns,
              deltaRows <= bearProximityRows else {
            return
        }

        guard let recoveryPoint = scenePointForTile(worldConfig.recoveryBedTile) else {
            return
        }

        beginBearAttackSequence(recoveryPoint: recoveryPoint)
    }

    private func beginBearAttackSequence(recoveryPoint: CGPoint) {
        guard !isBearAttackInProgress else { return }
        isBearAttackInProgress = true

        clearMoveTarget()
        player.physicsBody?.velocity = .zero
        setMenuVisible(false)

        let silhouetteOverlay = SKSpriteNode(color: UIColor.black.withAlphaComponent(0.55), size: size)
        silhouetteOverlay.position = .zero
        silhouetteOverlay.zPosition = ZLayer.bearAttackOverlay
        cameraNode.addChild(silhouetteOverlay)

        var silhouetteBearNode: SKSpriteNode?
        if let bearTexture = loadTexture(named: "bear") {
            let silhouetteBear = SKSpriteNode(texture: bearTexture)
            silhouetteBear.color = .black
            silhouetteBear.colorBlendFactor = 0.5  // 1.0 if you want a complete silhouette
            silhouetteBear.alpha = 0.95
            let maxWidth = size.width * 0.6
            let scale = maxWidth / max(1, bearTexture.size().width)
            silhouetteBear.size = CGSize(
                width: bearTexture.size().width * scale,
                height: bearTexture.size().height * scale
            )
            silhouetteBear.position = .zero
            silhouetteBear.zPosition = ZLayer.bearAttackOverlay + 1
            cameraNode.addChild(silhouetteBear)
            silhouetteBearNode = silhouetteBear
        }

        let blackoutOverlay = SKSpriteNode(color: .black, size: size)
        blackoutOverlay.position = .zero
        blackoutOverlay.alpha = 0
        blackoutOverlay.zPosition = ZLayer.bearAttackOverlay + 2
        cameraNode.addChild(blackoutOverlay)

        let waitBeforeFade = SKAction.wait(forDuration: 1.5)
        let fadeToBlack = SKAction.fadeAlpha(to: 1.0, duration: 0.25)
        let recover = SKAction.run { [weak self, weak silhouetteOverlay, weak silhouetteBearNode, weak blackoutOverlay] in
            guard let self else { return }

            self.player.position = recoveryPoint
            self.player.physicsBody?.velocity = .zero
            self.clearMoveTarget()

            silhouetteOverlay?.removeFromParent()
            silhouetteBearNode?.removeFromParent()
            blackoutOverlay?.removeFromParent()

            self.isBearAttackInProgress = false
            self.showMessage("You were attacked by a bear! You are now recovering at home.")
            self.markSaveDirty()
        }

        blackoutOverlay.run(SKAction.sequence([waitBeforeFade, fadeToBlack, recover]))
    }

    private func isSnowmobileDrivable(at scenePoint: CGPoint) -> Bool {
        guard let tile = tileCoordinate(for: scenePoint),
              let map = groundTileMap else { return false }

        if isRiverTile(tile) {
            return false
        }

        guard let floorTileName = map.tileGroup(atColumn: tile.column, row: tile.row)?.name else {
            return false
        }

        return !indoorSnowmobileBlockedFloorTiles.contains(floorTileName)
    }

    private func updateMountedSnowmobileUI() {
        let isMounted = mountedSnowmobileID != nil
        player.physicsBody?.collisionBitMask = isMounted ? PhysicsCategory.none : PhysicsCategory.wall
        player.alpha = 1.0
        // Mirror movement loop depth rule so immediate mount/dismount UI updates stay visually correct.
        player.zPosition = isMounted ? ZLayer.playerMounted : ZLayer.playerBase
    }

    private func isRiverTile(_ tile: TileCoordinate) -> Bool {
        guard let river = worldConfig.riverOverlay else { return false }
        return tile.column >= river.minColumn &&
            tile.column < river.maxColumnExclusive &&
            tile.row >= river.bottomRow &&
            tile.row < river.bottomRow + river.heightTiles
    }

    private func canDismountRaftToShore(from riverTile: TileCoordinate) -> Bool {
        let neighbors = [
            TileCoordinate(column: riverTile.column, row: riverTile.row + 1),
            TileCoordinate(column: riverTile.column + 1, row: riverTile.row),
            TileCoordinate(column: riverTile.column, row: riverTile.row - 1),
            TileCoordinate(column: riverTile.column - 1, row: riverTile.row)
        ]

        for tile in neighbors {
            guard tile.column >= 0,
                  tile.column < worldColumns,
                  tile.row >= 0,
                  tile.row < worldRows else {
                continue
            }
            if !isRiverTile(tile) && !worldConfig.wallTiles.contains(tile) {
                return true
            }
        }

        return false
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
        clearMoveTarget()
        player.physicsBody?.velocity = .zero
        isMapViewMode = false
        isDraggingMap = false
        cameraNode.setScale(1)
        mapCloseButtonNode?.isHidden = true
        setSnowmobileChoiceDialogVisible(false)
        setQuizDialogVisible(false)
        setSearsCatalogDialogVisible(false)
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
        isTrayCarried = false
        traySlicedPotatoCount = 0
        isChipsBasketCarried = false
        chipsBasketChipCount = 0
        isToiletBowlBrushCarried = false
        isToiletDirty = false
        toiletCleanDeadlineMove = nil
        nextToiletDirtyMove = ToiletEventSettings.randomDirtyIntervalMoves()
        hasShownToiletPenaltyStartMessage = false
        // Restore visual state of the toilet to match the reset logical state
        updateToiletVisualState()
        isTennisRacketCarried = false
        isShovelCarried = false
        isEnvelopeCarried = false
        carriedRaftID = nil
        riddenRaftID = nil
        pendingRaftDeliveryMoves.removeAll()
        nextRaftSequenceID = 1
        ownedSnowmobileIDs.removeAll()
        selectedOwnedSnowmobileID = nil
        mountedSnowmobileID = nil
        updateMountedSnowmobileUI()
        updateSnowmobileOwnershipVisuals()
        nextBatSpawnMove = BatEventSettings.randomSpawnIntervalMoves()
        batDefeatDeadlineMove = nil
        nextFoodOrderMove = FoodOrderEventSettings.randomSpawnIntervalMoves()
        foodOrderDeadlineMove = nil
        hasShownFirstSuccessfulChipDeliveryMessage = false
        trenchedSepticTiles.removeAll()
        hasAwardedSepticCompletionBonus = false
        resetSepticDigTiles()
        updateMakerLoadedIndicator()
        updateBucketPotatoIcon()
        updateFoodStateIcons()
        for (_, interactableNode) in interactableNodesByID {
            interactableNode.isHidden = false
        }
        for (id, homePosition) in interactableHomePositionByID {
            interactableNodesByID[id]?.position = homePosition
        }
        let dynamicRaftIDs = interactableNodesByID.keys.filter { $0.hasPrefix("raft_") }
        for raftID in dynamicRaftIDs {
            interactableNodesByID[raftID]?.removeFromParent()
            interactableNodesByID.removeValue(forKey: raftID)
            interactableConfigsByID.removeValue(forKey: raftID)
            interactableHomePositionByID.removeValue(forKey: raftID)
        }
        interactableNodesByID[bedroomBatID]?.isHidden = true
        interactableNodesByID[envelopeID]?.isHidden = true

        GameState.shared.resetCoins()
        GameState.shared.resetQuizStats()
        GameState.shared.addCoins(200)
        GameState.shared.resetStudyGuideOpenedBySubject()
        updateCoinLabel()
        updateStatusWindowBody()
        markSaveDirty()
        saveGameStateNow()

        // Reload the scene so all physics bodies (wall colliders, decoration
        // blockers) are freshly built from scratch.  This matches the behaviour
        // of a cold reinstall and avoids stale static physics bodies that can
        // block doorways after a soft Reset.
        if let view = self.view {
            let newScene = GameScene(size: self.size)
            newScene.scaleMode = self.scaleMode
            view.presentScene(newScene, transition: SKTransition.fade(withDuration: 0.3))
            // There's no easy way to display a "Progress reset" message after the new scene is loaded.
        } else {
            showMessage("Reset complete (unexpected: no view).")
        }
    }

    func showMessage(_ text: String) {
        messageLabel.removeAllActions()
        messageLabel.text = text
        messageLabel.alpha = 1
        let wait = SKAction.wait(forDuration: 5.0)
        let fade = SKAction.fadeOut(withDuration: 0.5)
        messageLabel.run(SKAction.sequence([wait, fade]))
    }
}
