//
//  PlayerNode.swift
//  UntammyValley
//
//  Created by Mark Riordan on 2/15/26.
//

import Foundation
import SpriteKit

class PlayerNode: SKSpriteNode {
    private static let displaySize = CGSize(width: 65, height: 65)

    init() {
        let resolvedTexture = Self.texture(for: UTSettings.shared.avatar)
        super.init(texture: resolvedTexture, color: .clear, size: Self.displaySize)
        self.name = "player"

        let bodyRadius = min(Self.displaySize.width, Self.displaySize.height) * 0.38
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

    func refreshAvatarTexture() {
        texture = Self.texture(for: UTSettings.shared.avatar)
        size = Self.displaySize
        colorBlendFactor = 0
    }

    private static func texture(for avatar: UTSettings.Avatar) -> SKTexture {
        let avatarTexture = SKTexture(imageNamed: avatar.assetName)
        if avatarTexture.size() != .zero {
            return avatarTexture
        }

        let fallbackTexture = SKTexture(imageNamed: "player_icon")
        if fallbackTexture.size() != .zero {
            return fallbackTexture
        }

        let fallbackImage = UIGraphicsImageRenderer(size: displaySize).image { ctx in
            UIColor.systemTeal.setFill()
            ctx.fill(CGRect(origin: .zero, size: displaySize))
        }
        return SKTexture(image: fallbackImage)
    }
}
