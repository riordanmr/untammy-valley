//
//  WorldLoader.swift
//  UntammyValley
//
//  Created by Mark Riordan on 2026-02-18.
//

import CoreGraphics

enum WorldLoader {
    private struct SeededGenerator: RandomNumberGenerator {
        private var state: UInt64

        init(seed: UInt64) {
            state = seed == 0 ? 0x9E3779B97F4A7C15 : seed
        }

        mutating func next() -> UInt64 {
            state = state &* 6364136223846793005 &+ 1442695040888963407
            return state
        }
    }

    private enum BarLayout {
        static let objectScale: CGFloat = 1.2
        static let baseObjectSize: CGFloat = 48

        static let minColumn = 88
        static let minRow = 18
        static let singleRoomWidth = 8
        static let diningRoomExtraWidth = 3
        static let roomHeight = 12

        static var bedroomRoomWidth: Int { singleRoomWidth }
        static var diningRoomWidth: Int { singleRoomWidth + diningRoomExtraWidth }
        static var kitchenRoomWidth: Int { singleRoomWidth }

        static func scaledSize(width: CGFloat, height: CGFloat) -> CGSize {
            CGSize(width: width * objectScale, height: height * objectScale)
        }

        static var standardObjectSize: CGSize {
            scaledSize(width: baseObjectSize, height: baseObjectSize)
        }

        static var deskSize: CGSize {
            scaledSize(width: baseObjectSize * 2 * 1.3, height: baseObjectSize * 1.3)
        }

        static var teachersDeskSize: CGSize {
            scaledSize(width: baseObjectSize, height: baseObjectSize * 2)
        }

        static var chipMakerSize: CGSize {
            scaledSize(width: baseObjectSize * 1.5, height: baseObjectSize * 1.5)
        }

        static var deepFryerSize: CGSize {
            scaledSize(width: baseObjectSize * 2, height: baseObjectSize * 4)
        }

        static var potatoBinSize: CGSize {
            scaledSize(width: baseObjectSize * 2, height: baseObjectSize * 2)
        }

        static var bedSize: CGSize {
            scaledSize(width: baseObjectSize * (10.0 / 3.0), height: baseObjectSize * (5.0 / 3.0))
        }

        static var largeSignSize: CGSize {
            scaledSize(width: baseObjectSize * 3, height: baseObjectSize * 2)
        }

        static var snowmobileSize: CGSize {
            scaledSize(width: baseObjectSize * 2, height: baseObjectSize * 2)
        }

        static var parkingCarSize: CGSize {
            CGSize(width: baseObjectSize * 2, height: baseObjectSize * 4)
        }

        static var livingRoomBarSize: CGSize {
            scaledSize(width: baseObjectSize * 1.5, height: baseObjectSize * 7)
        }

        static var stoolTileSize: CGSize {
            CGSize(width: 64, height: 64)
        }

        static var patronStoolTileSize: CGSize {
            CGSize(width: 64, height: 128)
        }

        static var studyGuideSize: CGSize {
            scaledSize(width: baseObjectSize * 0.6, height: baseObjectSize * 0.6)
        }

        static var treeSizes: [CGSize] {
            [
                scaledSize(width: baseObjectSize * (43.0 / 12.0), height: baseObjectSize * (25.0 / 6.0)),
                scaledSize(width: baseObjectSize * (23.0 / 6.0), height: baseObjectSize * (40.0 / 9.0)),
                scaledSize(width: baseObjectSize * (49.0 / 12.0), height: baseObjectSize * (85.0 / 18.0))
            ]
        }

        static var maxColumnExclusive: Int { minColumn + bedroomRoomWidth + diningRoomWidth + kitchenRoomWidth }
        static var maxRowExclusive: Int { minRow + roomHeight }

        static var barWidth: Int { bedroomRoomWidth + diningRoomWidth + kitchenRoomWidth }

        static var bedroomDiningWallColumn: Int { minColumn + bedroomRoomWidth }
        static var diningKitchenWallColumn: Int { bedroomDiningWallColumn + diningRoomWidth }

        static let bedroomDiningDoorRows: Set<Int> = [23, 24]
        static let diningKitchenDoorRows: Set<Int> = [21, 22]
        static var diningOutsideDoorColumns: Set<Int> { [bedroomDiningWallColumn + 3, bedroomDiningWallColumn + 4] }
        static var kitchenCellarDoorColumns: Set<Int> { [diningKitchenWallColumn + 3, diningKitchenWallColumn + 4] }

        static var cellarMinColumn: Int { diningKitchenWallColumn }
        static var cellarMaxColumnExclusive: Int { maxColumnExclusive }
        static var cellarMinRow: Int { maxRowExclusive - 1 }
        static var cellarMaxRowExclusive: Int { cellarMinRow + 7 }

        static var bedroomLabelTile: TileCoordinate {
            TileCoordinate(column: minColumn + 4, row: minRow + roomHeight / 2)
        }

