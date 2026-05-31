//
//  MortgageCalculationHistoryItem.swift
//  MortgageMLCalculator
//

import Foundation

struct MortgageCalculationHistoryItem: Codable, Identifiable {
    let id: UUID
    let date: Date
    let property: PropertyData
    let terms: MortgageTerms
    let predictedPrice: Double
    let monthlyPayment: Double

    init(
        id: UUID = UUID(),
        date: Date = Date(),
        property: PropertyData,
        terms: MortgageTerms,
        predictedPrice: Double,
        monthlyPayment: Double
    ) {
        self.id = id
        self.date = date
        self.property = property
        self.terms = terms
        self.predictedPrice = predictedPrice
        self.monthlyPayment = monthlyPayment
    }
}
