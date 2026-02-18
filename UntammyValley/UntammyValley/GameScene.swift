//
//  GameScene.swift
//  UntammyValley
//
//  Created by Mark Riordan on 2026-02-15 with help from Microsoft Copilot.

import SpriteKit
import GameplayKit

func makeBasicTileSet() -> SKTileSet {
    let tileSize = CGSize(width: 64, height: 64)
    
    // Helper to create a tile group from an asset name
    func makeTile(named name: String) -> SKTileGroup {
        let texture = SKTexture(imageNamed: name)
        let definition = SKTileDefinition(texture: texture, size: tileSize)
        let group = SKTileGroup(tileDefinition: definition)
        group.name = name
        return group
    }

    // Your new wood floor tile
    let wood = makeTile(named: "floor_wood")

    // Object tile (your wall)
    let wall = makeTile(named: "wall_vertical")

    // Return a tileset containing both tiles
    let tileSet = SKTileSet(tileGroups: [wood, wall])
    tileSet.defaultTileSize = tileSize
    return tileSet
}

class GameScene: SKScene {
    
    private var label : SKLabelNode?
    private var spinnyNode : SKShapeNode?
    var player: PlayerNode!
    var cameraNode: SKCameraNode!

    // This is called once per scene load.
    override func didMove(to view: SKView) {
        backgroundColor = .black

        // --- TILE MAP ---
        let tileSet = makeBasicTileSet()

        let columns = 100
        let rows = 100
        let tileSize = CGSize(width: 64, height: 64)

        // Create ground layer
        let tileMap = SKTileMapNode(tileSet: tileSet,
                                    columns: columns,
                                    rows: rows,
                                    tileSize: tileSize)

        // Center the tile map in the scene
        tileMap.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        tileMap.position = CGPoint(x: size.width / 2, y: size.height / 2)
        tileMap.zPosition = -10

        let woodGroup = tileSet.tileGroups[0]

        for col in 0..<columns {
            for row in 0..<rows {
                tileMap.setTileGroup(woodGroup, forColumn: col, row: row)
            }
        }
        addChild(tileMap)
        
        // Second tile layer for walls, furniture, etc.
        let objectTileMap = SKTileMapNode(
            tileSet: tileSet,
            columns: columns,
            rows: rows,
            tileSize: tileSize
        )
        objectTileMap.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        objectTileMap.position = CGPoint(x: size.width / 2, y: size.height / 2)
        objectTileMap.zPosition = 10   // above the floor
        addChild(objectTileMap)
        
        guard let wallGroup = tileSet.tileGroups.first(where: { $0.name == "wall_vertical" }) else {
            print("Missing wall tile group")
            return
        }

        let roomX = 47
        let roomY = 47
        let roomSize = 6

        // Horizontal walls (top and bottom)
        for col in roomX..<(roomX + roomSize) {
            objectTileMap.setTileGroup(wallGroup, forColumn: col, row: roomY)                 // bottom wall
            objectTileMap.setTileGroup(wallGroup, forColumn: col, row: roomY + roomSize - 1)  // top wall
        }

        // Vertical walls (left and right)
        for row in roomY..<(roomY + roomSize) {
            objectTileMap.setTileGroup(wallGroup, forColumn: roomX, row: row)                 // left wall
            objectTileMap.setTileGroup(wallGroup, forColumn: roomX + roomSize - 1, row: row)  // right wall
        }


        // --- PLAYER ---
        player = PlayerNode()
        // Place player at the center of the scene (and thus the tile map)
        player.position = CGPoint(x: size.width / 2, y: size.height / 2)
        addChild(player)

        // --- CAMERA ---
        cameraNode = SKCameraNode()
        camera = cameraNode
        addChild(cameraNode)

        // Make sure the camera starts on the player immediately
        cameraNode.position = player.position

    }

    override func didSimulatePhysics() {
        cameraNode.position = player.position
    }
    
    func touchDown(atPoint pos : CGPoint) {
        if let n = self.spinnyNode?.copy() as! SKShapeNode? {
            n.position = pos
            n.strokeColor = SKColor.green
            self.addChild(n)
        }
    }
    
    func touchMoved(toPoint pos : CGPoint) {
        if let n = self.spinnyNode?.copy() as! SKShapeNode? {
            n.position = pos
            n.strokeColor = SKColor.blue
            self.addChild(n)
        }
    }
    
    func touchUp(atPoint pos : CGPoint) {
        if let n = self.spinnyNode?.copy() as! SKShapeNode? {
            n.position = pos
            n.strokeColor = SKColor.red
            self.addChild(n)
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let label = self.label {
            label.run(SKAction.init(named: "Pulse")!, withKey: "fadeInOut")
        }
        
        for t in touches { self.touchDown(atPoint: t.location(in: self)) }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        for t in touches { self.touchMoved(toPoint: t.location(in: self)) }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first,
              let view = self.view else { return }

        // Convert from view coordinates → scene coordinates
        let locationInView = touch.location(in: view)
        let location = convertPoint(fromView: locationInView)

        let move = SKAction.move(to: location, duration: 0.4)
        player.run(move)
    }
   
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        for t in touches { self.touchUp(atPoint: t.location(in: self)) }
    }
    
    
    override func update(_ currentTime: TimeInterval) {
        // Called before each frame is rendered
    }
}