        static var diningLabelTile: TileCoordinate {
            TileCoordinate(column: bedroomDiningWallColumn + (diningRoomWidth / 2), row: minRow + roomHeight / 2)
        }

        static var kitchenLabelTile: TileCoordinate {
            TileCoordinate(column: diningKitchenWallColumn + (kitchenRoomWidth / 2), row: minRow + roomHeight / 2)
        }

        static var spawnTile: TileCoordinate {
            TileCoordinate(column: minColumn + 3, row: minRow + roomHeight / 2)
        }

        static var potatoPeelerTile: TileCoordinate {
     //was  TileCoordinate(column: diningKitchenWallColumn + 3, row: minRow + 4)
            TileCoordinate(column: diningKitchenWallColumn + 5, row: minRow + 3)
            //TileCoordinate(column: maxColumnExclusive - 0, row: minRow + 2) // was -2, +3
        }

        static var deepFryerTile: TileCoordinate {
            TileCoordinate(column: maxColumnExclusive - 3, row: minRow + 6)
        }

        static var chipsBasketTile: TileCoordinate {
            TileCoordinate(column: deepFryerTile.column, row: deepFryerTile.row - 2)
        }

        static var trayTile: TileCoordinate {
            TileCoordinate(column: chipsBasketTile.column - 1, row: chipsBasketTile.row)
        }

        static var livingRoomBarTile: TileCoordinate {
            TileCoordinate(
                column: diningKitchenWallColumn - 3,
                row: maxRowExclusive - 5
            )
        }

        static var barStoolColumn: Int {
            livingRoomBarTile.column - 1
        }

        static var topBarStoolTile: TileCoordinate {
            TileCoordinate(column: barStoolColumn, row: livingRoomBarTile.row + 2)
        }

        static var centerBarStoolTile: TileCoordinate {
            TileCoordinate(column: barStoolColumn, row: livingRoomBarTile.row)
        }

        static var patronBarStoolTile: TileCoordinate {
            TileCoordinate(column: barStoolColumn, row: livingRoomBarTile.row - 2)
        }

        // River sits above the bar: bottom is 10 tiles above bar top, height is 10 tiles.
        static var riverBottomRow: Int {
            (maxRowExclusive - 1) + 23
        }

        static var riverHeightTiles: Int {
            10
        }

        static var riverTopRow: Int {
            riverBottomRow + riverHeightTiles - 1
        }

        static var riverMinColumn: Int {
            0
        }

        static var riverMaxColumnExclusive: Int {
            ((maxColumnExclusive - 1) + 12) + 1
        }

        static var goatChaseTile: TileCoordinate {
            parkingCarTiles[1]
        }

        static var parkingCarTiles: [TileCoordinate] {
            let centerColumn = diningLabelTile.column
            let carRow = minRow - 4
            return [
                TileCoordinate(column: centerColumn - 3, row: carRow),
                TileCoordinate(column: centerColumn, row: carRow),
                TileCoordinate(column: centerColumn + 3, row: carRow)
            ]
        }

        static var carrollSignTile: TileCoordinate {
            TileCoordinate(
                column: max(2, minColumn - (barWidth * 2) + (barWidth / 2)),
                row: minRow + roomHeight / 2
            )
        }

        /// Sign below the bar, between dining room and kitchen.
        static var cramerSignTile: TileCoordinate {
            TileCoordinate(column: diningKitchenWallColumn, row: minRow - 3)
        }

        static var snowmobileTiles: [TileCoordinate] {
            [
                TileCoordinate(column: carrollSignTile.column + 5, row: carrollSignTile.row + 2),
                TileCoordinate(column: carrollSignTile.column + 6, row: carrollSignTile.row + 3),
                TileCoordinate(column: carrollSignTile.column + 7, row: carrollSignTile.row + 1),
                TileCoordinate(column: carrollSignTile.column + 8, row: carrollSignTile.row - 2),
                TileCoordinate(column: carrollSignTile.column + 6, row: carrollSignTile.row - 3),
                TileCoordinate(column: carrollSignTile.column + 7, row: carrollSignTile.row - 1)
            ]
        }

        static var carrollSalesRegion: TileRegion {
            let allColumns = [carrollSignTile.column] + snowmobileTiles.map { $0.column }
            let allRows = [carrollSignTile.row] + snowmobileTiles.map { $0.row }

            let minCol = max(0, (allColumns.min() ?? carrollSignTile.column) - 2)
            let maxColExclusive = (allColumns.max() ?? carrollSignTile.column) + 3
            let minRow = max(0, (allRows.min() ?? carrollSignTile.row) - 2)
            let maxRowExclusive = (allRows.max() ?? carrollSignTile.row) + 3

            return TileRegion(
                minColumn: minCol,
                maxColumnExclusive: maxColExclusive,
                minRow: minRow,
                maxRowExclusive: maxRowExclusive
            )
        }

