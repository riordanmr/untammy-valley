//
//  PlayerNode.swift
//  UntammyValley
//
//  Created by Mark Riordan on 2/15/26.
//

import Foundation
import SpriteKit

class PlayerNode: SKSpriteNode {

    init() {
        let displaySize = CGSize(width: 57.2, height: 57.2)
        let iconTexture = SKTexture(imageNamed: "player_icon")

        let resolvedTexture: SKTexture
        if iconTexture.size() == .zero {
            resolvedTexture = SKTexture(image: UIGraphicsImageRenderer(size: displaySize).image { ctx in
                UIColor.systemTeal.setFill()
                ctx.fill(CGRect(origin: .zero, size: displaySize))
            })
        } else {
            resolvedTexture = iconTexture
        }

        super.init(texture: resolvedTexture, color: .clear, size: displaySize)
        self.name = "player"

        let bodyRadius = min(displaySize.width, displaySize.height) * 0.38
        let body = SKPhysicsBody(circleOfRadius: bodyRadius)
        body.affectedByGravity = false
        body.allowsRotation = false
        body.linearDamping = 10.0
        body.friction = 0.0
        body.restitution = 0.0
        body.usesPreciseCollisionDetection = true
        physicsBody = body
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
