//
//  NamedGameSave.swift
//  UntammyValley
//

import Foundation

struct NamedGameSaveSummary: Codable, Equatable {
    let id: String
    let name: String
    let createdAt: Date
    let savedAt: Date
}

struct NamedGameSaveSlot: Codable {
    let id: String
    let name: String
    let createdAt: Date
    let savedAt: Date
    let snapshot: GameSaveSnapshot

    var summary: NamedGameSaveSummary {
        NamedGameSaveSummary(
            id: id,
            name: name,
            createdAt: createdAt,
            savedAt: savedAt
        )
    }
}

struct NamedGameSaveStore: Codable {
    let schemaVersion: Int
    var saves: [NamedGameSaveSlot]
}

enum NamedGameSaveError: LocalizedError {
    case invalidName
    case storageUnavailable
    case saveNotFound

    var errorDescription: String? {
        switch self {
        case .invalidName:
            return "Save name cannot be empty."
        case .storageUnavailable:
            return "Named save storage is unavailable."
        case .saveNotFound:
            return "The selected save could not be found."
        }
    }
}