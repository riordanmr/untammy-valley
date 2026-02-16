//
//  GameScene.swift
//  UntammyValley
//
//  Created by Mark Riordan on 2026-02-15 with help from Microsoft Copilot.

import SpriteKit
import GameplayKit

func makeBasicTileSet() -> SKTileSet {
    let tileSize = CGSize(width: 64, height: 64)

    func makeTile(_ color: UIColor) -> SKTileGroup {
        let texture = SKTexture(image: UIGraphicsImageRenderer(size: tileSize).image { ctx in
            // Fill tile
            color.setFill()
            ctx.fill(CGRect(origin: .zero, size: tileSize))

            // Draw border
            let rect = CGRect(origin: .zero, size: tileSize)
            ctx.cgContext.setStrokeColor(UIColor.black.cgColor)
            ctx.cgContext.setLineWidth(2)
            ctx.cgContext.stroke(rect)
        })

        let def = SKTileDefinition(texture: texture, size: tileSize)
        return SKTileGroup(tileDefinition: def)
    }

    let blue = makeTile(.systemBlue)
    let green = makeTile(.systemGreen)
    let yellow = makeTile(.systemYellow)

    return SKTileSet(tileGroups: [blue, green, yellow])
}




class GameScene: SKScene {
    
    private var label : SKLabelNode?
    private var spinnyNode : SKShapeNode?
    var player: PlayerNode!
    var cameraNode: SKCameraNode!

    
    override func didMove(to view: SKView) {
        backgroundColor = .black

        // --- TILE MAP ---
        let tileSet = makeBasicTileSet()

        let columns = 100
        let rows = 100
        let tileSize = CGSize(width: 64, height: 64)

        let tileMap = SKTileMapNode(tileSet: tileSet,
                                    columns: columns,
                                    rows: rows,
                                    tileSize: tileSize)

        // Center the tile map in the scene
        tileMap.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        tileMap.position = CGPoint(x: size.width / 2, y: size.height / 2)
        tileMap.zPosition = -10

        let groups = tileSet.tileGroups

        for col in 0..<columns {
            for row in 0..<rows {
                let index = (col + row) % groups.count
                tileMap.setTileGroup(groups[index], forColumn: col, row: row)
            }
        }



        addChild(tileMap)

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
