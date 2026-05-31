//
//  MortgageScreen.swift
//  MortgageMLCalculator
//
//  Created by Alexandra Lazareva on 25.02.2026.
//

import SwiftUI
import UIKit

struct MortgageScreen: View {

    @StateObject private var viewModel: MortgageCalculatorViewModel
    @Environment(\.dismiss) private var dismiss

    private let showsCloseButton: Bool

    private static let currencyFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        
        formatter.numberStyle = .currency
        formatter.currencySymbol = "₽"
        formatter.maximumFractionDigits = 0
        formatter.locale = Locale(identifier: "ru_RU")
        formatter.groupingSeparator = " "
        
        return formatter
    }()

    private static let historyDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        
        formatter.locale = Locale(identifier: "ru_RU")
        
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        
        return formatter
    }()

    init(
        property: PropertyData? = nil,
        showsCloseButton: Bool = false
    ) {
        _viewModel = StateObject(
            wrappedValue: MortgageCalculatorViewModel(property: property)
        )
        self.showsCloseButton = showsCloseButton
    }

    var body: some View {
        screen
            .onAppear {
                viewModel.debouncedCalculate()
            }
    }

    private var screen: some View {
        NavigationStack {
            contentForm
            .navigationTitle("Ипотечный калькулятор")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                closeToolbarItem
                keyboardToolbar
            }
        }
    }

    private var contentForm: some View {
        Form {
            propertySection
            mortgageSection
            resultSection
            paymentChartSection
            historySection
        }
    }

    @ToolbarContentBuilder
    private var closeToolbarItem: some ToolbarContent {
        if showsCloseButton {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                }
                .accessibilityLabel("Закрыть")
            }
        }
    }

    @ToolbarContentBuilder
    private var keyboardToolbar: some ToolbarContent {
        ToolbarItemGroup(placement: .keyboard) {
            Spacer()

            Button("Готово") {
                hideKeyboard()
            }
        }
    }

    private var propertySection: some View {
        Section("Характеристики недвижимости") {
            ParameterRow(title: "Площадь", value: $viewModel.area, unit: "м²")
                .onChange(of: viewModel.area) { _, _ in viewModel.propertyCharacteristicsDidChange() }

            ParameterRow(title: "Комнаты", value: $viewModel.rooms, unit: "шт.")
                .onChange(of: viewModel.rooms) { _, _ in viewModel.propertyCharacteristicsDidChange() }

            ParameterRow(title: "Санузлы", value: $viewModel.bathrooms, unit: "шт.")
                .onChange(of: viewModel.bathrooms) { _, _ in viewModel.propertyCharacteristicsDidChange() }

            ParameterRow(title: "Парковочные места", value: $viewModel.garage, unit: "шт.")
                .onChange(of: viewModel.garage) { _, _ in viewModel.propertyCharacteristicsDidChange() }

            ParameterRow(title: "Расстояние до центра", value: $viewModel.distance, unit: "км")
                .onChange(of: viewModel.distance) { _, _ in viewModel.propertyCharacteristicsDidChange() }

            ParameterRow(title: "Этаж", value: $viewModel.floor, unit: "эт.")
                .onChange(of: viewModel.floor) { _, _ in viewModel.propertyCharacteristicsDidChange() }

            Picker("Год постройки", selection: $viewModel.buildYear) {
                ForEach(MortgageCalculatorViewModel.buildYearRange, id: \.self) { year in
                    Text(String(year))
                        .tag(String(year))
                }
            }
            .pickerStyle(.menu)
            .onChange(of: viewModel.buildYear) { _, _ in viewModel.propertyCharacteristicsDidChange() }
        }
    }

    private var mortgageSection: some View {
        Section("Условия ипотеки") {
            sliderBlock(
                title: "Первоначальный взнос: \(Int(viewModel.downPayment))%",
                value: $viewModel.downPayment,
                bounds: 10...50,
                step: 5
            )
            .onChange(of: viewModel.downPayment) { _, _ in viewModel.recalculateMortgageOnly() }

            sliderBlock(
                title: "Срок кредита: \(Int(viewModel.loanTerm)) лет",
                value: $viewModel.loanTerm,
                bounds: 5...30,
                step: 1
            )
            .onChange(of: viewModel.loanTerm) { _, _ in viewModel.recalculateMortgageOnly() }

            sliderBlock(
                title: String(format: "Процентная ставка: %.1f%%", viewModel.interestRate),
                value: $viewModel.interestRate,
                bounds: 3...15,
                step: 0.1
            )
            .onChange(of: viewModel.interestRate) { _, _ in viewModel.recalculateMortgageOnly() }
        }
    }

    private var resultSection: some View {
        Section("Результаты расчета") {
            if viewModel.isCalculating {
                HStack(spacing: 12) {
                    ProgressView()
                    Text("Рассчитываем...")
                        .foregroundStyle(.secondary)
                }
            } else if let errorMessage = viewModel.errorMessage {
                Label(errorMessage, systemImage: "exclamationmark.triangle")
                    .foregroundStyle(.orange)
            } else if let price = viewModel.predictedPrice {
                MortgagePredictionResultView(
                    price: price,
                    monthlyPayment: viewModel.monthlyPayment,
                    downPayment: viewModel.downPayment,
                    loanTerm: viewModel.loanTerm,
                    interestRate: viewModel.interestRate
                )

                Button {
                    viewModel.saveCurrentCalculation()
                } label: {
                    Label("Сохранить расчет", systemImage: "clock.arrow.circlepath")
                }
                .disabled(viewModel.monthlyPayment == nil)
            } else {
                Text("Введите параметры для расчета")
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var paymentChartSection: some View {
        Section("График платежа по сроку") {
            if viewModel.paymentChartPoints.isEmpty {
                Text("График появится после расчета стоимости")
                    .foregroundStyle(.secondary)
            } else {
                MortgagePaymentChartView(
                    points: viewModel.paymentChartPoints,
                    selectedTerm: viewModel.loanTerm
                )
            }
        }
    }

    private var historySection: some View {
        Section("История расчетов") {
            if viewModel.history.isEmpty {
                Text("Сохраненные расчеты появятся здесь")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(viewModel.history) { item in
                    historyRow(item)
                }
                .onDelete { offsets in
                    viewModel.deleteHistoryItems(at: offsets)
                }

                Button(role: .destructive) {
                    viewModel.clearHistory()
                } label: {
                    Label("Очистить историю", systemImage: "trash")
                }
            }
        }
    }

    private func historyRow(_ item: MortgageCalculationHistoryItem) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline) {
                Text(formatCurrency(item.predictedPrice))
                    .font(.headline)
                    .foregroundStyle(.blue)

                Spacer(minLength: 12)

                Text(Self.historyDateFormatter.string(from: item.date))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Text(historyPropertyDescription(item.property))
                .font(.subheadline)
                .foregroundStyle(.secondary)

            HStack {
                Label(formatCurrency(item.monthlyPayment), systemImage: "creditcard")
                    .foregroundStyle(.green)

                Spacer()

                Text("\(Int(item.terms.loanTerm)) лет, \(item.terms.interestRate, specifier: "%.1f")%")
                    .foregroundStyle(.secondary)
            }
            .font(.subheadline)
        }
        .padding(.vertical, 4)
    }

    private func sliderBlock(
        title: String,
        value: Binding<Double>,
        bounds: ClosedRange<Double>,
        step: Double
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
            Slider(value: value, in: bounds, step: step)
        }
        .padding(.vertical, 4)
    }

    private func historyPropertyDescription(_ property: PropertyData) -> String {
        "\(Int(property.area)) м², \(Int(property.rooms)) комн., \(Int(property.year)) г."
    }

    private func formatCurrency(_ value: Double) -> String {
        Self.currencyFormatter.string(from: NSNumber(value: value)) ?? ""
    }

    private func hideKeyboard() {
        UIApplication.shared.sendAction(
            #selector(UIResponder.resignFirstResponder),
            to: nil,
            from: nil,
            for: nil
        )
    }
}

#Preview {
    MortgageScreen()
}
