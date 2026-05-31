//
//  PropertyData.swift
//  MortgageMLCalculator
//
//  Created by Alexandra Lazareva on 25.02.2026.
//

import Foundation

struct PropertyData: Codable {
    
    let area: Double
    let rooms: Double
    let bathrooms: Double
    let garage: Double
    let distance: Double
    let floor: Double
    let year: Double

    init(
        area: Double,
        rooms: Double,
        bathrooms: Double,
        garage: Double,
        distance: Double,
        floor: Double,
        year: Double
    ) {
        self.area = area
        self.rooms = rooms
        self.bathrooms = bathrooms
        self.garage = garage
        self.distance = distance
        self.floor = floor
        self.year = year
    }
    
    init?(
        area: String,
        rooms: String,
        bathrooms: String,
        garage: String,
        distance: String,
        floor: String,
        year: String
    ) {
        guard
            let area = Double(area),
            let rooms = Double(rooms),
            let bathrooms = Double(bathrooms),
            let garage = Double(garage),
            let distance = Double(distance),
            let floor = Double(floor),
            let year = Double(year)
        else { return nil }
        
        self.init(
            area: area,
            rooms: rooms,
            bathrooms: bathrooms,
            garage: garage,
            distance: distance,
            floor: floor,
            year: year
        )
    }

    init(property: PropertyObject) {
        self.init(
            area: property.area,
            rooms: Double(property.rooms),
            bathrooms: Double(property.bathrooms),
            garage: Double(property.garage),
            distance: property.distance,
            floor: Double(property.floor),
            year: Double(property.buildYear)
        )
    }
}
