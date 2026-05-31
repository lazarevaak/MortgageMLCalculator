//
//  MortgageCalculatorViewModel.swift
//  MortgageMLCalculator
//
//  Created by Alexandra Lazareva on 25.02.2026.
//

import Foundation
import Combine

final class MortgageCalculatorViewModel: ObservableObject {
    static let buildYearRange = 1990...2025

    @Published var area: String
    @Published var rooms: String
    @Published var bathrooms: String
    @Published var garage: String
    @Published var distance: String
    @Published var floor: String
    @Published var buildYear: String

    @Published var loanTerm: Double = 20
    @Published var downPayment: Double = 20
    @Published var interestRate: Double = 7.5

    @Published private(set) var predictedPrice: Double?
    @Published private(set) var monthlyPayment: Double?
    @Published private(set) var isCalculating = false
    @Published private(set) var errorMessage: String?
    @Published private(set) var history: [MortgageCalculationHistoryItem] = []

    var paymentChartPoints: [MortgagePaymentChartPoint] {
        guard let predictedPrice else {
            return []
        }

        return (5...30).map { term in
            let terms = MortgageTerms(
                downPayment: downPayment,
                loanTerm: Double(term),
                interestRate: interestRate
            )
            let payment = calculator.calculateMonthlyPayment(
                price: predictedPrice,
                terms: terms
            )

            return MortgagePaymentChartPoint(term: term, payment: payment)
        }
    }

    private let calculator: MortgageCalculatorProtocol
    private var calculationWorkItem: DispatchWorkItem?
    private var calculationGeneration = 0

    private static let historyStorageKey = "mortgage_calculation_history"
    private static let maxHistoryItems = 20

    init(
        property: PropertyData? = nil,
        calculator: MortgageCalculatorProtocol = MortgageCalculatorModel()
    ) {
        self.calculator = calculator

        area = property.map { Self.formatInput($0.area) } ?? "75"
        rooms = property.map { Self.formatInput($0.rooms) } ?? "3"
        bathrooms = property.map { Self.formatInput($0.bathrooms) } ?? "2"
        garage = property.map { Self.formatInput($0.garage) } ?? "1"
        distance = property.map { Self.formatInput($0.distance) } ?? "2.5"
        floor = property.map { Self.formatInput($0.floor) } ?? "5"
        buildYear = property.map { Self.formatBuildYear($0.year) } ?? "2010"
        history = Self.loadHistory()
    }

    func debouncedCalculate() {
        calculationWorkItem?.cancel()

        let workItem = DispatchWorkItem { [weak self] in
            self?.calculateFull()
        }

        calculationWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: workItem)
    }

    func propertyCharacteristicsDidChange() {
        calculationGeneration += 1
        predictedPrice = nil
        monthlyPayment = nil
        errorMessage = nil
        isCalculating = true
        debouncedCalculate()
    }

    func calculateFull() {
        let validation = validateInput()

        guard validation.isValid, let property = makePropertyData() else {
            errorMessage = validation.errorMessage
            predictedPrice = nil
            monthlyPayment = nil
            isCalculating = false
            return
        }

        errorMessage = nil
        isCalculating = true

        let terms = makeMortgageTerms()
        let calculator = calculator
        let generation = calculationGeneration

        DispatchQueue.global(qos: .userInitiated).async {
            let price = calculator.predictPrice(property: property)
            let payment = calculator.calculateMonthlyPayment(price: price, terms: terms)

            DispatchQueue.main.async { [weak self] in
                guard self?.calculationGeneration == generation else {
                    return
                }

                self?.predictedPrice = price
                self?.monthlyPayment = payment
                self?.isCalculating = false
            }
        }
    }

    func recalculateMortgageOnly() {
        guard let predictedPrice else {
            debouncedCalculate()
            return
        }

        monthlyPayment = calculator.calculateMonthlyPayment(
            price: predictedPrice,
            terms: makeMortgageTerms()
        )
    }

    func saveCurrentCalculation() {
        guard
            let property = makePropertyData(),
            let predictedPrice,
            let monthlyPayment
        else {
            return
        }

        let item = MortgageCalculationHistoryItem(
            property: property,
            terms: makeMortgageTerms(),
            predictedPrice: predictedPrice,
            monthlyPayment: monthlyPayment
        )

        history.insert(item, at: 0)

        if history.count > Self.maxHistoryItems {
            history = Array(history.prefix(Self.maxHistoryItems))
        }

        saveHistory()
    }

    func deleteHistoryItems(at offsets: IndexSet) {
        for index in offsets.sorted(by: >) {
            history.remove(at: index)
        }

        saveHistory()
    }

    func clearHistory() {
        history.removeAll()
        saveHistory()
    }

    func validateInput() -> (isValid: Bool, errorMessage: String?) {
        let fields: [(String, String)] = [
            (area, "Площадь"),
            (rooms, "Количество комнат"),
            (bathrooms, "Количество санузлов"),
            (garage, "Парковочные места"),
            (distance, "Расстояние до центра"),
            (floor, "Этаж"),
            (buildYear, "Год постройки")
        ]

        for (value, fieldName) in fields {
            guard let number = Self.parse(value), number >= 0 else {
                return (false, "Поле \"\(fieldName)\" должно быть положительным числом")
            }
        }

        if let year = Self.parse(buildYear) {
            let intYear = Int(year)
            if !Self.buildYearRange.contains(intYear) {
                return (
                    false,
                    "Год постройки должен быть между \(Self.buildYearRange.lowerBound) и \(Self.buildYearRange.upperBound)"
                )
            }
        }

        if let areaValue = Self.parse(area), areaValue < 10 || areaValue > 1000 {
            return (false, "Площадь должна быть реалистичной: 10-1000 м²")
        }

        return (true, nil)
    }

    private func makePropertyData() -> PropertyData? {
        guard
            let area = Self.parse(area),
            let rooms = Self.parse(rooms),
            let bathrooms = Self.parse(bathrooms),
            let garage = Self.parse(garage),
            let distance = Self.parse(distance),
            let floor = Self.parse(floor),
            let buildYear = Self.parse(buildYear)
        else {
            return nil
        }

        return PropertyData(
            area: area,
            rooms: rooms,
            bathrooms: bathrooms,
            garage: garage,
            distance: distance,
            floor: floor,
            year: buildYear
        )
    }

    private func makeMortgageTerms() -> MortgageTerms {
        MortgageTerms(
            downPayment: downPayment,
            loanTerm: loanTerm,
            interestRate: interestRate
        )
    }

    private func saveHistory() {
        guard let data = try? JSONEncoder().encode(history) else {
            return
        }

        UserDefaults.standard.set(data, forKey: Self.historyStorageKey)
    }

    private static func loadHistory() -> [MortgageCalculationHistoryItem] {
        guard
            let data = UserDefaults.standard.data(forKey: historyStorageKey),
            let history = try? JSONDecoder().decode([MortgageCalculationHistoryItem].self, from: data)
        else {
            return []
        }

        return Array(history.sorted { $0.date > $1.date }.prefix(maxHistoryItems))
    }

    private static func parse(_ value: String) -> Double? {
        Double(value.replacingOccurrences(of: ",", with: "."))
    }

    private static func formatInput(_ value: Double) -> String {
        value.truncatingRemainder(dividingBy: 1) == 0
        ? String(Int(value))
        : String(value)
    }

    private static func formatBuildYear(_ value: Double) -> String {
        let year = Int(value.rounded())
        let clampedYear = min(
            max(year, buildYearRange.lowerBound),
            buildYearRange.upperBound
        )
        return String(clampedYear)
    }
}
