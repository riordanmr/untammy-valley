//
//  WorldLoader.swift
//  UntammyValley
//
//  Created by Mark Riordan on 2026-02-18.
//

import CoreGraphics

enum WorldLoader {
    private enum BarLayout {
        static let minColumn = 24
        static let minRow = 18
        static let singleRoomWidth = 8
        static let roomHeight = 12

        static var maxColumnExclusive: Int { minColumn + (singleRoomWidth * 3) }
        static var maxRowExclusive: Int { minRow + roomHeight }

        static var bedroomDiningWallColumn: Int { minColumn + singleRoomWidth }
        static var diningKitchenWallColumn: Int { minColumn + (singleRoomWidth * 2) }

        static let bedroomDiningDoorRows: Set<Int> = [23, 24]
        static let diningKitchenDoorRows: Set<Int> = [23, 24]
        static let diningOutsideDoorColumns: Set<Int> = [35, 36]
        static let kitchenCellarDoorColumns: Set<Int> = [43, 44]

        static var cellarMinColumn: Int { diningKitchenWallColumn }
        static var cellarMaxColumnExclusive: Int { maxColumnExclusive }
        static var cellarMinRow: Int { maxRowExclusive - 1 }
        static var cellarMaxRowExclusive: Int { cellarMinRow + 7 }

        static var bedroomLabelTile: TileCoordinate {
            TileCoordinate(column: minColumn + 4, row: minRow + roomHeight / 2)
        }

        static var diningLabelTile: TileCoordinate {
            TileCoordinate(column: minColumn + singleRoomWidth + 4, row: minRow + roomHeight / 2)
        }

        static var kitchenLabelTile: TileCoordinate {
            TileCoordinate(column: minColumn + (singleRoomWidth * 2) + 4, row: minRow + roomHeight / 2)
        }

        static var spawnTile: TileCoordinate {
            TileCoordinate(column: minColumn + 3, row: minRow + roomHeight / 2)
        }

        static var potatoStationTile: TileCoordinate {
            TileCoordinate(column: diningKitchenWallColumn + 3, row: minRow + 4)
        }

        static var goatChaseTile: TileCoordinate {
            TileCoordinate(column: minColumn + singleRoomWidth + 4, row: minRow - 3)
        }

        static var potatoBinTile: TileCoordinate {
            TileCoordinate(column: cellarMinColumn + 2, row: cellarMaxRowExclusive - 2)
        }

        static var bucketStartTile: TileCoordinate {
            TileCoordinate(column: diningKitchenWallColumn + 2, row: maxRowExclusive - 3)
        }

        static var cellarLabelTile: TileCoordinate {
            TileCoordinate(column: diningKitchenWallColumn + 4, row: cellarMinRow + 3)
        }
    }

