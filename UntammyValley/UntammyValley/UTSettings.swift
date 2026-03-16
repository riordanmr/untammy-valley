//
//  UTSettings.swift
//  UntammyValley
//

import Foundation

final class UTSettings {
    static let shared = UTSettings()

    enum Avatar: String, CaseIterable {
        case tam
        case jc
        case casey
        case mark

        var assetName: String { rawValue }

        var title: String {
            switch self {
            case .tam: return "Tam"
            case .jc: return "JC"
            case .casey: return "Casey"
            case .mark: return "Mark"
            }
        }
    }

    struct Counts: Codable {
        var bearProximityColumns: Int = 6
        var bearProximityRows: Int = 5

        var batSpawnMinMoves: Int = 80
        var batSpawnMaxMoves: Int = 120
        var batDefeatDeadlineMoves: Int = 30

        var goatRespawnMinMoves: Int = 30
        var goatRespawnMaxMoves: Int = 45

        var raftDeliveryMinMoves: Int = 40
        var raftDeliveryMaxMoves: Int = 60

        var snowmobilePriceCoins: Int = 100

        var potatoChipRewardPerPotato: Int = 5
        var foodOrderMinMoves: Int = 100
        var foodOrderMaxMoves: Int = 150
        var foodOrderDeliverDeadlineMoves: Int = 120
        var foodOrderNonDeliveryPenaltyCoins: Int = 30
        var goatChaseRewardCoins: Int = 7
        var toiletDirtyIntervalMoves: Int = 100
        var toiletCleanDeadlineMoves: Int = 30
        var toiletCleanRewardCoins: Int = 10
        var toiletOverduePenaltyCoinsPerMove: Int = 1
        var septicTrenchTileRewardCoins: Int = 1
        var septicCompletionBonusCoins: Int = 100

        var batEscapePenaltyMaxCoins: Int = 200

