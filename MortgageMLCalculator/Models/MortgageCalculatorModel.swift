//
//  MortgageCalculatorModel.swift
//  MortgageMLCalculator
//
//  Created by Alexandra Lazareva on 25.02.2026.
//

import Foundation
import CoreML

protocol MortgageCalculatorProtocol {
    func predictPrice(property: PropertyData) -> Double
    func calculateMonthlyPayment(price: Double, terms: MortgageTerms) -> Double
}

final class MortgageCalculatorModel: MortgageCalculatorProtocol {
    
    func predictPrice(property: PropertyData) -> Double {
        if let extendedPrice = predictExtendedPrice(property: property) {
            return extendedPrice
        }

        return predictBasePrice(property: property)
    }
    
    private func predictExtendedPrice(property: PropertyData) -> Double? {
        do {
            let model = try HousePricePredictorExtended(configuration: .init())
            
            let input = HousePricePredictorExtendedInput(
                area: Int64(property.area),
                total_rooms: Int64(property.rooms),
                bathrooms: Int64(property.bathrooms),
                garage_spaces: Int64(property.garage),
                distance_to_center: property.distance,
                floor: Int64(property.floor),
                build_year: Int64(property.year),
                balcony: inferredBalcony(for: property),
                renovation_level: inferredRenovationLevel(for: property),
                has_elevator: inferredElevator(for: property),
                ceiling_height: inferredCeilingHeight(for: property),
                district_rating: inferredDistrictRating(for: property)
            )
            
            let prediction = try model.prediction(input: input)
            guard prediction.price.isFinite, prediction.price > 0 else {
                return nil
            }
            
            return prediction.price
        } catch {
            return nil
        }
    }
    
    private func predictBasePrice(property: PropertyData) -> Double {
        do {
            let model = try HousePricePredictor(configuration: .init())
            
            let input = HousePricePredictorInput(
                area: Int64(property.area),
                total_rooms: Int64(property.rooms),
                bathrooms: Int64(property.bathrooms),
                garage_spaces: Int64(property.garage),
                distance_to_center: property.distance,
                floor: Int64(property.floor),
                build_year: Int64(property.year)
            )
            
            let prediction = try model.prediction(input: input)
            return max(Double(prediction.price), fallbackPrice(property: property))
        } catch {
            return fallbackPrice(property: property)
        }
    }
    
    func calculateMonthlyPayment(price: Double, terms: MortgageTerms) -> Double {
        
        let loanAmount = price * (100 - terms.downPayment) / 100
        let monthlyRate = (terms.interestRate / 100) / 12
        let months = terms.loanTerm * 12
        
        guard monthlyRate > 0 else {
            return loanAmount / months
        }
        
        let compound = pow(1 + monthlyRate, months)
        let denominator = compound - 1
        
        guard denominator > 0 else {
            return loanAmount / months
        }
        
        return loanAmount * (monthlyRate * compound / denominator)
    }
    
    private func fallbackPrice(property: PropertyData) -> Double {
        let base = property.area * 60_000
        let bonus = property.rooms * 200_000
        let discount = property.distance * 100_000
        let yearBonus = (property.year - 2000) * 10_000
        
        return max(base + bonus - discount + yearBonus, 1_000_000)
    }
    
    private func inferredBalcony(for property: PropertyData) -> Int64 {
        property.area >= 45 && property.floor > 1 ? 1 : 0
    }
    
    private func inferredRenovationLevel(for property: PropertyData) -> Int64 {
        if property.year >= 2018 {
            return 3
        } else if property.year >= 2005 {
            return 2
        } else {
            return 1
        }
    }
    
    private func inferredElevator(for property: PropertyData) -> Int64 {
        property.floor >= 3 || property.year >= 2000 ? 1 : 0
    }
    
    private func inferredCeilingHeight(for property: PropertyData) -> Double {
        if property.year >= 2015 {
            return 2.9
        } else if property.year >= 2000 {
            return 2.75
        } else {
            return 2.65
        }
    }
    
    private func inferredDistrictRating(for property: PropertyData) -> Int64 {
        switch property.distance {
        case ..<1.5:
            return 5
        case ..<3:
            return 4
        case ..<5:
            return 3
        case ..<8:
            return 2
        default:
            return 1
        }
    }
}
