//
//  GameSaveSnapshot.swift
//  UntammyValley
//

import Foundation

struct GameSaveSnapshot: Codable {
    let schemaVersion: Int
    let appVersion: String
    let savedAt: Date

    let coins: Int
    let completedMoveCount: Int
    let barCompletedMoveCount: Int?
    let playerTile: TileCoordinate

    let interactableTilesByID: [String: TileCoordinate]
    let hiddenInteractableIDs: [String]
    let respawnAtMoveByInteractableID: [String: Int]

    let isBucketCarried: Bool
    let bucketPotatoCount: Int
    let washedPotatoCount: Int
    let selectedPotatoForLoading: Bool
    let selectedPotatoIsWashed: Bool
    let peelerHasSlicedPotatoes: Bool
    let fryerSlicedPotatoCount: Int
    let isTrayCarried: Bool?
    let traySlicedPotatoCount: Int?
    let isChipsBasketCarried: Bool
    let basketSlicedPotatoCount: Int
    let chipsBasketChipCount: Int?
    let chipsBasketContainsChips: Bool
    let isToiletBowlBrushCarried: Bool
    let isTennisRacketCarried: Bool
    let isShovelCarried: Bool
    let isPropaneTankCarried: Bool?
    let isEnvelopeCarried: Bool?
    let isCrescentWrenchCarried: Bool?
    let carriedRaftID: String?
    let riddenRaftID: String?
    let pendingRaftDeliveryMoves: [Int]?
    let nextRaftSequenceID: Int?
    let hasShownFirstRaftDeliveryHint: Bool?
    let hasActivatedRaftCatalogTask: Bool?

    let ownedSnowmobileIDs: [String]
    let selectedOwnedSnowmobileID: String?
    let mountedSnowmobileID: String?

    let isToiletDirty: Bool
    let toiletCleanDeadlineMove: Int?
    let nextToiletDirtyMove: Int
    let hasShownToiletPenaltyStartMessage: Bool

    let quizStatsBySubject: [String: QuizSubjectStats]?
    let studyGuideOpenedBySubject: [String: Bool]

    let nextBatSpawnMove: Int
    let batDefeatDeadlineMove: Int?

    let nextFoodOrderMove: Int?
    let foodOrderDeadlineMove: Int?
    let hasShownFirstSuccessfulChipDeliveryMessage: Bool?

    let trenchedSepticTiles: [TileCoordinate]
    let hasAwardedSepticCompletionBonus: Bool
    let hasPropaneTankBeenDelivered: Bool?
    let hasRadioBeenDelivered: Bool?
    let hasUnlockedShed: Bool?
    let hasCrescentWrenchBeenDelivered: Bool?
    let hasRivetGunBeenDelivered: Bool?
    let snowTankerPartsCarriedIDs: [String]?
    let shedLockCombination: String?
    let isGymBinOpen: Bool?
}
