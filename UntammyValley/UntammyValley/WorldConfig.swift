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

enum InteractableKind {
    case potatoChips
    case potatoBin
    case bucket
    case spigot
    case chaseGoats
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
    let roomLabels: [(name: String, tile: TileCoordinate)]
    let spawnTile: TileCoordinate
    let interactables: [InteractableConfig]

    static let current = WorldLoader.makeInitialBarWorld()
}
