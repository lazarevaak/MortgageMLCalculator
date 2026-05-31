//
//  CianAPIService.swift
//  MortgageMLCalculator
//
//  Created by Alexandra Lazareva on 25.02.2026.
//

import Foundation

final class CianAPIService {
    
    private let client: NetworkClient
    
    init(client: NetworkClient = NetworkClient()) {
        self.client = client
    }
    
    func loadOffers() throws -> [CianOffer] {
        try client.fetchMockProperties().offers
    }
}
