//
//  SceneDelegate.swift
//  UntammyValley
//
//  Created by GitHub Copilot on 2/16/26.
//

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    func scene(_ scene: UIScene,
               willConnectTo session: UISceneSession,
               options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = scene as? UIWindowScene else { return }

        let window = UIWindow(windowScene: windowScene)
        window.rootViewController = GameViewController()
        self.window = window
        window.makeKeyAndVisible()
    }
}
