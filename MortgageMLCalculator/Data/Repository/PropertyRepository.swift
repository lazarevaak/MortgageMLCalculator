//
//  PropertyRepository.swift
//  MortgageMLCalculator
//
//  Created by Alexandra Lazareva on 25.02.2026.
//

import RxSwift
import RealmSwift

final class PropertyRepository {
    
    private let apiService = CianAPIService()
    
    private let realm: Realm = {
        do {
            return try Realm()
        } catch {
            fatalError("Realm init error: \(error)")
        }
    }()
    
    func loadProperties() -> Observable<[PropertyObject]> {
        
        return apiService.loadOffers()
            .map { offers in
                
                try self.realm.write {
                    
                    offers.forEach { offer in
                        let object = PropertyObject()
                        
                        object.id = offer.id
                        object.price = offer.price
                        object.area = offer.area
                        object.rooms = offer.rooms
                        object.floor = offer.floor
                        object.buildYear = offer.buildYear
                        object.address = offer.address
                        object.district = offer.district
                        object.metro = offer.metro
                        object.latitude = offer.latitude
                        object.longitude = offer.longitude
                        
                        self.realm.add(object, update: .modified)
                    }
                }
                
                return Array(self.realm.objects(PropertyObject.self))
            }
    }
}