    static func makeInitialBarWorld() -> WorldConfig {
        var wallTiles = Set<TileCoordinate>()

        for column in BarLayout.minColumn..<BarLayout.maxColumnExclusive {
            if !BarLayout.kitchenCellarDoorColumns.contains(column) {
                wallTiles.insert(TileCoordinate(column: column, row: BarLayout.maxRowExclusive - 1))
            }
            if BarLayout.kitchenCellarDoorColumns.contains(column) {
                continue
            }
            if !BarLayout.diningOutsideDoorColumns.contains(column) {
                wallTiles.insert(TileCoordinate(column: column, row: BarLayout.minRow))
            }
        }

        for row in BarLayout.minRow..<BarLayout.maxRowExclusive {
            wallTiles.insert(TileCoordinate(column: BarLayout.minColumn, row: row))
            wallTiles.insert(TileCoordinate(column: BarLayout.maxColumnExclusive - 1, row: row))

            if !BarLayout.bedroomDiningDoorRows.contains(row) {
                wallTiles.insert(TileCoordinate(column: BarLayout.bedroomDiningWallColumn, row: row))
            }
            if !BarLayout.diningKitchenDoorRows.contains(row) {
                wallTiles.insert(TileCoordinate(column: BarLayout.diningKitchenWallColumn, row: row))
            }
        }

        // Cellar room north of the kitchen
        for column in BarLayout.cellarMinColumn..<BarLayout.cellarMaxColumnExclusive {
            wallTiles.insert(TileCoordinate(column: column, row: BarLayout.cellarMaxRowExclusive - 1))
        }

        for row in BarLayout.cellarMinRow..<BarLayout.cellarMaxRowExclusive {
            wallTiles.insert(TileCoordinate(column: BarLayout.cellarMinColumn, row: row))
            wallTiles.insert(TileCoordinate(column: BarLayout.cellarMaxColumnExclusive - 1, row: row))
        }

        let roomLabels: [(name: String, tile: TileCoordinate)] = [
            ("Bedroom", BarLayout.bedroomLabelTile),
            ("Dining", BarLayout.diningLabelTile),
            ("Kitchen", BarLayout.kitchenLabelTile),
            ("Cellar", BarLayout.cellarLabelTile)
        ]

        let interiorMinRow = BarLayout.minRow + 1
        let interiorMaxRowExclusive = BarLayout.maxRowExclusive - 1

        let floorRegions: [FloorRegion] = [
            FloorRegion(
                tileName: "floor_wood",
                region: TileRegion(
                    minColumn: BarLayout.minColumn + 1,
                    maxColumnExclusive: BarLayout.bedroomDiningWallColumn,
                    minRow: interiorMinRow,
                    maxRowExclusive: interiorMaxRowExclusive
                )
            ),
            FloorRegion(
                tileName: "floor_carpet",
                region: TileRegion(
                    minColumn: BarLayout.bedroomDiningWallColumn + 1,
                    maxColumnExclusive: BarLayout.diningKitchenWallColumn,
                    minRow: interiorMinRow,
                    maxRowExclusive: interiorMaxRowExclusive
                )
            ),
            FloorRegion(
                tileName: "floor_linoleum",
                region: TileRegion(
                    minColumn: BarLayout.diningKitchenWallColumn + 1,
                    maxColumnExclusive: BarLayout.maxColumnExclusive - 1,
                    minRow: interiorMinRow,
                    maxRowExclusive: interiorMaxRowExclusive
                )
            ),
            FloorRegion(
                tileName: "floor_linoleum",
                region: TileRegion(
                    minColumn: BarLayout.cellarMinColumn + 1,
                    maxColumnExclusive: BarLayout.cellarMaxColumnExclusive - 1,
                    minRow: BarLayout.cellarMinRow + 1,
                    maxRowExclusive: BarLayout.cellarMaxRowExclusive - 1
                )
            )
        ]

        let doorwayFloorOverrides: [FloorRegion] = [
            // Bedroom <-> Dining doorway: use bedroom floor
            FloorRegion(
                tileName: "floor_wood",
                region: TileRegion(
                    minColumn: BarLayout.bedroomDiningWallColumn,
                    maxColumnExclusive: BarLayout.bedroomDiningWallColumn + 1,
                    minRow: BarLayout.bedroomDiningDoorRows.min() ?? BarLayout.minRow,
                    maxRowExclusive: (BarLayout.bedroomDiningDoorRows.max() ?? BarLayout.minRow) + 1
                )
            ),
            // Dining <-> Kitchen doorway: use dining floor
            FloorRegion(
                tileName: "floor_carpet",
                region: TileRegion(
                    minColumn: BarLayout.diningKitchenWallColumn,
                    maxColumnExclusive: BarLayout.diningKitchenWallColumn + 1,
                    minRow: BarLayout.diningKitchenDoorRows.min() ?? BarLayout.minRow,
                    maxRowExclusive: (BarLayout.diningKitchenDoorRows.max() ?? BarLayout.minRow) + 1
                )
            ),
            // Dining <-> Outside doorway: keep threshold as dining floor
            FloorRegion(
                tileName: "floor_carpet",
                region: TileRegion(
                    minColumn: BarLayout.diningOutsideDoorColumns.min() ?? BarLayout.minColumn,
                    maxColumnExclusive: (BarLayout.diningOutsideDoorColumns.max() ?? BarLayout.minColumn) + 1,
                    minRow: BarLayout.minRow,
                    maxRowExclusive: BarLayout.minRow + 1
                )
            ),
            // Kitchen <-> Cellar doorway: keep threshold as kitchen floor
            FloorRegion(
                tileName: "floor_linoleum",
                region: TileRegion(
                    minColumn: BarLayout.kitchenCellarDoorColumns.min() ?? BarLayout.cellarMinColumn,
                    maxColumnExclusive: (BarLayout.kitchenCellarDoorColumns.max() ?? BarLayout.cellarMinColumn) + 1,
                    minRow: BarLayout.cellarMinRow,
                    maxRowExclusive: BarLayout.cellarMinRow + 1
                )
            )
        ]

        let potatoStation = InteractableConfig(
            id: "potatoStation",
            kind: .potatoChips,
            spriteName: "potato_grinder",
            tile: BarLayout.potatoStationTile,
            size: CGSize(width: 46, height: 46),
            rewardCoins: 5,
            interactionRange: 90
        )

        let goatChaseSpot = InteractableConfig(
            id: "goatChaseSpot",
            kind: .chaseGoats,
            spriteName: "goat_chase_marker",
            tile: BarLayout.goatChaseTile,
            size: CGSize(width: 46, height: 46),
            rewardCoins: 7,
            interactionRange: 95
        )

        let potatoBin = InteractableConfig(
            id: "potatoBin",
            kind: .potatoBin,
            spriteName: "potato_bin",
            tile: BarLayout.potatoBinTile,
            size: CGSize(width: 50, height: 50),
            rewardCoins: 0,
            interactionRange: 95
        )

        let bucket = InteractableConfig(
            id: "bucket",
            kind: .bucket,
            spriteName: "bucket_marker",
            tile: BarLayout.bucketStartTile,
            size: CGSize(width: 40, height: 40),
            rewardCoins: 0,
            interactionRange: 95
        )

        return WorldConfig(
            wallTiles: wallTiles,
            defaultFloorTileName: "floor_outdoor",
            floorRegions: floorRegions,
            doorwayFloorOverrides: doorwayFloorOverrides,
            roomLabels: roomLabels,
            spawnTile: BarLayout.spawnTile,
            interactables: [potatoStation, potatoBin, bucket, goatChaseSpot]
        )
    }
}