        mutating func normalize() {
            bearProximityColumns = max(1, bearProximityColumns)
            bearProximityRows = max(1, bearProximityRows)

            batSpawnMinMoves = max(1, batSpawnMinMoves)
            batSpawnMaxMoves = max(batSpawnMinMoves, batSpawnMaxMoves)
            batDefeatDeadlineMoves = max(1, batDefeatDeadlineMoves)

            goatRespawnMinMoves = max(1, goatRespawnMinMoves)
            goatRespawnMaxMoves = max(goatRespawnMinMoves, goatRespawnMaxMoves)

            raftDeliveryMinMoves = max(1, raftDeliveryMinMoves)
            raftDeliveryMaxMoves = max(raftDeliveryMinMoves, raftDeliveryMaxMoves)

            snowmobilePriceCoins = max(0, snowmobilePriceCoins)

            foodOrderMinMoves = max(1, foodOrderMinMoves)
            foodOrderMaxMoves = max(foodOrderMinMoves, foodOrderMaxMoves)
            foodOrderDeliverDeadlineMoves = max(1, foodOrderDeliverDeadlineMoves)
            foodOrderNonDeliveryPenaltyCoins = max(0, foodOrderNonDeliveryPenaltyCoins)

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
        case bearProximityColumns
        case bearProximityRows

        case batSpawnMinMoves
        case batSpawnMaxMoves
        case batDefeatDeadlineMoves
        case batEscapePenaltyMaxCoins

        case goatRespawnMinMoves
        case goatRespawnMaxMoves
        case raftDeliveryMinMoves
        case raftDeliveryMaxMoves
        case goatChaseRewardCoins

        case snowmobilePriceCoins

        case potatoChipRewardPerPotato
        case foodOrderMinMoves
        case foodOrderMaxMoves
        case foodOrderDeliverDeadlineMoves
        case foodOrderNonDeliveryPenaltyCoins

        case toiletDirtyIntervalMoves
        case toiletCleanDeadlineMoves
        case toiletCleanRewardCoins
        case toiletOverduePenaltyCoinsPerMove

        case septicTrenchTileRewardCoins
        case septicCompletionBonusCoins

        var title: String {
            switch self {
            case .bearProximityColumns: return "Bear proximity columns"
            case .bearProximityRows: return "Bear proximity rows"
            case .batSpawnMinMoves: return "Bat spawn min moves"
            case .batSpawnMaxMoves: return "Bat spawn max moves"
            case .batDefeatDeadlineMoves: return "Bat escape moves"
            case .goatRespawnMinMoves: return "Goat return min moves"
            case .goatRespawnMaxMoves: return "Goat return max moves"
            case .raftDeliveryMinMoves: return "Raft delivery min moves"
            case .raftDeliveryMaxMoves: return "Raft delivery max moves"
            case .snowmobilePriceCoins: return "Snowmobile cost"
            case .potatoChipRewardPerPotato: return "Chip reward per potato"
            case .foodOrderMinMoves: return "Food order min moves"
            case .foodOrderMaxMoves: return "Food order max moves"
            case .foodOrderDeliverDeadlineMoves: return "Food order delivery deadline"
            case .foodOrderNonDeliveryPenaltyCoins: return "Food order non-delivery penalty"
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
                case .bearProximityColumns, .bearProximityRows,
                    .batSpawnMinMoves, .batSpawnMaxMoves, .batDefeatDeadlineMoves,
                    .goatRespawnMinMoves, .goatRespawnMaxMoves,
                    .raftDeliveryMinMoves, .raftDeliveryMaxMoves,
                        .toiletDirtyIntervalMoves, .toiletCleanDeadlineMoves,
                        .foodOrderMinMoves, .foodOrderMaxMoves, .foodOrderDeliverDeadlineMoves:
                return 1
            default:    
                return 0
            }
        }

        var maximumValue: Int {
            switch self {
            case .bearProximityColumns, .bearProximityRows:
                return 100
              case .batSpawnMinMoves, .batSpawnMaxMoves, .goatRespawnMinMoves, .goatRespawnMaxMoves,
                  .raftDeliveryMinMoves, .raftDeliveryMaxMoves,
                 .toiletDirtyIntervalMoves,
                 .foodOrderMinMoves, .foodOrderMaxMoves:
                return 999
            case .batDefeatDeadlineMoves, .toiletCleanDeadlineMoves, .foodOrderDeliverDeadlineMoves:
                return 200
            default:
                return 9999
            }
        }

        func value(from counts: Counts) -> Int {
            switch self {
            case .bearProximityColumns: return counts.bearProximityColumns
            case .bearProximityRows: return counts.bearProximityRows
            case .batSpawnMinMoves: return counts.batSpawnMinMoves
            case .batSpawnMaxMoves: return counts.batSpawnMaxMoves
            case .batDefeatDeadlineMoves: return counts.batDefeatDeadlineMoves
            case .goatRespawnMinMoves: return counts.goatRespawnMinMoves
            case .goatRespawnMaxMoves: return counts.goatRespawnMaxMoves
            case .raftDeliveryMinMoves: return counts.raftDeliveryMinMoves
            case .raftDeliveryMaxMoves: return counts.raftDeliveryMaxMoves
            case .snowmobilePriceCoins: return counts.snowmobilePriceCoins
            case .potatoChipRewardPerPotato: return counts.potatoChipRewardPerPotato
            case .foodOrderMinMoves: return counts.foodOrderMinMoves
            case .foodOrderMaxMoves: return counts.foodOrderMaxMoves
            case .foodOrderDeliverDeadlineMoves: return counts.foodOrderDeliverDeadlineMoves
            case .foodOrderNonDeliveryPenaltyCoins: return counts.foodOrderNonDeliveryPenaltyCoins
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
            case .bearProximityColumns: counts.bearProximityColumns = clamped
            case .bearProximityRows: counts.bearProximityRows = clamped
            case .batSpawnMinMoves: counts.batSpawnMinMoves = clamped
            case .batSpawnMaxMoves: counts.batSpawnMaxMoves = clamped
            case .batDefeatDeadlineMoves: counts.batDefeatDeadlineMoves = clamped
            case .goatRespawnMinMoves: counts.goatRespawnMinMoves = clamped
            case .goatRespawnMaxMoves: counts.goatRespawnMaxMoves = clamped
            case .raftDeliveryMinMoves: counts.raftDeliveryMinMoves = clamped
            case .raftDeliveryMaxMoves: counts.raftDeliveryMaxMoves = clamped
            case .snowmobilePriceCoins: counts.snowmobilePriceCoins = clamped
            case .potatoChipRewardPerPotato: counts.potatoChipRewardPerPotato = clamped
            case .foodOrderMinMoves: counts.foodOrderMinMoves = clamped
            case .foodOrderMaxMoves: counts.foodOrderMaxMoves = clamped
            case .foodOrderDeliverDeadlineMoves: counts.foodOrderDeliverDeadlineMoves = clamped
            case .foodOrderNonDeliveryPenaltyCoins: counts.foodOrderNonDeliveryPenaltyCoins = clamped
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
    private static let avatarStorageKey = "ut.settings.avatar"

    private(set) var counts: Counts {
        didSet {
            saveCounts()
        }
    }

    private(set) var avatar: Avatar {
        didSet {
            saveAvatar()
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

        if let rawAvatar = UserDefaults.standard.string(forKey: Self.avatarStorageKey),
           let persistedAvatar = Avatar(rawValue: rawAvatar) {
            avatar = persistedAvatar
        } else {
            avatar = .tam
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

    func resetToDefaults() {
        resetCountsToDefaults()
        avatar = .tam
    }

    func setAvatar(_ avatar: Avatar) {
        self.avatar = avatar
    }

    private func saveCounts() {
        guard let data = try? JSONEncoder().encode(counts) else { return }
        UserDefaults.standard.set(data, forKey: Self.countsStorageKey)
    }

    private func saveAvatar() {
        UserDefaults.standard.set(avatar.rawValue, forKey: Self.avatarStorageKey)
    }
}