        static var potatoBinTile: TileCoordinate {
            TileCoordinate(column: cellarMinColumn + 2, row: cellarMaxRowExclusive - 3)
        }

        static var bucketStartTile: TileCoordinate {
            TileCoordinate(column: deepFryerTile.column, row: deepFryerTile.row + 2)
        }

        static var cellarLabelTile: TileCoordinate {
            TileCoordinate(column: diningKitchenWallColumn + 4, row: cellarMinRow + 3)
        }

        static var spigotTile: TileCoordinate {
            TileCoordinate(column: maxColumnExclusive, row: minRow + roomHeight / 2)
        }

        static var tennisRacketTile: TileCoordinate {
            TileCoordinate(column: minColumn + 2, row: minRow + 10)
        }

        static var bedroomBatTile: TileCoordinate {
            TileCoordinate(column: minColumn + 5, row: minRow + 8)
        }

        static var deskTile: TileCoordinate {
            TileCoordinate(column: bedroomDiningWallColumn - 2, row: maxRowExclusive - 2)
        }

        static var studyGuideTile: TileCoordinate {
            TileCoordinate(column: deskTile.column, row: deskTile.row)
        }

        static var searsCatalogTile: TileCoordinate {
            TileCoordinate(column: deskTile.column, row: deskTile.row)
        }

        static var bedTiles: [TileCoordinate] {
            [
                TileCoordinate(column: minColumn + 2, row: minRow + 8),
                TileCoordinate(column: minColumn + 2, row: minRow + 5),
                TileCoordinate(column: minColumn + 2, row: minRow + 2)
            ]
        }

        static var shovelTile: TileCoordinate {
            TileCoordinate(column: cellarMaxColumnExclusive - 2, row: cellarMaxRowExclusive - 2)
        }

        static let bathroomInteriorWidth = 3
        static let bathroomInteriorHeight = 2

        static var bathroomInteriorMinColumn: Int { bedroomDiningWallColumn + 1 }
        static var bathroomInteriorMaxColumnExclusive: Int { bathroomInteriorMinColumn + bathroomInteriorWidth }
        static var bathroomInteriorMaxRowExclusive: Int { maxRowExclusive - 1 }
        static var bathroomInteriorMinRow: Int { bathroomInteriorMaxRowExclusive - bathroomInteriorHeight }

        static var bathroomLeftWallColumn: Int { bathroomInteriorMinColumn - 1 }
        static var bathroomBottomWallRow: Int { bathroomInteriorMinRow - 1 }
        static var bathroomDoorColumn: Int { bathroomInteriorMaxColumnExclusive - 1 }

        static var toiletTile: TileCoordinate {
            TileCoordinate(
                column: bathroomInteriorMinColumn,
                row: bathroomInteriorMaxRowExclusive - 1
            )
        }

        static var toiletBowlBrushTile: TileCoordinate {
            TileCoordinate(
                column: toiletTile.column,
                row: toiletTile.row - 1
            )
        }

        static let septicSystemWidth = 2
        static let septicSystemHeight = 5
        static let septicGapColumns = 7

        static var leftSepticMinColumn: Int { maxColumnExclusive + 4 }
        static var leftSepticMinRow: Int { minRow - 7 }

        static var rightSepticMinColumn: Int {
            leftSepticMinColumn + septicSystemWidth + septicGapColumns
        }

        static var septicMidRow: Int { leftSepticMinRow + (septicSystemHeight / 2) }

        static var leftSepticRegion: TileRegion {
            TileRegion(
                minColumn: leftSepticMinColumn,
                maxColumnExclusive: leftSepticMinColumn + septicSystemWidth,
                minRow: leftSepticMinRow,
                maxRowExclusive: leftSepticMinRow + septicSystemHeight
            )
        }

        static var rightSepticRegion: TileRegion {
            TileRegion(
                minColumn: rightSepticMinColumn,
                maxColumnExclusive: rightSepticMinColumn + septicSystemWidth,
                minRow: leftSepticMinRow,
                maxRowExclusive: leftSepticMinRow + septicSystemHeight
            )
        }

        static var septicDigTiles: Set<TileCoordinate> {
            let startColumn = leftSepticMinColumn + septicSystemWidth
            let endColumnInclusive = rightSepticMinColumn - 1
            guard startColumn <= endColumnInclusive else { return [] }
            return Set((startColumn...endColumnInclusive).map {
                TileCoordinate(column: $0, row: septicMidRow)
            })
        }
    }

