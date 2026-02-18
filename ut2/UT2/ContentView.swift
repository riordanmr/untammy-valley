import SwiftUI
import SpriteKit

struct ContentView: View {
    private enum Screen {
        case map
        case stats
    }

    @StateObject private var gameState = GameState()
    @State private var selectedScreen: Screen = .map
    @State private var isMenuOpen = false

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Group {
                switch selectedScreen {
                case .map:
                    GameMapContainerView(state: gameState)
                case .stats:
                    StatsView(state: gameState)
                }
            }

            VStack(alignment: .trailing, spacing: 8) {
                Button {
                    withAnimation(.easeInOut(duration: 0.16)) {
                        isMenuOpen.toggle()
                    }
                } label: {
                    Text("≡")
                        .font(.title3.weight(.bold))
                        .frame(width: 38, height: 38)
                        .background(Color.black.opacity(0.55))
                        .foregroundStyle(Color.white)
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)

                if isMenuOpen {
                    VStack(alignment: .leading, spacing: 8) {
                        selectorButton(title: "Map", icon: "map", screen: .map)
                        selectorButton(title: "Stats", icon: "chart.bar", screen: .stats)
                    }
                    .padding(10)
                    .background(Color.black.opacity(0.62))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .transition(.move(edge: .top).combined(with: .opacity))
                }
            }
            .padding(.top, 8)
            .padding(.trailing, 10)
        }
    }

    private func selectorButton(title: String, icon: String, screen: Screen) -> some View {
        Button {
            selectedScreen = screen
            withAnimation(.easeInOut(duration: 0.16)) {
                isMenuOpen = false
            }
        } label: {
            Label(title, systemImage: icon)
                .font(.subheadline.weight(.semibold))
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(selectedScreen == screen ? Color.white : Color.black.opacity(0.55))
                .foregroundStyle(selectedScreen == screen ? Color.black : Color.white)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

private struct GameMapContainerView: View {
    @ObservedObject var state: GameState
    @StateObject private var holder: SceneHolder

    init(state: GameState) {
        self.state = state
        _holder = StateObject(wrappedValue: SceneHolder(state: state))
    }

    var body: some View {
        SpriteView(scene: holder.scene)
            .ignoresSafeArea()
            .background(.black)
    }
}

private final class SceneHolder: ObservableObject {
    let scene: GameScene

    init(state: GameState) {
        let gameScene = GameScene(gameState: state)
        gameScene.scaleMode = .resizeFill
        scene = gameScene
    }
}

private struct StatsView: View {
    @ObservedObject var state: GameState

    var body: some View {
        NavigationStack {
            List {
                Section("World") {
                    row("Current Area", state.location.rawValue)
                    row("Coins", "\(state.coins)")
                    row("Snowmobile", state.snowmobileBuilt ? "Built" : "Not built")
                    row("Fuel", "\(state.fuel)/\(state.fuelTankMax)")
                    row("Atlantic Progress", "\(state.atlanticProgress)%")
                    row("Atomic Tubes", "\(state.tubeSectionsBuilt)/\(state.sectionsRequired)")
                }

                Section("Mission") {
                    Text(state.missionText)
                        .font(.body)
                        .padding(.vertical, 4)
                }

                Section("Targets") {
                    row("Build Snowmobile", "\(state.snowmobileCost) coins")
                    row("Travel Cost", "\(state.travelFuelCost) fuel")
                    row("Refuel Cost", "\(state.refuelCost) coins for +\(state.refuelAmount) fuel")
                }
            }
            .navigationTitle("UT2 Progress")
        }
    }

    private func row(_ key: String, _ value: String) -> some View {
        HStack {
            Text(key)
            Spacer()
            Text(value)
                .foregroundStyle(.secondary)
        }
    }
}
