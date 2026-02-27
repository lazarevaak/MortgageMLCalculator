//
//  CianAPIService.swift
//  MortgageMLCalculator
//
//  Created by Alexandra Lazareva on 25.02.2026.
//

import RxSwift

final class CianAPIService {
    
    private let client: NetworkClient
    
    init(client: NetworkClient = NetworkClient()) {
        self.client = client
    }
    
    func loadOffers() -> Observable<[CianOffer]> {
        return client
            .fetchMockProperties()
            .map { $0.offers }
    }
}
