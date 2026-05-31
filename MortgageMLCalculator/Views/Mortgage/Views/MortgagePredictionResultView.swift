//
//  MortgagePredictionResultView.swift
//  MortgageMLCalculator
//
//  Created by Alexandra Lazareva on 25.02.2026.
//

import SwiftUI

struct MortgagePredictionResultView: View {

    let price: Double
    let monthlyPayment: Double?
    let downPayment: Double
    let loanTerm: Double
    let interestRate: Double

    private static let priceFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = "₽"
        formatter.maximumFractionDigits = 0
        formatter.locale = Locale(identifier: "ru_RU")
        formatter.groupingSeparator = " "
        return formatter
    }()

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Прогнозируемая стоимость")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text(formatCurrency(price))
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(.blue)
            }

            if let monthlyPayment {
                Divider()

                VStack(alignment: .leading, spacing: 10) {
                    Text("Ипотечный расчет")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    resultRow(title: "Первоначальный взнос:", value: "\(Int(downPayment))%")
                    resultRow(title: "Сумма кредита:", value: formatCurrency(creditAmount))
                    resultRow(
                        title: "Ежемесячный платеж:",
                        value: formatCurrency(monthlyPayment),
                        valueColor: .green,
                        isHighlighted: true
                    )
                    resultRow(
                        title: "Переплата за \(Int(loanTerm)) лет:",
                        value: formatCurrency(overpayment(monthlyPayment)),
                        valueColor: .red
                    )

                    if creditAmount > 0 {
                        resultRow(
                            title: "Переплата:",
                            value: String(format: "%.1f%%", overpaymentPercent(monthlyPayment)),
                            valueColor: .orange
                        )
                    }
                }
            }
        }
        .padding(.vertical, 8)
    }

    private var creditAmount: Double {
        price * (100 - downPayment) / 100
    }

    private func overpayment(_ payment: Double) -> Double {
        payment * loanTerm * 12 - creditAmount
    }

    private func overpaymentPercent(_ payment: Double) -> Double {
        overpayment(payment) / creditAmount * 100
    }

    private func resultRow(
        title: String,
        value: String,
        valueColor: Color = .primary,
        isHighlighted: Bool = false
    ) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title)
                .foregroundStyle(.secondary)

            Spacer(minLength: 12)

            Text(value)
                .font(isHighlighted ? .headline : .body)
                .fontWeight(isHighlighted ? .bold : .medium)
                .foregroundStyle(valueColor)
                .multilineTextAlignment(.trailing)
        }
    }

    private func formatCurrency(_ value: Double) -> String {
        Self.priceFormatter.string(from: NSNumber(value: value)) ?? ""
    }
}

#Preview {
    Form {
        MortgagePredictionResultView(
            price: 5_500_000,
            monthlyPayment: 35_420,
            downPayment: 20,
            loanTerm: 20,
            interestRate: 7.5
        )
    }
}
