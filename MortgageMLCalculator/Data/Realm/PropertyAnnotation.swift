//
//  PropertyAnnotation.swift
//  MortgageMLCalculator
//
//  Created by Alexandra Lazareva on 28.02.2026.
//

import Foundation
import MapKit

final class PropertyAnnotation: NSObject, MKAnnotation {

    let property: PropertyObject

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(
            latitude: property.latitude,
            longitude: property.longitude
        )
    }

    var title: String? {
        "\(Int(property.price)) ₽"
    }

    init(property: PropertyObject) {
        self.property = property
    }
}
