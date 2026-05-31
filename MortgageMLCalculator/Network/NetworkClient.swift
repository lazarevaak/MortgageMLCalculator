//
//  NetworkClient.swift
//  MortgageMLCalculator
//
//  Created by Alexandra Lazareva on 25.02.2026.
//

import Foundation

final class NetworkClient {
    
    func fetchMockProperties() throws -> CianOffersResponse {
        guard let url = Bundle.main.url(
            forResource: "moscow_properties",
            withExtension: "json"
        ) else {
            throw NSError(domain: "FileNotFound", code: -1)
        }

        let data = try Data(contentsOf: url)
        return try JSONDecoder().decode(CianOffersResponse.self, from: data)
    }
}
