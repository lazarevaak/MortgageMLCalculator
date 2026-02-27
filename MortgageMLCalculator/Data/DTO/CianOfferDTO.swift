//
//  CianOfferDTO.swift
//  MortgageMLCalculator
//
//  Created by MacBoock on 25.02.2026.
//

struct CianOfferDTO: Decodable {
    let id: Int
    let price: Double
    let area: Double
    let rooms: Int
    let floor: Int
    let buildYear: Int
    let latitude: Double
    let longitude: Double
}
