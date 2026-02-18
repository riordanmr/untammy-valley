import Foundation

enum UT2Location: String {
    case familyBar = "Family Bar"
    case highSchool = "High School"
    case expedition = "Frozen Atlantic"
    case chinaLab = "China Lab"
}

final class GameState: ObservableObject {
    @Published var location: UT2Location = .familyBar
    @Published var coins: Int = 0
    @Published var snowmobileBuilt = false
    @Published var fuel: Int = 0
    @Published var atlanticProgress: Int = 0
    @Published var tubeSectionsBuilt: Int = 0
    @Published var gameComplete = false

    let snowmobileCost = 120
    let fuelTankMax = 100
    let travelFuelCost = 20
    let refuelCost = 12
    let refuelAmount = 30
    let sectionsRequired = 6

    var missionText: String {
        if gameComplete {
            return "Mission complete: atomic tubes are online and the world is saved."
        }

        switch location {
        case .familyBar:
            return snowmobileBuilt
                ? "Snowmobile is built. Keep earning coins or head east to the Atlantic route."
                : "Earn \(snowmobileCost) coins to build the huge snowmobile."
        case .highSchool:
            return snowmobileBuilt
                ? "Keep training or move into expedition territory to travel east."
                : "Build coins in school teams to unlock the snowmobile."
        case .expedition:
            return "Travel east to 100% progress and refuel along the frozen Atlantic."
        case .chinaLab:
            return "Assemble \(sectionsRequired) atomic tube sections in China."
        }
    }

    var compactProgress: String {
        var pieces: [String] = ["Coins: \(coins)"]
        pieces.append(snowmobileBuilt ? "Snowmobile: Built" : "Snowmobile: Not Built")
        pieces.append("Fuel: \(fuel)/\(fuelTankMax)")
        pieces.append("Atlantic: \(atlanticProgress)%")
        pieces.append("Tubes: \(tubeSectionsBuilt)/\(sectionsRequired)")
        return pieces.joined(separator: "  ·  ")
    }
}
