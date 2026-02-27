//
//  MapViewModel.swift
//  MortgageMLCalculator
//
//  Created by Alexandra Lazareva on 25.02.2026.
//

import RxSwift
import RxCocoa

final class MapViewModel {

    private let repository = PropertyRepository()
    private let disposeBag = DisposeBag()

    let properties = BehaviorRelay<[PropertyObject]>(value: [])

    func load() {
        repository.loadProperties()
            .subscribe(onNext: { [weak self] properties in
                self?.properties.accept(properties)
            })
            .disposed(by: disposeBag)
    }
}
