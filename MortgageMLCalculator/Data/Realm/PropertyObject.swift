//
//  PropertyObject.swift
//  MortgageMLCalculator
//
//  Created by Alexandra Lazareva on 25.02.2026.
//

import RealmSwift

final class PropertyObject: Object {
    
    @Persisted(primaryKey: true) var id: String
    @Persisted var price: Double
    @Persisted var area: Double
    @Persisted var rooms: Double
    @Persisted var floor: Double
    @Persisted var buildYear: Double
    @Persisted var address: String
    @Persisted var district: String
    @Persisted var metro: String
    @Persisted var latitude: Double
    @Persisted var longitude: Double
}
