//
//  GameSaveSnapshot.swift
//  UntammyValley
//

import Foundation

struct SavedPoint: Codable {
    let x: Double
    let y: Double
}

struct GameSaveSnapshot: Codable {
    let schemaVersion: Int
    let appVersion: String
    let savedAt: Date

    let coins: Int
    let completedMoveCount: Int
    let playerPosition: SavedPoint

    let interactablePositionsByID: [String: SavedPoint]
    let hiddenInteractableIDs: [String]
    let respawnAtMoveByInteractableID: [String: Int]

    let isBucketCarried: Bool
    let bucketPotatoCount: Int
    let washedPotatoCount: Int
    let selectedPotatoForLoading: Bool
    let selectedPotatoIsWashed: Bool
    let peelerHasSlicedPotatoes: Bool
    let fryerSlicedPotatoCount: Int
    let isChipsBasketCarried: Bool
    let basketSlicedPotatoCount: Int
    let chipsBasketContainsChips: Bool
    let isToiletBowlBrushCarried: Bool
    let isTennisRacketCarried: Bool
    let isShovelCarried: Bool

    let ownedSnowmobileIDs: [String]
    let selectedOwnedSnowmobileID: String?
    let mountedSnowmobileID: String?

    let isToiletDirty: Bool
    let toiletCleanDeadlineMove: Int?
    let nextToiletDirtyMove: Int
    let hasShownToiletPenaltyStartMessage: Bool

    let nextBatSpawnMove: Int
    let batDefeatDeadlineMove: Int?

    let trenchedSepticTiles: [TileCoordinate]
    let hasAwardedSepticCompletionBonus: Bool
}
