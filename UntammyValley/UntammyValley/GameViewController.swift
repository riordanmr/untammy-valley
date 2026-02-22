//
//  GameViewController.swift
//  UntammyValley
//
//  Created by Mark Riordan on 2/15/26.
//

import UIKit
import SpriteKit
import GameplayKit

class GameViewController: UIViewController {

    func saveGameStateIfPossible() {
        guard let skView = self.view as? SKView,
              let scene = skView.scene as? GameScene else { return }
        scene.saveGameStateNow()
    }

    override func loadView() {
        self.view = SKView(frame: UIScreen.main.bounds)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        guard let skView = self.view as? SKView else { return }
        skView.ignoresSiblingOrder = true
        let scene = GameScene(size: skView.bounds.size)
        scene.scaleMode = .resizeFill
        skView.presentScene(scene)
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        if UIDevice.current.userInterfaceIdiom == .phone {
            return .allButUpsideDown
        } else {
            return .all
        }
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }
}
