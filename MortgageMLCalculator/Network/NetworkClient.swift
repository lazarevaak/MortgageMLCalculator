//
//  NetworkClient.swift
//  MortgageMLCalculator
//
//  Created by Alexandra Lazareva on 25.02.2026.
//

import Foundation
import RxSwift

final class NetworkClient {
    
    func fetchMockProperties() -> Observable<CianOffersResponse> {
        
        return Observable.create { observer in
            
            guard let url = Bundle.main.url(
                forResource: "moscow_properties",
                withExtension: "json"
            ) else {
                observer.onError(NSError(domain: "FileNotFound", code: -1))
                return Disposables.create()
            }
            
            do {
                let data = try Data(contentsOf: url)
                let decoded = try JSONDecoder().decode(CianOffersResponse.self, from: data)
                
                observer.onNext(decoded)
                observer.onCompleted()
            } catch {
                observer.onError(error)
            }
            
            return Disposables.create()
        }
    }
}
