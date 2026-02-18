//
//  WorldLoader.swift
//  UntammyValley
//
//  Created by Mark Riordan on 2026-02-18.
//

import CoreGraphics

enum WorldLoader {
    static func makeInitialBarWorld() -> WorldConfig {
        let barMinX = 24
        let barMinY = 18
        let singleRoomWidth = 8
        let roomHeight = 12
        let barMaxX = barMinX + (singleRoomWidth * 3)
        let barMaxY = barMinY + roomHeight

        let bedroomDiningWallX = barMinX + singleRoomWidth
        let diningKitchenWallX = barMinX + (singleRoomWidth * 2)

        let bedroomDiningDoorRows: Set<Int> = [23, 24]
        let diningKitchenDoorRows: Set<Int> = [23, 24]
        let diningOutsideDoorColumns: Set<Int> = [35, 36]

        var wallTiles = Set<TileCoordinate>()

        for column in barMinX..<barMaxX {
            wallTiles.insert(TileCoordinate(column: column, row: barMaxY - 1))
            if !diningOutsideDoorColumns.contains(column) {
                wallTiles.insert(TileCoordinate(column: column, row: barMinY))
            }
        }

        for row in barMinY..<barMaxY {
            wallTiles.insert(TileCoordinate(column: barMinX, row: row))
            wallTiles.insert(TileCoordinate(column: barMaxX - 1, row: row))

            if !bedroomDiningDoorRows.contains(row) {
                wallTiles.insert(TileCoordinate(column: bedroomDiningWallX, row: row))
            }
            if !diningKitchenDoorRows.contains(row) {
                wallTiles.insert(TileCoordinate(column: diningKitchenWallX, row: row))
            }
        }

        let roomLabels: [(name: String, tile: TileCoordinate)] = [
            ("Bedroom", TileCoordinate(column: barMinX + 4, row: barMinY + roomHeight / 2)),
            ("Dining", TileCoordinate(column: barMinX + singleRoomWidth + 4, row: barMinY + roomHeight / 2)),
            ("Kitchen", TileCoordinate(column: barMinX + (singleRoomWidth * 2) + 4, row: barMinY + roomHeight / 2))
        ]

        let spawnTile = TileCoordinate(column: barMinX + 3, row: barMinY + roomHeight / 2)

        let potatoStation = InteractableConfig(
            id: "potatoStation",
            kind: .potatoChips,
            spriteName: "potato_grinder",
            tile: TileCoordinate(column: diningKitchenWallX + 3, row: barMinY + 4),
            size: CGSize(width: 46, height: 46),
            rewardCoins: 5,
            interactionRange: 90
        )

        let goatChaseSpot = InteractableConfig(
            id: "goatChaseSpot",
            kind: .chaseGoats,
            spriteName: "goat_chase_marker",
            tile: TileCoordinate(column: barMinX + singleRoomWidth + 4, row: barMinY - 3),
            size: CGSize(width: 46, height: 46),
            rewardCoins: 7,
            interactionRange: 95
        )

        return WorldConfig(
            wallTiles: wallTiles,
            roomLabels: roomLabels,
            spawnTile: spawnTile,
            interactables: [potatoStation, goatChaseSpot]
        )
    }
}