    static func makeInitialBarWorld() -> WorldConfig {
        var wallTiles = Set<TileCoordinate>()
        SchoolLayout.configure(
            barWidth: BarLayout.barWidth,
            barRightWallColumn: BarLayout.maxColumnExclusive - 1,
            minRow: BarLayout.minRow
        )

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

        for row in BarLayout.bathroomInteriorMinRow..<BarLayout.maxRowExclusive {
            wallTiles.insert(TileCoordinate(column: BarLayout.bathroomLeftWallColumn, row: row))
            wallTiles.insert(TileCoordinate(column: BarLayout.bathroomInteriorMaxColumnExclusive, row: row))
        }

        for column in BarLayout.bathroomLeftWallColumn...BarLayout.bathroomInteriorMaxColumnExclusive {
            if column == BarLayout.bathroomDoorColumn {
                continue
            }
            wallTiles.insert(TileCoordinate(column: column, row: BarLayout.bathroomBottomWallRow))
        }

        // Cellar room north of the kitchen
        for column in BarLayout.cellarMinColumn..<BarLayout.cellarMaxColumnExclusive {
            wallTiles.insert(TileCoordinate(column: column, row: BarLayout.cellarMaxRowExclusive - 1))
        }

        for row in BarLayout.cellarMinRow..<BarLayout.cellarMaxRowExclusive {
            wallTiles.insert(TileCoordinate(column: BarLayout.cellarMinColumn, row: row))
            wallTiles.insert(TileCoordinate(column: BarLayout.cellarMaxColumnExclusive - 1, row: row))
        }

        // --- School shell ---
        for column in SchoolLayout.minColumn..<SchoolLayout.maxColumnExclusive {
            wallTiles.insert(TileCoordinate(column: column, row: SchoolLayout.minRow))
            wallTiles.insert(TileCoordinate(column: column, row: SchoolLayout.maxRowExclusive - 1))
        }

        for row in SchoolLayout.minRow..<SchoolLayout.maxRowExclusive {
            if !SchoolLayout.leftExteriorDoorRows.contains(row) {
                wallTiles.insert(TileCoordinate(column: SchoolLayout.minColumn, row: row))
            }
            wallTiles.insert(TileCoordinate(column: SchoolLayout.maxColumnExclusive - 1, row: row))
        }

        // Horizontal walls separating classrooms and hall (with 2-tile doors per classroom).
        for column in (SchoolLayout.minColumn + 1)..<SchoolLayout.gymDividerColumn {
            if !SchoolLayout.classroomDoorColumns.contains(column) {
                wallTiles.insert(TileCoordinate(column: column, row: SchoolLayout.topClassroomDividerRow))
                wallTiles.insert(TileCoordinate(column: column, row: SchoolLayout.bottomClassroomDividerRow))
            }
        }

        // Vertical divider between left and right classrooms above/below hall.
        for row in (SchoolLayout.minRow + 1)..<(SchoolLayout.maxRowExclusive - 1) {
            if row >= SchoolLayout.hallMinRow && row < SchoolLayout.hallMaxRowExclusive {
                continue
            }
            wallTiles.insert(TileCoordinate(column: SchoolLayout.classroomVerticalDividerColumn, row: row))
        }

        // Divider between hall/classrooms block and gym, with a 4-tile hall door.
        for row in (SchoolLayout.minRow + 1)..<(SchoolLayout.maxRowExclusive - 1) {
            if SchoolLayout.hallToGymDoorRows.contains(row) {
                continue
            }
            wallTiles.insert(TileCoordinate(column: SchoolLayout.gymDividerColumn, row: row))
        }

        let roomLabels: [(name: String, tile: TileCoordinate)] = [
            ("Bedroom", BarLayout.bedroomLabelTile),
            ("Dining", BarLayout.diningLabelTile),
            ("Kitchen", BarLayout.kitchenLabelTile),
            ("Cellar", BarLayout.cellarLabelTile),
            ("School Hall", SchoolLayout.hallLabelTile),
            ("English", SchoolLayout.classroomTopLeftLabelTile),
            ("History", SchoolLayout.classroomTopRightLabelTile),
            ("Mathematics", SchoolLayout.classroomBottomLeftLabelTile),
            ("Science", SchoolLayout.classroomBottomRightLabelTile),
            ("Gym", SchoolLayout.gymLabelTile)
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
                    minColumn: BarLayout.bathroomInteriorMinColumn,
                    maxColumnExclusive: BarLayout.bathroomInteriorMaxColumnExclusive,
                    minRow: BarLayout.bathroomInteriorMinRow,
                    maxRowExclusive: BarLayout.bathroomInteriorMaxRowExclusive
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
            ),
            FloorRegion(
                tileName: "septic_cover",
                region: BarLayout.leftSepticRegion
            ),
            FloorRegion(
                tileName: "septic_cover",
                region: BarLayout.rightSepticRegion
            ),
            FloorRegion(
                tileName: "floor_carroll_sales",
                region: BarLayout.carrollSalesRegion
            ),
            FloorRegion(
                tileName: "floor_linoleum",
                region: TileRegion(
                    minColumn: SchoolLayout.minColumn + 1,
                    maxColumnExclusive: SchoolLayout.gymDividerColumn,
                    minRow: SchoolLayout.hallMinRow,
                    maxRowExclusive: SchoolLayout.hallMaxRowExclusive
                )
            ),
            FloorRegion(
                tileName: "floor_carpet",
                region: TileRegion(
                    minColumn: SchoolLayout.minColumn + 1,
                    maxColumnExclusive: SchoolLayout.classroomVerticalDividerColumn,
                    minRow: SchoolLayout.hallMaxRowExclusive,
                    maxRowExclusive: SchoolLayout.maxRowExclusive - 1
                )
            ),
            FloorRegion(
                tileName: "floor_carpet",
                region: TileRegion(
                    minColumn: SchoolLayout.classroomVerticalDividerColumn + 1,
                    maxColumnExclusive: SchoolLayout.gymDividerColumn,
                    minRow: SchoolLayout.hallMaxRowExclusive,
                    maxRowExclusive: SchoolLayout.maxRowExclusive - 1
                )
            ),
            FloorRegion(
                tileName: "floor_carpet",
                region: TileRegion(
                    minColumn: SchoolLayout.minColumn + 1,
                    maxColumnExclusive: SchoolLayout.classroomVerticalDividerColumn,
                    minRow: SchoolLayout.minRow + 1,
                    maxRowExclusive: SchoolLayout.hallMinRow
                )
            ),
            FloorRegion(
                tileName: "floor_carpet",
                region: TileRegion(
                    minColumn: SchoolLayout.classroomVerticalDividerColumn + 1,
                    maxColumnExclusive: SchoolLayout.gymDividerColumn,
                    minRow: SchoolLayout.minRow + 1,
                    maxRowExclusive: SchoolLayout.hallMinRow
                )
            ),
            FloorRegion(
                tileName: "floor_wood",
                region: TileRegion(
                    minColumn: SchoolLayout.gymDividerColumn + 1,
                    maxColumnExclusive: SchoolLayout.maxColumnExclusive - 1,
                    minRow: SchoolLayout.minRow + 1,
                    maxRowExclusive: SchoolLayout.maxRowExclusive - 1
                )
            ),
            FloorRegion(
                tileName: "floor_wood",
                region: TileRegion(
                    minColumn: SchoolLayout.gymDividerColumn + 1,
                    maxColumnExclusive: SchoolLayout.gymDividerColumn + 2,
                    minRow: SchoolLayout.hallToGymTransitionMinRow,
                    maxRowExclusive: SchoolLayout.hallToGymTransitionMaxRowExclusive
                )
            ),
            FloorRegion(
                tileName: "floor_linoleum",
                region: TileRegion(
                    minColumn: SchoolLayout.gymDividerColumn,
                    maxColumnExclusive: SchoolLayout.gymDividerColumn + 1,
                    minRow: SchoolLayout.hallToGymDoorRows.min() ?? SchoolLayout.hallMinRow,
                    maxRowExclusive: (SchoolLayout.hallToGymDoorRows.max() ?? (SchoolLayout.hallMinRow + 1)) + 1
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

        let riverOverlay = RiverOverlayConfig(
            minColumn: BarLayout.riverMinColumn,
            maxColumnExclusive: BarLayout.riverMaxColumnExclusive,
            bottomRow: BarLayout.riverBottomRow,
            heightTiles: BarLayout.riverHeightTiles,
            repeatedSpriteName: "river_with_banks",
            rightEdgeSpriteName: "river_bend"
        )

        let barInteriorRegions: [TileRegion] = [
            TileRegion(
                minColumn: BarLayout.minColumn,
                maxColumnExclusive: BarLayout.maxColumnExclusive,
                minRow: BarLayout.minRow,
                maxRowExclusive: BarLayout.maxRowExclusive
            ),
            TileRegion(
                minColumn: BarLayout.cellarMinColumn,
                maxColumnExclusive: BarLayout.cellarMaxColumnExclusive,
                minRow: BarLayout.cellarMinRow,
                maxRowExclusive: BarLayout.cellarMaxRowExclusive
            )
        ]

        let potatoPeeler = InteractableConfig(
            id: "potatoPeeler",
            kind: .potatoChips,
            spriteName: "potato_grinder",
            tile: BarLayout.potatoPeelerTile,
            size: BarLayout.chipMakerSize,
            rewardCoins: 5,
            interactionRange: 90
        )

        let deepFryer = InteractableConfig(
            id: "deepFryer",
            kind: .deepFryer,
            spriteName: "deep_fryer_marker",
            tile: BarLayout.deepFryerTile,
            size: BarLayout.deepFryerSize,
            rewardCoins: 0,
            interactionRange: 95
        )

        let chipsBasket = InteractableConfig(
            id: "chipsBasket",
            kind: .chipsBasket,
            spriteName: "chips_basket_marker",
            tile: BarLayout.chipsBasketTile,
            size: BarLayout.standardObjectSize,
            rewardCoins: 0,
            interactionRange: 95
        )

        let tray = InteractableConfig(
            id: "tray",
            kind: .tray,
            spriteName: "tray",
            tile: BarLayout.trayTile,
            size: BarLayout.standardObjectSize,
            rewardCoins: 0,
            interactionRange: 95
        )

        let toilet = InteractableConfig(
            id: "toilet",
            kind: .toilet,
            spriteName: "toilet",
            tile: BarLayout.toiletTile,
            size: BarLayout.standardObjectSize,
            rewardCoins: 0,
            interactionRange: 95
        )

        let toiletBowlBrush = InteractableConfig(
            id: "toiletBowlBrush",
            kind: .toiletBowlBrush,
            spriteName: "toilet_bowl_brush",
            tile: BarLayout.toiletBowlBrushTile,
            size: BarLayout.standardObjectSize,
            rewardCoins: 0,
            interactionRange: 95
        )

        let goatChaseSpot = InteractableConfig(
            id: "goatChaseSpot",
            kind: .chaseGoats,
            spriteName: "goat_chase_marker",
            tile: BarLayout.goatChaseTile,
            size: BarLayout.standardObjectSize,
            rewardCoins: 7,
            interactionRange: 130
        )

        let potatoBin = InteractableConfig(
            id: "potatoBin",
            kind: .potatoBin,
            spriteName: "potato_bin",
            tile: BarLayout.potatoBinTile,
            size: BarLayout.potatoBinSize,
            rewardCoins: 0,
            interactionRange: 95
        )

        let bucket = InteractableConfig(
            id: "bucket",
            kind: .bucket,
            spriteName: "bucket_marker",
            tile: BarLayout.bucketStartTile,
            size: BarLayout.standardObjectSize,
            rewardCoins: 0,
            interactionRange: 95
        )

        let spigot = InteractableConfig(
            id: "spigot",
            kind: .spigot,
            spriteName: "spigot_marker",
            tile: BarLayout.spigotTile,
            size: BarLayout.standardObjectSize,
            rewardCoins: 0,
            interactionRange: 95
        )

        let tennisRacket = InteractableConfig(
            id: "tennisRacket",
            kind: .tennisRacket,
            spriteName: "tennis_racket_marker",
            tile: BarLayout.tennisRacketTile,
            size: BarLayout.standardObjectSize,
            rewardCoins: 0,
            interactionRange: 95
        )

        let studyGuide = InteractableConfig(
            id: "studyGuide",
            kind: .studyGuide,
            spriteName: "studyguide",
            tile: BarLayout.studyGuideTile,
            size: BarLayout.studyGuideSize,
            rewardCoins: 0,
            interactionRange: 100
        )

        let searsCatalog = InteractableConfig(
            id: "searsCatalog",
            kind: .searsCatalog,
            spriteName: "searscatalog",
            tile: BarLayout.searsCatalogTile,
            size: BarLayout.studyGuideSize,
            rewardCoins: 0,
            interactionRange: 100
        )

        let teacherDeskEnglish = InteractableConfig(
            id: "teacherDeskEnglish",
            kind: .teachersDesk,
            spriteName: "teachers_desk",
            tile: SchoolLayout.classroomTopLeftDeskTile,
            size: BarLayout.teachersDeskSize,
            rewardCoins: 0,
            interactionRange: 110
        )

        let teacherDeskHistory = InteractableConfig(
            id: "teacherDeskHistory",
            kind: .teachersDesk,
            spriteName: "teachers_desk",
            tile: SchoolLayout.classroomTopRightDeskTile,
            size: BarLayout.teachersDeskSize,
            rewardCoins: 0,
            interactionRange: 110
        )

        let teacherDeskMathematics = InteractableConfig(
            id: "teacherDeskMathematics",
            kind: .teachersDesk,
            spriteName: "teachers_desk",
            tile: SchoolLayout.classroomBottomLeftDeskTile,
            size: BarLayout.teachersDeskSize,
            rewardCoins: 0,
            interactionRange: 110
        )

        let teacherDeskScience = InteractableConfig(
            id: "teacherDeskScience",
            kind: .teachersDesk,
            spriteName: "teachers_desk",
            tile: SchoolLayout.classroomBottomRightDeskTile,
            size: BarLayout.teachersDeskSize,
            rewardCoins: 0,
            interactionRange: 110
        )

        let teachersDesks: [TeachersDeskConfig] = [
            TeachersDeskConfig(interactableID: teacherDeskEnglish.id, subject: .english),
            TeachersDeskConfig(interactableID: teacherDeskHistory.id, subject: .history),
            TeachersDeskConfig(interactableID: teacherDeskMathematics.id, subject: .mathematics),
            TeachersDeskConfig(interactableID: teacherDeskScience.id, subject: .science)
        ]

        let bedroomBat = InteractableConfig(
            id: "bedroomBat",
            kind: .bedroomBat,
            spriteName: "bedroom_bat_marker",
            tile: BarLayout.bedroomBatTile,
            size: BarLayout.standardObjectSize,
            rewardCoins: 0,
            interactionRange: 95
        )

        let shovel = InteractableConfig(
            id: "shovel",
            kind: .shovel,
            spriteName: "shovel_marker",
            tile: BarLayout.shovelTile,
            size: BarLayout.standardObjectSize,
            rewardCoins: 0,
            interactionRange: 95
        )

        let snowmobiles: [InteractableConfig] = BarLayout.snowmobileTiles.enumerated().map { index, tile in
            InteractableConfig(
                id: "snowmobile\(index + 1)",
                kind: .snowmobile,
                spriteName: "snowmobile\(index + 1)",
                tile: tile,
                size: BarLayout.snowmobileSize,
                rewardCoins: 0,
                interactionRange: 125
            )
        }

        let carrollSign = DecorationConfig(
            id: "carrollSnowmobileSign",
            kind: .largeTextSign,
            spriteName: "carroll_snowmobile_sales_sign",
            labelText: "Carroll's Snowmobile Sales",
            tile: BarLayout.carrollSignTile,
            size: BarLayout.largeSignSize,
            blocksMovement: false
        )

        let cramerSign = DecorationConfig(
            id: "cramersLittleValleySign",
            kind: .largeTextSign,
            spriteName: "cramers_little_valley_sign",
            labelText: "Cramer's Little Valley",
            tile: BarLayout.cramerSignTile,
            size: BarLayout.largeSignSize,
            blocksMovement: false
        )

        let schoolSign = DecorationConfig(
            id: "suringHighSchoolSign",
            kind: .largeTextSign,
            spriteName: "suring_high_school_sign",
            labelText: "Suring High School",
            tile: SchoolLayout.schoolSignTile,
            size: BarLayout.largeSignSize,
            blocksMovement: false
        )

        let bedroomBeds: [DecorationConfig] = BarLayout.bedTiles.enumerated().map { index, tile in
            DecorationConfig(
                id: "bedroomBed\(index + 1)",
                kind: .sprite,
                spriteName: "bed\(index + 1)",
                labelText: nil,
                tile: tile,
                size: BarLayout.bedSize,
                blocksMovement: true
            )
        }

        let livingRoomBar = DecorationConfig(
            id: "livingRoomBar",
            kind: .sprite,
            spriteName: "bar",
            labelText: nil,
            tile: BarLayout.livingRoomBarTile,
            size: BarLayout.livingRoomBarSize,
            blocksMovement: true
        )

        let studyDesk = DecorationConfig(
            id: "studyDesk",
            kind: .sprite,
            spriteName: "desk",
            labelText: nil,
            tile: BarLayout.deskTile,
            size: BarLayout.deskSize,
            blocksMovement: true
        )

        let topBarStool = DecorationConfig(
            id: "topBarStool",
            kind: .sprite,
            spriteName: "barstool",
            labelText: nil,
            tile: BarLayout.topBarStoolTile,
            size: BarLayout.stoolTileSize,
            blocksMovement: true
        )

        let centerBarStool = DecorationConfig(
            id: "centerBarStool",
            kind: .sprite,
            spriteName: "barstool",
            labelText: nil,
            tile: BarLayout.centerBarStoolTile,
            size: BarLayout.stoolTileSize,
            blocksMovement: true
        )

        let patronBarStool = DecorationConfig(
            id: "patronBarStool",
            kind: .sprite,
            spriteName: "barstoolwithpatron1",
            labelText: nil,
            tile: BarLayout.patronBarStoolTile,
            size: BarLayout.patronStoolTileSize,
            blocksMovement: true
        )

        let parkingCars: [DecorationConfig] = [
            DecorationConfig(
                id: "parkingCarSedan",
                kind: .sprite,
                spriteName: "sedan",
                labelText: nil,
                tile: BarLayout.parkingCarTiles[0],
                size: BarLayout.parkingCarSize,
                blocksMovement: true
            ),
            DecorationConfig(
                id: "parkingCarPickupTruck",
                kind: .sprite,
                spriteName: "pickuptruck",
                labelText: nil,
                tile: BarLayout.parkingCarTiles[1],
                size: BarLayout.parkingCarSize,
                blocksMovement: true
            ),
            DecorationConfig(
                id: "parkingCarStationWagon",
                kind: .sprite,
                spriteName: "stationwagon",
                labelText: nil,
                tile: BarLayout.parkingCarTiles[2],
                size: BarLayout.parkingCarSize,
                blocksMovement: true
            )
        ]

        let allInteractables = [potatoPeeler, deepFryer, tray, chipsBasket, toilet, toiletBowlBrush, potatoBin, bucket, spigot, tennisRacket, studyGuide, searsCatalog, teacherDeskEnglish, teacherDeskHistory, teacherDeskMathematics, teacherDeskScience, bedroomBat, shovel, goatChaseSpot] + snowmobiles

        let staticDecorations = [
            carrollSign,
            cramerSign,
            schoolSign,
            livingRoomBar,
            studyDesk,
            topBarStool,
            centerBarStool,
            patronBarStool
        ] + bedroomBeds + parkingCars
        let treeDecorations = makeTreeDecorations(
            wallTiles: wallTiles,
            blockedTiles: Set(allInteractables.map { $0.tile }).union(Set(staticDecorations.map { $0.tile }))
        )

        return WorldConfig(
            wallTiles: wallTiles,
            defaultFloorTileName: "floor_outdoor",
            floorRegions: floorRegions,
            riverOverlay: riverOverlay,
            doorwayFloorOverrides: doorwayFloorOverrides,
            barInteriorRegions: barInteriorRegions,
            carrollSalesRegion: BarLayout.carrollSalesRegion,
            septicDigTiles: BarLayout.septicDigTiles,
            roomLabels: roomLabels,
            spawnTile: BarLayout.spawnTile,
            decorations: staticDecorations + treeDecorations,
            interactables: allInteractables,
            teachersDesks: teachersDesks
        )
    }

    private static func makeTreeDecorations(wallTiles: Set<TileCoordinate>, blockedTiles: Set<TileCoordinate>) -> [DecorationConfig] {
        let minTreeColumn = BarLayout.maxColumnExclusive + 2
        let maxTreeColumn = SchoolLayout.minColumn - 2
        guard minTreeColumn <= maxTreeColumn else { return [] }

        let corridorCenterRow = SchoolLayout.hallMinRow + 1
        let corridorMinRow = max(0, corridorCenterRow - 2)
        let corridorMaxRow = min(45, corridorMinRow + 4)

        var septicTiles: Set<TileCoordinate> = []
        for column in BarLayout.leftSepticRegion.minColumn..<BarLayout.leftSepticRegion.maxColumnExclusive {
            for row in BarLayout.leftSepticRegion.minRow..<BarLayout.leftSepticRegion.maxRowExclusive {
                septicTiles.insert(TileCoordinate(column: column, row: row))
            }
        }
        for column in BarLayout.rightSepticRegion.minColumn..<BarLayout.rightSepticRegion.maxColumnExclusive {
            for row in BarLayout.rightSepticRegion.minRow..<BarLayout.rightSepticRegion.maxRowExclusive {
                septicTiles.insert(TileCoordinate(column: column, row: row))
            }
        }
        septicTiles.formUnion(BarLayout.septicDigTiles)

        let minTreeRow = max(2, min(BarLayout.minRow, SchoolLayout.minRow) - 6)
        let topOccupiedRow = max(BarLayout.maxRowExclusive, SchoolLayout.maxRowExclusive) - 1
        let maxTreeRow = min(44, topOccupiedRow)
        guard minTreeRow <= maxTreeRow else { return [] }

        let treeSpriteNames = ["fir", "maple", "birch"]
        let treeSizes = BarLayout.treeSizes

        var rng = SeededGenerator(seed: 20260223)
        var placedTiles = Set<TileCoordinate>()
        var treeDecorations: [DecorationConfig] = []

        for column in stride(from: minTreeColumn, through: maxTreeColumn, by: 3) {
            for row in stride(from: minTreeRow, through: maxTreeRow, by: 3) {
                if row >= corridorMinRow && row <= corridorMaxRow {
                    continue
                }

                let tile = TileCoordinate(column: column, row: row)
                let isRiverTile = tile.column >= BarLayout.riverMinColumn
                    && tile.column < BarLayout.riverMaxColumnExclusive
                    && tile.row >= BarLayout.riverBottomRow
                    && tile.row <= BarLayout.riverTopRow
                if isRiverTile {
                    continue
                }
                if wallTiles.contains(tile) || blockedTiles.contains(tile) {
                    continue
                }

                let isNearSepticSystem = septicTiles.contains { septicTile in
                    abs(septicTile.column - tile.column) <= 3 && abs(septicTile.row - tile.row) <= 3
                }
                if isNearSepticSystem {
                    continue
                }

                let shouldPlaceTree = Int.random(in: 0..<100, using: &rng) < 20
                if !shouldPlaceTree {
                    continue
                }

                let tooClose = placedTiles.contains { placed in
                    abs(placed.column - tile.column) <= 2 && abs(placed.row - tile.row) <= 2
                }
                if tooClose {
                    continue
                }

                let spriteName = treeSpriteNames[Int.random(in: 0..<treeSpriteNames.count, using: &rng)]
                let size = treeSizes[Int.random(in: 0..<treeSizes.count, using: &rng)]
                treeDecorations.append(
                    DecorationConfig(
                        id: "tree_\(column)_\(row)",
                        kind: .sprite,
                        spriteName: spriteName,
                        labelText: nil,
                        tile: tile,
                        size: size,
                        blocksMovement: true
                    )
                )
                placedTiles.insert(tile)
            }
        }

        return treeDecorations
    }
}
