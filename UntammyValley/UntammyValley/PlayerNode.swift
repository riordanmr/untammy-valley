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
        // Temporary placeholder: a simple colored square
        let size = CGSize(width: 40, height: 40)
        let texture = SKTexture(image: UIGraphicsImageRenderer(size: size).image { ctx in
            UIColor.systemTeal.setFill()
            ctx.fill(CGRect(origin: .zero, size: size))
        })

        super.init(texture: texture, color: .clear, size: size)
        self.name = "player"
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
