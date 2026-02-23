//
//  SchoolLayout.swift
//  UntammyValley
//

import Foundation

enum SchoolLayout {
    static let classroomWidth = 8
    static let classroomHeight = 10
    static let hallHeight = 5
    static let gymWidth = 16

    private static var configuredBarWidth = 0
    private static var configuredBarRightWallColumn = 0
    private static var configuredMinRow = 0

    static func configure(barWidth: Int, barRightWallColumn: Int, minRow: Int) {
        configuredBarWidth = barWidth
        configuredBarRightWallColumn = barRightWallColumn
        configuredMinRow = minRow
    }

    static var distanceFromBarColumns: Int { configuredBarWidth * 4 }

    static var minColumn: Int { configuredBarRightWallColumn + distanceFromBarColumns }
    static var minRow: Int { configuredMinRow }

    static var classroomBlockWidth: Int { classroomWidth * 2 }
    static var gymDividerColumn: Int { minColumn + classroomBlockWidth }
    static var maxColumnExclusive: Int { gymDividerColumn + gymWidth }

    static var hallMinRow: Int { minRow + classroomHeight }
    static var hallMaxRowExclusive: Int { hallMinRow + hallHeight }
    static var maxRowExclusive: Int { minRow + (classroomHeight * 2) + hallHeight }

    static var topClassroomDividerRow: Int { hallMaxRowExclusive - 1 }
    static var bottomClassroomDividerRow: Int { hallMinRow }
    static var classroomVerticalDividerColumn: Int { minColumn + classroomWidth }

    static var leftExteriorDoorRows: Set<Int> {
        Set((hallMinRow + 1)..<(hallMinRow + 3))
    }

    static var classroomDoorColumns: Set<Int> {
        Set([
            minColumn + 3, minColumn + 4,
            minColumn + classroomWidth + 3, minColumn + classroomWidth + 4
        ])
    }

    static var hallToGymTransitionMinRow: Int {
        hallMinRow
    }

    static var hallToGymTransitionMaxRowExclusive: Int {
        hallMaxRowExclusive
    }

    static var hallToGymDoorRows: Set<Int> {
        Set((hallToGymTransitionMinRow + 1)..<(hallToGymTransitionMaxRowExclusive - 1))
    }

    static var schoolSignTile: TileCoordinate {
        TileCoordinate(column: minColumn + 6, row: minRow - 3)
    }

    static var hallLabelTile: TileCoordinate {
        TileCoordinate(column: minColumn + (classroomBlockWidth / 2), row: hallMinRow + (hallHeight / 2))
    }

    static var classroomTopLeftLabelTile: TileCoordinate {
        TileCoordinate(column: minColumn + (classroomWidth / 2), row: hallMaxRowExclusive + (classroomHeight / 2))
    }

    static var classroomTopRightLabelTile: TileCoordinate {
        TileCoordinate(column: minColumn + classroomWidth + (classroomWidth / 2), row: hallMaxRowExclusive + (classroomHeight / 2))
    }

    static var classroomBottomLeftLabelTile: TileCoordinate {
        TileCoordinate(column: minColumn + (classroomWidth / 2), row: minRow + (classroomHeight / 2))
    }

    static var classroomBottomRightLabelTile: TileCoordinate {
        TileCoordinate(column: minColumn + classroomWidth + (classroomWidth / 2), row: minRow + (classroomHeight / 2))
    }

    static var gymLabelTile: TileCoordinate {
        TileCoordinate(column: gymDividerColumn + (gymWidth / 2), row: minRow + ((maxRowExclusive - minRow) / 2))
    }

    static var classroomTopLeftDeskTile: TileCoordinate {
        TileCoordinate(column: classroomVerticalDividerColumn - 2, row: classroomTopLeftLabelTile.row)
    }

    static var classroomTopRightDeskTile: TileCoordinate {
        TileCoordinate(column: gymDividerColumn - 2, row: classroomTopRightLabelTile.row)
    }

    static var classroomBottomLeftDeskTile: TileCoordinate {
        TileCoordinate(column: classroomVerticalDividerColumn - 2, row: classroomBottomLeftLabelTile.row)
    }

    static var classroomBottomRightDeskTile: TileCoordinate {
        TileCoordinate(column: gymDividerColumn - 2, row: classroomBottomRightLabelTile.row)
    }
}
