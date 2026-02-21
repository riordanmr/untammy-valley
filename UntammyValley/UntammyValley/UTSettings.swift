//
//  UTSettings.swift
//  UntammyValley
//

import Foundation

final class UTSettings {
    static let shared = UTSettings()

    struct Counts: Codable {
        var batSpawnMinMoves: Int = 50
        var batSpawnMaxMoves: Int = 120
        var batDefeatDeadlineMoves: Int = 22

        var goatRespawnMinMoves: Int = 30
        var goatRespawnMaxMoves: Int = 45

        var snowmobilePriceCoins: Int = 100

        var potatoChipRewardPerPotato: Int = 5
        var goatChaseRewardCoins: Int = 7
        var toiletDirtyIntervalMoves: Int = 100
        var toiletCleanDeadlineMoves: Int = 20
        var toiletCleanRewardCoins: Int = 10
        var toiletOverduePenaltyCoinsPerMove: Int = 1
        var septicTrenchTileRewardCoins: Int = 1
        var septicCompletionBonusCoins: Int = 100

        var batEscapePenaltyMaxCoins: Int = 200

        mutating func normalize() {
            batSpawnMinMoves = max(1, batSpawnMinMoves)
            batSpawnMaxMoves = max(batSpawnMinMoves, batSpawnMaxMoves)
            batDefeatDeadlineMoves = max(1, batDefeatDeadlineMoves)

            goatRespawnMinMoves = max(1, goatRespawnMinMoves)
            goatRespawnMaxMoves = max(goatRespawnMinMoves, goatRespawnMaxMoves)

            snowmobilePriceCoins = max(0, snowmobilePriceCoins)

            toiletDirtyIntervalMoves = max(1, toiletDirtyIntervalMoves)
            toiletCleanDeadlineMoves = max(1, toiletCleanDeadlineMoves)

            potatoChipRewardPerPotato = max(0, potatoChipRewardPerPotato)
            goatChaseRewardCoins = max(0, goatChaseRewardCoins)
            toiletCleanRewardCoins = max(0, toiletCleanRewardCoins)
            toiletOverduePenaltyCoinsPerMove = max(0, toiletOverduePenaltyCoinsPerMove)
            septicTrenchTileRewardCoins = max(0, septicTrenchTileRewardCoins)
            septicCompletionBonusCoins = max(0, septicCompletionBonusCoins)

            batEscapePenaltyMaxCoins = max(0, batEscapePenaltyMaxCoins)
        }
    }

    enum CountField: String, CaseIterable {
        case batSpawnMinMoves
        case batSpawnMaxMoves
        case batDefeatDeadlineMoves
        case batEscapePenaltyMaxCoins

        case goatRespawnMinMoves
        case goatRespawnMaxMoves
        case goatChaseRewardCoins

        case snowmobilePriceCoins

        case potatoChipRewardPerPotato

        case toiletDirtyIntervalMoves
        case toiletCleanDeadlineMoves
        case toiletCleanRewardCoins
        case toiletOverduePenaltyCoinsPerMove

        case septicTrenchTileRewardCoins
        case septicCompletionBonusCoins

        var title: String {
            switch self {
            case .batSpawnMinMoves: return "Bat spawn min moves"
            case .batSpawnMaxMoves: return "Bat spawn max moves"
            case .batDefeatDeadlineMoves: return "Bat escape moves"
            case .goatRespawnMinMoves: return "Goat return min moves"
            case .goatRespawnMaxMoves: return "Goat return max moves"
            case .snowmobilePriceCoins: return "Snowmobile cost"
            case .potatoChipRewardPerPotato: return "Chip reward per potato"
            case .toiletDirtyIntervalMoves: return "Toilet dirty interval"
            case .toiletCleanDeadlineMoves: return "Toilet clean deadline"
            case .goatChaseRewardCoins: return "Goat chase reward"
            case .toiletCleanRewardCoins: return "Toilet clean reward"
            case .toiletOverduePenaltyCoinsPerMove: return "Toilet overdue penalty"
            case .septicTrenchTileRewardCoins: return "Septic trench tile reward"
            case .septicCompletionBonusCoins: return "Septic completion bonus"
            case .batEscapePenaltyMaxCoins: return "Bat escape max penalty"
            }
        }

        var minimumValue: Int {
            switch self {
              case .batSpawnMinMoves, .batSpawnMaxMoves, .batDefeatDeadlineMoves,
                  .goatRespawnMinMoves, .goatRespawnMaxMoves,
                  .toiletDirtyIntervalMoves, .toiletCleanDeadlineMoves:
                return 1
            default:
                return 0
            }
        }

