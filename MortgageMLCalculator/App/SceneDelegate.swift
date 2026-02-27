//
//  SceneDelegate.swift
//  MortgageMLCalculator
//
//  Created by MacBoock on 25.02.2026.
//

import UIKit
import RxFlow
import RxSwift
import RealmSwift

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?
    private let disposeBag = DisposeBag()
    private var coordinator: FlowCoordinator?

    func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {
        let config = Realm.Configuration(
            schemaVersion: 100,
            deleteRealmIfMigrationNeeded: true
        )
        Realm.Configuration.defaultConfiguration = config

        guard let windowScene = scene as? UIWindowScene else { return }

        let window = UIWindow(windowScene: windowScene)
        self.window = window

        let appFlow = AppFlow()

        let coordinator = FlowCoordinator()
        self.coordinator = coordinator

        coordinator.coordinate(
            flow: appFlow,
            with: OneStepper(withSingleStep: AppStep.map)
        )

        window.rootViewController = appFlow.root as? UIViewController
        window.makeKeyAndVisible()
    }
}
