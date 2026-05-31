//
//  MortgagePaymentChartView.swift
//  MortgageMLCalculator
//
//  Created by Alexandra Lazareva on 25.02.2026.
//

import Charts
import SwiftUI

struct MortgagePaymentChartView: View {
    let points: [MortgagePaymentChartPoint]
    let selectedTerm: Double

    private var selectedPoint: MortgagePaymentChartPoint? {
        points.first { $0.term == Int(selectedTerm) }
    }

    private var paymentRange: ClosedRange<Double> {
        guard
            let minPayment = points.map(\.payment).min(),
            let maxPayment = points.map(\.payment).max()
        else {
            return 0...1
        }

        let padding = max((maxPayment - minPayment) * 0.12, 1)
        return max(0, minPayment - padding)...(maxPayment + padding)
    }

    var body: some View {
        content
            .padding(.vertical, 8)
    }

    private var content: some View {
        VStack(alignment: .leading, spacing: 12) {
            selectedPaymentHeader
            paymentChart
        }
    }

    @ViewBuilder
    private var selectedPaymentHeader: some View {
        if let selectedPoint {
            VStack(alignment: .leading, spacing: 4) {
                Text("Платеж при текущем сроке")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(Self.currencyFormatter.string(from: NSNumber(value: selectedPoint.payment)) ?? "")
                    .font(.headline)
                    .foregroundStyle(.green)
            }
        }
    }

    private var paymentChart: some View {
        Chart(points) { point in
            paymentMarks(for: point)
        }
        .chartXScale(domain: 5...30)
        .chartYScale(domain: paymentRange)
        .chartXAxis { xAxisMarks }
        .chartYAxis { yAxisMarks }
        .frame(height: 220)
    }

    @ChartContentBuilder
    private func paymentMarks(for point: MortgagePaymentChartPoint) -> some ChartContent {
        LineMark(
            x: .value("Срок", point.term),
            y: .value("Платеж", point.payment)
        )
        .foregroundStyle(.blue)
        .interpolationMethod(.catmullRom)

        AreaMark(
            x: .value("Срок", point.term),
            y: .value("Платеж", point.payment)
        )
        .foregroundStyle(.blue.opacity(0.12))
        .interpolationMethod(.catmullRom)

        if point.term == Int(selectedTerm) {
            selectedTermMarks(for: point)
        }
    }

    @ChartContentBuilder
    private func selectedTermMarks(for point: MortgagePaymentChartPoint) -> some ChartContent {
        PointMark(
            x: .value("Срок", point.term),
            y: .value("Платеж", point.payment)
        )
        .foregroundStyle(.green)
        .symbolSize(80)

        RuleMark(x: .value("Текущий срок", point.term))
            .foregroundStyle(.green.opacity(0.45))
            .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
    }

    private var xAxisMarks: some AxisContent {
        AxisMarks(values: [5, 10, 15, 20, 25, 30]) { value in
            AxisGridLine()
            AxisTick()
            AxisValueLabel {
                if let term = value.as(Int.self) {
                    Text("\(term) л.")
                }
            }
        }
    }

    private var yAxisMarks: some AxisContent {
        AxisMarks(position: .leading) { value in
            AxisGridLine()
            AxisTick()
            AxisValueLabel {
                if let payment = value.as(Double.self) {
                    Text(Self.compactCurrency(payment))
                }
            }
        }
    }

    private static let currencyFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = "₽"
        formatter.maximumFractionDigits = 0
        formatter.locale = Locale(identifier: "ru_RU")
        formatter.groupingSeparator = " "
        return formatter
    }()

    private static func compactCurrency(_ value: Double) -> String {
        if value >= 1_000_000 {
            return String(format: "%.1f млн ₽", value / 1_000_000)
        }

        return "\(Int(value / 1_000)) тыс. ₽"
    }
}
