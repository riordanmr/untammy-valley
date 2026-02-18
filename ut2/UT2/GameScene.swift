import SpriteKit

final class GameScene: SKScene {
    private let gameState: GameState

    private let worldSize = CGSize(width: 3200, height: 1800)
    private let worldNode = SKNode()
    private let cameraNode = SKCameraNode()

    private let hero = SKShapeNode(circleOfRadius: 22)
    private var moveTarget: CGPoint?
    private var lastUpdateTime: TimeInterval = 0

    private let titleLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
    private let areaLabel = SKLabelNode(fontNamed: "AvenirNext-DemiBold")
    private let hintLabel = SKLabelNode(fontNamed: "AvenirNext-Regular")
    private let eventLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
    private var shouldShowInstructionHint = true

    private let familyBarRect = CGRect(x: 130, y: 260, width: 980, height: 700)
    private let schoolRect = CGRect(x: 1220, y: 300, width: 980, height: 700)
    private let chinaRect = CGRect(x: 2450, y: 320, width: 620, height: 620)

    init(gameState: GameState) {
        self.gameState = gameState
        super.init(size: .zero)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func didMove(to view: SKView) {
        backgroundColor = SKColor(red: 0.06, green: 0.08, blue: 0.12, alpha: 1)
        anchorPoint = CGPoint(x: 0, y: 0)
        resetSceneGraph()
        buildWorldMap()
        setupHero()
        setupCameraAndHud()
        refreshHudText()
    }

    override func didChangeSize(_ oldSize: CGSize) {
        super.didChangeSize(oldSize)
        guard camera != nil else { return }
        layoutHudForCurrentSize()
        updateCameraPosition()
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let touchInScene = touch.location(in: self)
        let touchInWorld = convert(touchInScene, to: worldNode)

        let tappedNodes = worldNode.nodes(at: touchInWorld)
        if let actionNode = tappedNodes.first(where: { $0.name?.hasPrefix("action.") == true }),
           let actionName = actionNode.name?.replacingOccurrences(of: "action.", with: "") {
            runAction(named: actionName)
            return
        }

        moveTarget = clampedWorldPoint(touchInWorld)
    }

    override func update(_ currentTime: TimeInterval) {
        let delta: TimeInterval
        if lastUpdateTime == 0 {
            delta = 1.0 / 60.0
        } else {
            delta = min(1.0 / 30.0, currentTime - lastUpdateTime)
        }
        lastUpdateTime = currentTime

        moveHero(deltaTime: delta)
        updateLocationFromHeroPosition()
        updateCameraPosition()
    }

    private func resetSceneGraph() {
        removeAllChildren()
        worldNode.removeAllChildren()
        worldNode.removeFromParent()
        cameraNode.removeAllChildren()
        cameraNode.removeFromParent()
        moveTarget = nil
    }

    private func buildWorldMap() {
        addChild(worldNode)

        let ground = SKShapeNode(rect: CGRect(origin: .zero, size: worldSize), cornerRadius: 0)
        ground.fillColor = SKColor(red: 0.10, green: 0.14, blue: 0.18, alpha: 1)
        ground.strokeColor = SKColor(red: 0.26, green: 0.32, blue: 0.38, alpha: 1)
        ground.lineWidth = 4
        ground.zPosition = -20
        worldNode.addChild(ground)

        addRoom(rect: familyBarRect, title: "Family Bar", color: SKColor(red: 0.40, green: 0.25, blue: 0.20, alpha: 0.9))
        addRoom(rect: schoolRect, title: "High School", color: SKColor(red: 0.18, green: 0.34, blue: 0.50, alpha: 0.9))
        addRoom(rect: chinaRect, title: "China Lab", color: SKColor(red: 0.30, green: 0.36, blue: 0.22, alpha: 0.9))

        addPath(from: CGPoint(x: 1080, y: 610), to: CGPoint(x: 1220, y: 610))
        addPath(from: CGPoint(x: 2200, y: 610), to: CGPoint(x: 2450, y: 610))
        addPath(from: CGPoint(x: 2200, y: 980), to: CGPoint(x: 2950, y: 980))

        addAreaLabel(text: "Frozen Atlantic Route", position: CGPoint(x: 2580, y: 1030))

        addActionNode(key: "chips", title: "Make Chips", position: CGPoint(x: 370, y: 720), color: .orange)
        addActionNode(key: "septic", title: "Dig Septic", position: CGPoint(x: 640, y: 500), color: .brown)
        addActionNode(key: "goats", title: "Chase Goats", position: CGPoint(x: 900, y: 720), color: .yellow)
        addActionNode(key: "buildSnowmobile", title: "Build Snowmobile", position: CGPoint(x: 600, y: 860), color: .green)

        addActionNode(key: "track", title: "Track Team", position: CGPoint(x: 1460, y: 780), color: .cyan)
        addActionNode(key: "volleyball", title: "Volleyball", position: CGPoint(x: 1730, y: 520), color: .cyan)
        addActionNode(key: "drill", title: "Drill Team", position: CGPoint(x: 2010, y: 780), color: .cyan)

        addActionNode(key: "travel", title: "Ride East", position: CGPoint(x: 2300, y: 980), color: .white)
        addActionNode(key: "refuelWest", title: "Refuel", position: CGPoint(x: 2520, y: 980), color: .purple)
        addActionNode(key: "refuelEast", title: "Refuel", position: CGPoint(x: 2780, y: 980), color: .purple)

        addActionNode(key: "tube", title: "Atomic Tubes", position: CGPoint(x: 2740, y: 600), color: .magenta)
    }

    private func addRoom(rect: CGRect, title: String, color: SKColor) {
        let room = SKShapeNode(rect: rect, cornerRadius: 24)
        room.fillColor = color
        room.strokeColor = .white.withAlphaComponent(0.35)
        room.lineWidth = 3
        room.zPosition = -5
        worldNode.addChild(room)

        let label = SKLabelNode(fontNamed: "AvenirNext-Bold")
        label.text = title
        label.fontSize = 34
        label.position = CGPoint(x: rect.midX, y: rect.maxY - 52)
        label.zPosition = 0
        worldNode.addChild(label)
    }

    private func addPath(from: CGPoint, to: CGPoint) {
        let path = CGMutablePath()
        path.move(to: from)
        path.addLine(to: to)

        let node = SKShapeNode(path: path)
        node.strokeColor = SKColor(red: 0.82, green: 0.84, blue: 0.88, alpha: 0.9)
        node.lineWidth = 12
        node.zPosition = -2
        worldNode.addChild(node)
    }

    private func addAreaLabel(text: String, position: CGPoint) {
        let label = SKLabelNode(fontNamed: "AvenirNext-DemiBold")
        label.text = text
        label.fontSize = 26
        label.fontColor = .white.withAlphaComponent(0.85)
        label.position = position
        worldNode.addChild(label)
    }

    private func addActionNode(key: String, title: String, position: CGPoint, color: SKColor) {
        let container = SKNode()
        container.name = "action.\(key)"
        container.position = position

        let marker = SKShapeNode(circleOfRadius: 40)
        marker.fillColor = color.withAlphaComponent(0.75)
        marker.strokeColor = .white.withAlphaComponent(0.9)
        marker.lineWidth = 2.5
        marker.name = container.name
        marker.zPosition = 4
        container.addChild(marker)

        let label = SKLabelNode(fontNamed: "AvenirNext-DemiBold")
        label.text = title
        label.fontSize = 16
        label.position = CGPoint(x: 0, y: -64)
        label.name = container.name
        label.zPosition = 5
        container.addChild(label)

        worldNode.addChild(container)
    }

    private func setupHero() {
        if hero.parent != nil {
            hero.removeFromParent()
        }
        hero.removeAllChildren()

        hero.fillColor = SKColor(red: 0.98, green: 0.45, blue: 0.72, alpha: 1)
        hero.strokeColor = .white
        hero.lineWidth = 2
        hero.position = CGPoint(x: 470, y: 580)
        hero.zPosition = 8
        worldNode.addChild(hero)

        let backpack = SKShapeNode(rectOf: CGSize(width: 16, height: 20), cornerRadius: 4)
        backpack.fillColor = SKColor(red: 0.28, green: 0.60, blue: 0.95, alpha: 1)
        backpack.strokeColor = .clear
        backpack.position = CGPoint(x: -7, y: -6)
        backpack.zPosition = 7
        hero.addChild(backpack)

        let bob = SKAction.sequence([
            .moveBy(x: 0, y: 5, duration: 0.8),
            .moveBy(x: 0, y: -5, duration: 0.8)
        ])
        hero.run(.repeatForever(bob))
    }

    private func setupCameraAndHud() {
        addChild(cameraNode)
        camera = cameraNode

        titleLabel.fontSize = 28
        titleLabel.horizontalAlignmentMode = .left
        titleLabel.verticalAlignmentMode = .top
        titleLabel.fontColor = .white
        cameraNode.addChild(titleLabel)

        areaLabel.fontSize = 20
        areaLabel.horizontalAlignmentMode = .left
        areaLabel.verticalAlignmentMode = .top
        areaLabel.fontColor = SKColor(red: 0.95, green: 0.90, blue: 0.5, alpha: 1)
        cameraNode.addChild(areaLabel)

        hintLabel.fontSize = 16
        hintLabel.horizontalAlignmentMode = .left
        hintLabel.verticalAlignmentMode = .bottom
        hintLabel.fontColor = .white.withAlphaComponent(0.90)
        hintLabel.numberOfLines = 3
        hintLabel.preferredMaxLayoutWidth = 560
        cameraNode.addChild(hintLabel)

        eventLabel.fontSize = 18
        eventLabel.horizontalAlignmentMode = .center
        eventLabel.verticalAlignmentMode = .bottom
        eventLabel.alpha = 0
        cameraNode.addChild(eventLabel)

        layoutHudForCurrentSize()
        updateCameraPosition()
    }

    private func layoutHudForCurrentSize() {
        titleLabel.position = CGPoint(x: -size.width * 0.47, y: size.height * 0.47)
        areaLabel.position = CGPoint(x: -size.width * 0.47, y: size.height * 0.40)
        hintLabel.position = CGPoint(x: -size.width * 0.47, y: -size.height * 0.44)
        eventLabel.position = CGPoint(x: 0, y: -size.height * 0.44)
    }

    private func refreshHudText() {
        titleLabel.text = "UT2 · World Map"
        areaLabel.text = "Area: \(gameState.location.rawValue)"
        if shouldShowInstructionHint {
            hintLabel.removeAction(forKey: "hideHint")
            hintLabel.alpha = 1
            hintLabel.text = "Tap a room/object to interact. Tap empty ground to walk. Stats and progress are in the Stats tab."
        } else if hintLabel.action(forKey: "hideHint") == nil {
            hintLabel.text = ""
            hintLabel.alpha = 0
        }
    }

    private func updateLocationFromHeroPosition() {
        let oldLocation = gameState.location

        if familyBarRect.contains(hero.position) {
            gameState.location = .familyBar
        } else if schoolRect.contains(hero.position) {
            gameState.location = .highSchool
        } else if chinaRect.contains(hero.position) {
            gameState.location = .chinaLab
        } else {
            gameState.location = .expedition
        }

        if oldLocation == .familyBar && gameState.location != .familyBar && shouldShowInstructionHint {
            shouldShowInstructionHint = false
            let hide = SKAction.sequence([
                .fadeOut(withDuration: 0.45),
                .run { [weak self] in
                    self?.hintLabel.text = ""
                }
            ])
            hintLabel.run(hide, withKey: "hideHint")
        }

        if oldLocation != gameState.location {
            refreshHudText()
        }
    }

    private func updateCameraPosition() {
        let halfWidth = size.width * 0.5
        let halfHeight = size.height * 0.5

        let clampedX = min(max(hero.position.x, halfWidth), worldSize.width - halfWidth)
        let clampedY = min(max(hero.position.y, halfHeight), worldSize.height - halfHeight)
        cameraNode.position = CGPoint(x: clampedX, y: clampedY)
    }

    private func clampedWorldPoint(_ point: CGPoint) -> CGPoint {
        CGPoint(
            x: min(max(point.x, 30), worldSize.width - 30),
            y: min(max(point.y, 30), worldSize.height - 30)
        )
    }

    private func moveHero(deltaTime: TimeInterval) {
        guard let target = moveTarget else { return }

        let dx = target.x - hero.position.x
        let dy = target.y - hero.position.y
        let distance = sqrt(dx * dx + dy * dy)

        if distance < 6 {
            hero.position = target
            moveTarget = nil
            return
        }

        let speed: CGFloat = 300
        let step = min(CGFloat(deltaTime) * speed, distance)
        let direction = CGPoint(x: dx / distance, y: dy / distance)
        hero.position = CGPoint(x: hero.position.x + direction.x * step, y: hero.position.y + direction.y * step)
    }

    private func runAction(named action: String) {
        if gameState.gameComplete {
            showEvent("World already saved. Explore freely.", color: .green)
            return
        }

        switch action {
        case "chips":
            guard ensureLocation(.familyBar, message: "Make chips inside the Family Bar area.") else { return }
            let earned = Int.random(in: 8...14)
            gameState.coins += earned
            animateHeroNudge()
            showEvent("Fresh chips sold: +\(earned) coins", color: .cyan)

        case "septic":
            guard ensureLocation(.familyBar, message: "Dig septic systems in the Family Bar front yard.") else { return }
            let earned = Int.random(in: 14...24)
            gameState.coins += earned
            animateHeroNudge()
            showEvent("Septic project complete: +\(earned) coins", color: .cyan)

        case "goats":
            guard ensureLocation(.familyBar, message: "Chase goats from the Family Bar parking lot.") else { return }
            let earned = Int.random(in: 10...18)
            gameState.coins += earned
            animateHeroNudge()
            showEvent("Goats cleared: +\(earned) coins", color: .cyan)

        case "track":
            guard ensureLocation(.highSchool, message: "Track practice is in the High School area.") else { return }
            let earned = Int.random(in: 7...12)
            gameState.coins += earned
            animateHeroNudge()
            showEvent("Track reps complete: +\(earned) coins", color: .cyan)

        case "volleyball":
            guard ensureLocation(.highSchool, message: "Volleyball drills are in the High School area.") else { return }
            let earned = Int.random(in: 8...13)
            gameState.coins += earned
            animateHeroNudge()
            showEvent("Volleyball clinic done: +\(earned) coins", color: .cyan)

        case "drill":
            guard ensureLocation(.highSchool, message: "Drill team routine is at High School.") else { return }
            let earned = Int.random(in: 9...15)
            gameState.coins += earned
            animateHeroNudge()
            showEvent("Drill showcase complete: +\(earned) coins", color: .cyan)

        case "buildSnowmobile":
            guard ensureLocation(.familyBar, message: "Build the snowmobile at the Family Bar workshop.") else { return }
            guard !gameState.snowmobileBuilt else {
                showEvent("Huge snowmobile is already built.", color: .yellow)
                return
            }
            guard gameState.coins >= gameState.snowmobileCost else {
                showEvent("Need \(gameState.snowmobileCost - gameState.coins) more coins.", color: .orange)
                return
            }
            gameState.coins -= gameState.snowmobileCost
            gameState.snowmobileBuilt = true
            gameState.fuel = 70
            showEvent("Snowmobile completed. Fuel tank primed.", color: .green)

        case "travel":
            guard ensureLocation(.expedition, message: "Move onto the frozen Atlantic route to travel east.") else { return }
            guard gameState.snowmobileBuilt else {
                showEvent("Build the huge snowmobile first.", color: .orange)
                return
            }
            guard gameState.fuel >= gameState.travelFuelCost else {
                showEvent("Not enough fuel. Use a refuel station.", color: .orange)
                return
            }

            gameState.fuel -= gameState.travelFuelCost
            gameState.atlanticProgress = min(100, gameState.atlanticProgress + 20)
            animateHeroNudge()

            if gameState.atlanticProgress == 100 {
                moveTarget = CGPoint(x: 2660, y: 600)
                showEvent("Reached China. Build atomic tubes in the lab.", color: .green)
            } else {
                showEvent("Atlantic progress: \(gameState.atlanticProgress)%", color: .cyan)
            }

        case "refuelWest", "refuelEast":
            guard ensureLocation(.expedition, message: "Refuel stations are on the frozen Atlantic route.") else { return }
            guard gameState.coins >= gameState.refuelCost else {
                showEvent("Need \(gameState.refuelCost - gameState.coins) more coins to refuel.", color: .orange)
                return
            }
            gameState.coins -= gameState.refuelCost
            gameState.fuel = min(gameState.fuelTankMax, gameState.fuel + gameState.refuelAmount)
            showEvent("Refueled. Fuel now \(gameState.fuel)/\(gameState.fuelTankMax).", color: .green)

        case "tube":
            guard ensureLocation(.chinaLab, message: "Atomic tube assembly is in the China lab.") else { return }
            guard gameState.atlanticProgress == 100 else {
                showEvent("Complete the Atlantic crossing first.", color: .orange)
                return
            }
            guard gameState.tubeSectionsBuilt < gameState.sectionsRequired else {
                showEvent("All tube sections are complete.", color: .green)
                return
            }

            let sectionCost = 15
            guard gameState.coins >= sectionCost else {
                showEvent("Need \(sectionCost - gameState.coins) more coins.", color: .orange)
                return
            }
            gameState.coins -= sectionCost
            gameState.tubeSectionsBuilt += 1
            animateHeroNudge()

            if gameState.tubeSectionsBuilt == gameState.sectionsRequired {
                gameState.gameComplete = true
                showEvent("Atomic tubes completed. The world is saved.", color: .green)
            } else {
                showEvent("Tube section \(gameState.tubeSectionsBuilt)/\(gameState.sectionsRequired) assembled.", color: .cyan)
            }

        default:
            break
        }
    }

    private func ensureLocation(_ expected: UT2Location, message: String) -> Bool {
        updateLocationFromHeroPosition()
        guard gameState.location == expected else {
            showEvent(message, color: .orange)
            return false
        }
        return true
    }

    private func animateHeroNudge() {
        hero.removeAllActions()
        let nudge = SKAction.sequence([
            .moveBy(x: 14, y: 0, duration: 0.08),
            .moveBy(x: -14, y: 0, duration: 0.08)
        ])
        let bob = SKAction.sequence([
            .moveBy(x: 0, y: 5, duration: 0.8),
            .moveBy(x: 0, y: -5, duration: 0.8)
        ])
        hero.run(nudge) {
            self.hero.run(.repeatForever(bob))
        }
    }

    private func showEvent(_ text: String, color: SKColor) {
        eventLabel.removeAllActions()
        eventLabel.text = text
        eventLabel.fontColor = color
        eventLabel.alpha = 0

        let sequence = SKAction.sequence([
            .fadeIn(withDuration: 0.2),
            .wait(forDuration: 1.5),
            .fadeOut(withDuration: 0.45)
        ])
        eventLabel.run(sequence)
        refreshHudText()
    }
}