        var maximumValue: Int {
            switch self {
            case .batSpawnMinMoves, .batSpawnMaxMoves, .goatRespawnMinMoves, .goatRespawnMaxMoves,
                 .toiletDirtyIntervalMoves:
                return 999
            case .batDefeatDeadlineMoves, .toiletCleanDeadlineMoves:
                return 200
            default:
                return 9999
            }
        }

        func value(from counts: Counts) -> Int {
            switch self {
            case .batSpawnMinMoves: return counts.batSpawnMinMoves
            case .batSpawnMaxMoves: return counts.batSpawnMaxMoves
            case .batDefeatDeadlineMoves: return counts.batDefeatDeadlineMoves
            case .goatRespawnMinMoves: return counts.goatRespawnMinMoves
            case .goatRespawnMaxMoves: return counts.goatRespawnMaxMoves
            case .snowmobilePriceCoins: return counts.snowmobilePriceCoins
            case .potatoChipRewardPerPotato: return counts.potatoChipRewardPerPotato
            case .toiletDirtyIntervalMoves: return counts.toiletDirtyIntervalMoves
            case .toiletCleanDeadlineMoves: return counts.toiletCleanDeadlineMoves
            case .goatChaseRewardCoins: return counts.goatChaseRewardCoins
            case .toiletCleanRewardCoins: return counts.toiletCleanRewardCoins
            case .toiletOverduePenaltyCoinsPerMove: return counts.toiletOverduePenaltyCoinsPerMove
            case .septicTrenchTileRewardCoins: return counts.septicTrenchTileRewardCoins
            case .septicCompletionBonusCoins: return counts.septicCompletionBonusCoins
            case .batEscapePenaltyMaxCoins: return counts.batEscapePenaltyMaxCoins
            }
        }

        func setValue(_ value: Int, in counts: inout Counts) {
            let clamped = min(max(value, minimumValue), maximumValue)
            switch self {
            case .batSpawnMinMoves: counts.batSpawnMinMoves = clamped
            case .batSpawnMaxMoves: counts.batSpawnMaxMoves = clamped
            case .batDefeatDeadlineMoves: counts.batDefeatDeadlineMoves = clamped
            case .goatRespawnMinMoves: counts.goatRespawnMinMoves = clamped
            case .goatRespawnMaxMoves: counts.goatRespawnMaxMoves = clamped
            case .snowmobilePriceCoins: counts.snowmobilePriceCoins = clamped
            case .potatoChipRewardPerPotato: counts.potatoChipRewardPerPotato = clamped
            case .toiletDirtyIntervalMoves: counts.toiletDirtyIntervalMoves = clamped
            case .toiletCleanDeadlineMoves: counts.toiletCleanDeadlineMoves = clamped
            case .goatChaseRewardCoins: counts.goatChaseRewardCoins = clamped
            case .toiletCleanRewardCoins: counts.toiletCleanRewardCoins = clamped
            case .toiletOverduePenaltyCoinsPerMove: counts.toiletOverduePenaltyCoinsPerMove = clamped
            case .septicTrenchTileRewardCoins: counts.septicTrenchTileRewardCoins = clamped
            case .septicCompletionBonusCoins: counts.septicCompletionBonusCoins = clamped
            case .batEscapePenaltyMaxCoins: counts.batEscapePenaltyMaxCoins = clamped
            }
        }
    }

    private static let countsStorageKey = "ut.settings.counts"

    private(set) var counts: Counts {
        didSet {
            saveCounts()
        }
    }

    private init() {
        if let data = UserDefaults.standard.data(forKey: Self.countsStorageKey),
           let decoded = try? JSONDecoder().decode(Counts.self, from: data) {
            var normalized = decoded
            normalized.normalize()
            counts = normalized
        } else {
            counts = Counts()
        }
    }

    func value(for field: CountField) -> Int {
        field.value(from: counts)
    }

    @discardableResult
    func setValue(_ value: Int, for field: CountField) -> Int {
        var updated = counts
        field.setValue(value, in: &updated)
        updated.normalize()
        counts = updated
        return field.value(from: updated)
    }

    @discardableResult
    func adjustValue(for field: CountField, delta: Int) -> Int {
        let current = field.value(from: counts)
        return setValue(current + delta, for: field)
    }

    func resetCountsToDefaults() {
        var defaults = Counts()
        defaults.normalize()
        counts = defaults
    }

    private func saveCounts() {
        guard let data = try? JSONEncoder().encode(counts) else { return }
        UserDefaults.standard.set(data, forKey: Self.countsStorageKey)
    }
}
