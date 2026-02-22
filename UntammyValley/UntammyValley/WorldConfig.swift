//
//  WorldConfig.swift
//  UntammyValley
//
//  Created by Mark Riordan on 2026-02-18.
//

import CoreGraphics

struct TileCoordinate: Hashable, Codable {
    let column: Int
    let row: Int
}

struct TileRegion {
    let minColumn: Int
    let maxColumnExclusive: Int
    let minRow: Int
    let maxRowExclusive: Int
}

struct FloorRegion {
    let tileName: String
    let region: TileRegion
}

enum DecorationKind {
    case largeTextSign
    case sprite
}

struct DecorationConfig {
    let id: String
    let kind: DecorationKind
    let spriteName: String
    let labelText: String?
    let tile: TileCoordinate
    let size: CGSize
    let blocksMovement: Bool
}

enum InteractableKind {
    case potatoChips
    case deepFryer
    case chipsBasket
    case desk
    case snowmobile
    case toilet
    case toiletBowlBrush
    case potatoBin
    case bucket
    case spigot
    case chaseGoats
    case tennisRacket
    case bedroomBat
    case shovel
}

struct InteractableConfig {
    let id: String
    let kind: InteractableKind
    let spriteName: String
    let tile: TileCoordinate
    let size: CGSize
    let rewardCoins: Int
    let interactionRange: CGFloat
}

struct WorldConfig {
    let wallTiles: Set<TileCoordinate>
    let defaultFloorTileName: String
    let floorRegions: [FloorRegion]
    let doorwayFloorOverrides: [FloorRegion]
    let barInteriorRegions: [TileRegion]
    let carrollSalesRegion: TileRegion
    let septicDigTiles: Set<TileCoordinate>
    let roomLabels: [(name: String, tile: TileCoordinate)]
    let spawnTile: TileCoordinate
    let decorations: [DecorationConfig]
    let interactables: [InteractableConfig]

    static let current = WorldLoader.makeInitialBarWorld()

    private var maxConfiguredColumn: Int {
        var candidates: [Int] = []

        candidates.append(contentsOf: wallTiles.map { $0.column })
        candidates.append(contentsOf: septicDigTiles.map { $0.column })
        candidates.append(contentsOf: roomLabels.map { $0.tile.column })
        candidates.append(contentsOf: decorations.map { $0.tile.column })
        candidates.append(contentsOf: interactables.map { $0.tile.column })
        candidates.append(spawnTile.column)

        candidates.append(contentsOf: floorRegions.map { $0.region.maxColumnExclusive - 1 })
        candidates.append(contentsOf: doorwayFloorOverrides.map { $0.region.maxColumnExclusive - 1 })
        candidates.append(carrollSalesRegion.maxColumnExclusive - 1)

        return candidates.max() ?? 0
    }

    var recommendedWorldColumns: Int {
        let rightPadding = 8
        return max(104, maxConfiguredColumn + rightPadding + 1)
    }
}
