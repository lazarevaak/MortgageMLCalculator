//
//  MortgageMLCalculatorApp.swift
//  MortgageMLCalculator
//
//  Created by Alexandra Lazareva on 25.02.2026.
//

import RealmSwift
import SwiftUI

@main
struct MortgageMLCalculatorApp: App {
    init() {
        Realm.Configuration.defaultConfiguration = Realm.Configuration(
            schemaVersion: 100,
            deleteRealmIfMigrationNeeded: true
        )
    }

    var body: some Scene {
        WindowGroup {
            RootTabView()
        }
    }
}
