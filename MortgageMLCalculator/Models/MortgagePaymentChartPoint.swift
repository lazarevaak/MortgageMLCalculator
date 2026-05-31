//
//  MortgagePaymentChartPoint.swift
//  MortgageMLCalculator
//
//  Created by Alexandra Lazareva on 31.05.2026.
//

import Combine
import Foundation

struct MortgagePaymentChartPoint: Identifiable {
    let term: Int
    let payment: Double

    var id: Int {
        term
    }
}
