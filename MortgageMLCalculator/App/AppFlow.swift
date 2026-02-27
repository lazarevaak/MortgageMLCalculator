//
//  AppFlow.swift
//  MortgageMLCalculator
//
//  Created by MacBoock on 25.02.2026.
//

import RxFlow
import RxSwift
import UIKit

enum AppStep: Step {
    case map
    case calculator(PropertyObject)
}

final class AppFlow: Flow {

    var root: Presentable { rootViewController }
    private let rootViewController = UINavigationController()

    func navigate(to step: Step) -> FlowContributors {

        guard let step = step as? AppStep else { return .none }

        switch step {
            
        case .map:
            let viewModel = MapViewModel()
            let vc = MapViewController(viewModel: viewModel)
            rootViewController.setViewControllers([vc], animated: false)
            return .none
            
        case .calculator(let property):
            let viewModel = MortgageViewModel(property: property)
            let vc = MortgageViewController(viewModel: viewModel)
            rootViewController.pushViewController(vc, animated: true)
            return .none
            
        }
    }
}
