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

enum InteractableKind {
    case potatoChips
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
    let roomLabels: [(name: String, tile: TileCoordinate)]
    let spawnTile: TileCoordinate
    let potatoStation: InteractableConfig

    static let current = WorldLoader.makeInitialBarWorld()
}
