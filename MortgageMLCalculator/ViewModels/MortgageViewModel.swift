//
//  MortgageViewModel.swift
//  MortgageMLCalculator
//
//  Created by Alexandra Lazareva on 25.02.2026.
//

import Foundation

final class MortgageViewModel {
    
    private(set) var property: PropertyObject
    
    private let calculator: MortgageCalculatorProtocol
    
    init(
        property: PropertyObject,
        calculator: MortgageCalculatorProtocol = MortgageCalculatorModel()
    ) {
        self.property = property
        self.calculator = calculator
    }
    
    struct Input {
        let property: PropertyData
        let mortgage: MortgageTerms
    }
    
    struct Output {
        let price: Double
        let monthlyPayment: Double
    }
    
    func calculate(input: Input) -> Output {
        
        let price = calculator.predictPrice(property: input.property)
        
        let payment = calculator.calculateMonthlyPayment(
            price: price,
            terms: input.mortgage
        )
        
        return Output(
            price: price,
            monthlyPayment: payment
        )
    }
}
