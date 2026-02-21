//
//  WorldConfig.swift
//  UntammyValley
//
//  Created by Mark Riordan on 2026-02-18.
//

import CoreGraphics

struct TileCoordinate: Hashable {
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
    let carrollSalesRegion: TileRegion
    let septicDigTiles: Set<TileCoordinate>
    let roomLabels: [(name: String, tile: TileCoordinate)]
    let spawnTile: TileCoordinate
    let decorations: [DecorationConfig]
    let interactables: [InteractableConfig]

    static let current = WorldLoader.makeInitialBarWorld()
}
