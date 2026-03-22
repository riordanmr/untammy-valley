//
//  MessageLog.swift
//  UntammyValley
//
//  Central store for messages shown to the user via showMessage().
//  Keeps at most UTSettings.shared.counts.logMessageMaxCount entries;
//  oldest entries are dropped when the limit is exceeded.
//

import Foundation

final class MessageLog {
    static let shared = MessageLog()

    // Stored oldest-first; exposed newest-first via `messages`.
    private var _messages: [String] = []

    /// All recorded messages, newest first.
    var messages: [String] { Array(_messages.reversed()) }

    private init() {}

    /// Record a message.  Empty/whitespace-only strings are ignored.
    func append(_ message: String) {
        let trimmed = message.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        _messages.append(trimmed)
        let maxCount = UTSettings.shared.counts.logMessageMaxCount
        if _messages.count > maxCount {
            _messages.removeFirst(_messages.count - maxCount)
        }
    }
}
