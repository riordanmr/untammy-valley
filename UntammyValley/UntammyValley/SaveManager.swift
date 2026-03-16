//
//  SaveManager.swift
//  UntammyValley
//

import Foundation

final class SaveManager {
    static let shared = SaveManager()

    private let autosaveFileName = "game-save-v1.json"
    private let namedSavesFileName = "named-game-saves-v1.json"
    private let namedSavesSchemaVersion = 1

    private init() {}

    private var appSupportDirectoryURL: URL? {
        let fileManager = FileManager.default
        guard let baseURL = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
            return nil
        }

        let appSupportURL = baseURL.appendingPathComponent("UntammyValley", isDirectory: true)
        do {
            try fileManager.createDirectory(at: appSupportURL, withIntermediateDirectories: true)
            return appSupportURL
        } catch {
            print("[SaveManager] Failed to create app support directory: \(error)")
            return nil
        }
    }

    private var autosaveFileURL: URL? {
        appSupportDirectoryURL?.appendingPathComponent(autosaveFileName)
    }

    private var namedSavesFileURL: URL? {
        appSupportDirectoryURL?.appendingPathComponent(namedSavesFileName)
    }

    private func makeEncoder() -> JSONEncoder {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted]
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }

    private func makeDecoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }

    private func normalizedSaveName(_ rawName: String) -> String {
        rawName.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func saveNameMatches(_ lhs: String, _ rhs: String) -> Bool {
        normalizedSaveName(lhs).caseInsensitiveCompare(normalizedSaveName(rhs)) == .orderedSame
    }

    private func sortedNamedSaves(_ saves: [NamedGameSaveSlot]) -> [NamedGameSaveSlot] {
        saves.sorted { lhs, rhs in
            if lhs.savedAt != rhs.savedAt {
                return lhs.savedAt > rhs.savedAt
            }
            if lhs.createdAt != rhs.createdAt {
                return lhs.createdAt > rhs.createdAt
            }
            let nameComparison = lhs.name.localizedCaseInsensitiveCompare(rhs.name)
            if nameComparison != .orderedSame {
                return nameComparison == .orderedAscending
            }
            return lhs.id < rhs.id
        }
    }

    private func readNamedSaveStore() throws -> NamedGameSaveStore {
        guard let url = namedSavesFileURL else {
            throw NamedGameSaveError.storageUnavailable
        }
        guard FileManager.default.fileExists(atPath: url.path) else {
            return NamedGameSaveStore(schemaVersion: namedSavesSchemaVersion, saves: [])
        }

        let data = try Data(contentsOf: url)
        var store = try makeDecoder().decode(NamedGameSaveStore.self, from: data)
        store.saves = sortedNamedSaves(store.saves)
        return store
    }

    private func writeNamedSaveStore(_ store: NamedGameSaveStore) throws {
        guard let url = namedSavesFileURL else {
            throw NamedGameSaveError.storageUnavailable
        }

        let normalizedStore = NamedGameSaveStore(
            schemaVersion: namedSavesSchemaVersion,
            saves: sortedNamedSaves(store.saves)
        )
        let data = try makeEncoder().encode(normalizedStore)
        try data.write(to: url, options: .atomic)
    }

    @discardableResult
    func saveSnapshot(_ snapshot: GameSaveSnapshot) -> Bool {
        guard let url = autosaveFileURL else { return false }

        do {
            let data = try makeEncoder().encode(snapshot)
            try data.write(to: url, options: .atomic)
            return true
        } catch {
            print("[SaveManager] Failed saving snapshot: \(error)")
            return false
        }
    }

    func loadSnapshot() -> GameSaveSnapshot? {
        guard let url = autosaveFileURL else { return nil }
        guard FileManager.default.fileExists(atPath: url.path) else { return nil }

        do {
            let data = try Data(contentsOf: url)
            return try makeDecoder().decode(GameSaveSnapshot.self, from: data)
        } catch {
            print("[SaveManager] Failed loading snapshot: \(error)")
            return nil
        }
    }

    func listNamedSaves() -> [NamedGameSaveSummary] {
        do {
            return try readNamedSaveStore().saves.map(\.summary)
        } catch {
            print("[SaveManager] Failed listing named saves: \(error)")
            return []
        }
    }

    @discardableResult
    func saveNamedSnapshot(_ snapshot: GameSaveSnapshot, named rawName: String) throws -> NamedGameSaveSummary {
        let saveName = normalizedSaveName(rawName)
        guard !saveName.isEmpty else {
            throw NamedGameSaveError.invalidName
        }

        var store = try readNamedSaveStore()
        let now = Date()

        if let existingIndex = store.saves.firstIndex(where: { saveNameMatches($0.name, saveName) }) {
            let existingSlot = store.saves[existingIndex]
            store.saves[existingIndex] = NamedGameSaveSlot(
                id: existingSlot.id,
                name: saveName,
                createdAt: existingSlot.createdAt,
                savedAt: now,
                snapshot: snapshot
            )
        } else {
            store.saves.append(
                NamedGameSaveSlot(
                    id: UUID().uuidString,
                    name: saveName,
                    createdAt: now,
                    savedAt: now,
                    snapshot: snapshot
                )
            )
        }

        try writeNamedSaveStore(store)

        guard let savedSlot = sortedNamedSaves(store.saves).first(where: { saveNameMatches($0.name, saveName) }) else {
            throw NamedGameSaveError.saveNotFound
        }

        return savedSlot.summary
    }

    func loadNamedSnapshot(id: String) throws -> GameSaveSnapshot {
        let store = try readNamedSaveStore()
        guard let slot = store.saves.first(where: { $0.id == id }) else {
            throw NamedGameSaveError.saveNotFound
        }
        return slot.snapshot
    }

    func loadNamedSnapshot(named rawName: String) throws -> GameSaveSnapshot {
        let saveName = normalizedSaveName(rawName)
        let store = try readNamedSaveStore()
        guard let slot = store.saves.first(where: { saveNameMatches($0.name, saveName) }) else {
            throw NamedGameSaveError.saveNotFound
        }
        return slot.snapshot
    }

    func deleteNamedSnapshot(id: String) throws {
        var store = try readNamedSaveStore()
        let originalCount = store.saves.count
        store.saves.removeAll { $0.id == id }
        guard store.saves.count != originalCount else {
            throw NamedGameSaveError.saveNotFound
        }
        try writeNamedSaveStore(store)
    }

    func deleteNamedSnapshot(named rawName: String) throws {
        let saveName = normalizedSaveName(rawName)
        var store = try readNamedSaveStore()
        let originalCount = store.saves.count
        store.saves.removeAll { saveNameMatches($0.name, saveName) }
        guard store.saves.count != originalCount else {
            throw NamedGameSaveError.saveNotFound
        }
        try writeNamedSaveStore(store)
    }
}
