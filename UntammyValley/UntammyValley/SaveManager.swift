//
//  SaveManager.swift
//  UntammyValley
//

import Foundation

final class SaveManager {
    static let shared = SaveManager()

    private let fileName = "game-save-v1.json"

    private init() {}

    private var saveFileURL: URL? {
        let fileManager = FileManager.default
        guard let baseURL = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
            return nil
        }

        let appSupportURL = baseURL.appendingPathComponent("UntammyValley", isDirectory: true)
        do {
            try fileManager.createDirectory(at: appSupportURL, withIntermediateDirectories: true)
            return appSupportURL.appendingPathComponent(fileName)
        } catch {
            print("[SaveManager] Failed to create app support directory: \(error)")
            return nil
        }
    }

    @discardableResult
    func saveSnapshot(_ snapshot: GameSaveSnapshot) -> Bool {
        guard let url = saveFileURL else { return false }

        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted]
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(snapshot)
            try data.write(to: url, options: .atomic)
            return true
        } catch {
            print("[SaveManager] Failed saving snapshot: \(error)")
            return false
        }
    }

    func loadSnapshot() -> GameSaveSnapshot? {
        guard let url = saveFileURL else { return nil }
        guard FileManager.default.fileExists(atPath: url.path) else { return nil }

        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            return try decoder.decode(GameSaveSnapshot.self, from: data)
        } catch {
            print("[SaveManager] Failed loading snapshot: \(error)")
            return nil
        }
    }
}
