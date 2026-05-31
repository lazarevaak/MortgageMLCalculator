//
//  MortgageComparisonScreen.swift
//  MortgageMLCalculator
//

import MapKit
import SwiftUI

private enum PropertySelectionTarget: String, Identifiable {
    case first
    case second

    var id: String { rawValue }

    var title: String {
        switch self {
        case .first:
            return "Первый вариант"
        case .second:
            return "Второй вариант"
        }
    }
}

private struct MortgageComparisonResult {
    let predictedPrice: Double
    let monthlyPayment: Double
    let loanAmount: Double
    let overpayment: Double
}

struct MortgageComparisonScreen: View {
    @StateObject private var viewModel = MapViewModel()
    @State private var firstPropertyID = ""
    @State private var secondPropertyID = ""
    @State private var loanTerm: Double = 20
    @State private var downPayment: Double = 20
    @State private var interestRate: Double = 7.5
    @State private var firstComparisonResult: MortgageComparisonResult?
    @State private var secondComparisonResult: MortgageComparisonResult?
    @State private var isComparisonCalculating = false
    @State private var comparisonWorkItem: DispatchWorkItem?
    @State private var comparisonGeneration = 0
    @State private var activeSelectionTarget: PropertySelectionTarget?

    private static let currencyFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = "₽"
        formatter.maximumFractionDigits = 0
        formatter.locale = Locale(identifier: "ru_RU")
        formatter.groupingSeparator = " "
        return formatter
    }()

    var body: some View {
        NavigationStack {
            content
                .navigationTitle("Сравнение")
                .navigationBarTitleDisplayMode(.inline)
                .onAppear {
                    loadPropertiesIfNeeded()
                }
                .onChange(of: firstPropertyID) { _, _ in
                    scheduleComparisonCalculation()
                }
                .onChange(of: secondPropertyID) { _, _ in
                    scheduleComparisonCalculation()
                }
                .onChange(of: loanTerm) { _, _ in
                    scheduleComparisonCalculation()
                }
                .onChange(of: downPayment) { _, _ in
                    scheduleComparisonCalculation()
                }
                .onChange(of: interestRate) { _, _ in
                    scheduleComparisonCalculation()
                }
                .sheet(item: $activeSelectionTarget) { target in
                    propertySelectionSheet(for: target)
                }
        }
    }

    private var content: some View {
        Form {
            propertySelectionSection
            mortgageTermsSection
            comparisonSection
        }
    }

    private var propertySelectionSection: some View {
        Section("Объекты недвижимости") {
            propertyPicker(
                title: "Первый вариант",
                selection: $firstPropertyID,
                target: .first
            )

            propertyPicker(
                title: "Второй вариант",
                selection: $secondPropertyID,
                target: .second
            )

            if firstPropertyID == secondPropertyID, !firstPropertyID.isEmpty {
                Label("Выберите разные квартиры для сравнения", systemImage: "exclamationmark.triangle")
                    .foregroundStyle(.orange)
            }
        }
    }

    private var mortgageTermsSection: some View {
        Section("Условия ипотеки") {
            sliderBlock(
                title: "Первоначальный взнос: \(Int(downPayment))%",
                value: $downPayment,
                bounds: 10...50,
                step: 5
            )

            sliderBlock(
                title: "Срок кредита: \(Int(loanTerm)) лет",
                value: $loanTerm,
                bounds: 5...30,
                step: 1
            )

            sliderBlock(
                title: String(format: "Процентная ставка: %.1f%%", interestRate),
                value: $interestRate,
                bounds: 3...15,
                step: 0.1
            )
        }
    }

    private var comparisonSection: some View {
        Section("Сравнение") {
            if let errorMessage = viewModel.errorMessage {
                Label(errorMessage, systemImage: "exclamationmark.triangle")
                    .foregroundStyle(.orange)
            } else if let firstProperty, let secondProperty {
                if isComparisonCalculating && (firstComparisonResult == nil || secondComparisonResult == nil) {
                    HStack {
                        ProgressView()
                        Text("Рассчитываем...")
                            .foregroundStyle(.secondary)
                    }
                }

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(alignment: .top, spacing: 12) {
                        comparisonCard(
                            title: "Вариант 1",
                            property: firstProperty,
                            result: firstComparisonResult
                        )

                        comparisonCard(
                            title: "Вариант 2",
                            property: secondProperty,
                            result: secondComparisonResult
                        )
                    }
                    .padding(.vertical, 4)
                    .opacity(isComparisonCalculating ? 0.7 : 1)
                }
            } else {
                Text("Выберите две квартиры для сравнения")
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var firstProperty: PropertyObject? {
        viewModel.properties.first { $0.id == firstPropertyID }
    }

    private var secondProperty: PropertyObject? {
        viewModel.properties.first { $0.id == secondPropertyID }
    }

    private var terms: MortgageTerms {
        MortgageTerms(
            downPayment: downPayment,
            loanTerm: loanTerm,
            interestRate: interestRate
        )
    }

    private func propertyPicker(
        title: String,
        selection: Binding<String>,
        target: PropertySelectionTarget
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.subheadline)
                .foregroundStyle(.primary)

            Button {
                activeSelectionTarget = target
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "house")
                        .font(.system(size: 26, weight: .medium))
                        .foregroundStyle(.blue)

                    Text(selectedPropertyAddress(for: selection.wrappedValue))
                        .lineLimit(1)
                        .truncationMode(.tail)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    if let area = selectedPropertyArea(for: selection.wrappedValue) {
                        Text("\(Int(area)) м²")
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }

                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 4)
    }

    private func comparisonCard(
        title: String,
        property: PropertyObject,
        result: MortgageComparisonResult?
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(title, systemImage: "house.fill")
                .font(.headline)
                .foregroundStyle(.blue)

            Text(property.address)
                .font(.subheadline)
                .fontWeight(.medium)
                .lineLimit(3)

            Divider()

            if let result {
                comparisonRow("Прогноз", formatCurrency(result.predictedPrice), color: .blue)
                comparisonRow("Платеж", formatCurrency(result.monthlyPayment), color: .green)
                comparisonRow("Сумма кредита", formatCurrency(result.loanAmount))
                comparisonRow("Переплата", formatCurrency(result.overpayment), color: .red)
            } else {
                HStack {
                    ProgressView()
                    Text("Расчет...")
                        .foregroundStyle(.secondary)
                }
                .frame(minHeight: 112, alignment: .leading)
            }

            Divider()

            comparisonRow("Площадь", "\(formatNumber(property.area)) м²")
            comparisonRow("Комнаты", "\(Int(property.rooms))")
            comparisonRow("Этаж", "\(Int(property.floor))")
            comparisonRow("Год", "\(Int(property.buildYear))")
            comparisonRow("Метро", property.metro)
        }
        .padding(12)
        .frame(width: 260, alignment: .topLeading)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))
    }

    private func propertySelectionSheet(for target: PropertySelectionTarget) -> some View {
        PropertySelectionSheet(
            title: target.title,
            properties: viewModel.properties,
            selection: selectionBinding(for: target)
        ) {
            activeSelectionTarget = nil
        }
    }

    private func comparisonRow(
        _ title: String,
        _ value: String,
        color: Color = .primary
    ) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)

            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(color)
                .lineLimit(2)
        }
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

    private func loadPropertiesIfNeeded() {
        guard viewModel.properties.isEmpty else {
            setDefaultSelectionIfNeeded()
            return
        }

        viewModel.load()
        setDefaultSelectionIfNeeded()
    }

    private func setDefaultSelectionIfNeeded() {
        guard !viewModel.properties.isEmpty else {
            return
        }

        if firstPropertyID.isEmpty {
            firstPropertyID = viewModel.properties[0].id
        }

        if secondPropertyID.isEmpty {
            secondPropertyID = viewModel.properties.count > 1
            ? viewModel.properties[1].id
            : viewModel.properties[0].id
        }

        scheduleComparisonCalculation()
    }

    private func scheduleComparisonCalculation() {
        comparisonWorkItem?.cancel()

        let workItem = DispatchWorkItem {
            calculateComparison()
        }

        comparisonWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15, execute: workItem)
    }

    private func calculateComparison() {
        guard let firstProperty, let secondProperty else {
            firstComparisonResult = nil
            secondComparisonResult = nil
            isComparisonCalculating = false
            return
        }

        let firstData = PropertyData(property: firstProperty)
        let secondData = PropertyData(property: secondProperty)
        let currentTerms = terms

        comparisonGeneration += 1
        let generation = comparisonGeneration
        isComparisonCalculating = true

        DispatchQueue.global(qos: .userInitiated).async {
            let calculator: MortgageCalculatorProtocol = MortgageCalculatorModel()
            let firstResult = makeComparisonResult(
                property: firstData,
                terms: currentTerms,
                calculator: calculator
            )
            let secondResult = makeComparisonResult(
                property: secondData,
                terms: currentTerms,
                calculator: calculator
            )

            DispatchQueue.main.async {
                guard generation == comparisonGeneration else {
                    return
                }

                firstComparisonResult = firstResult
                secondComparisonResult = secondResult
                isComparisonCalculating = false
            }
        }
    }

    private func setProperty(_ propertyID: String, for target: PropertySelectionTarget) {
        switch target {
        case .first:
            firstPropertyID = propertyID
        case .second:
            secondPropertyID = propertyID
        }
    }

    private func selectionBinding(for target: PropertySelectionTarget) -> Binding<String> {
        switch target {
        case .first:
            return $firstPropertyID
        case .second:
            return $secondPropertyID
        }
    }

    private func selectedPropertyAddress(for id: String) -> String {
        guard let property = viewModel.properties.first(where: { $0.id == id }) else {
            return "Выберите квартиру"
        }

        return property.address
    }

    private func selectedPropertyArea(for id: String) -> Double? {
        viewModel.properties.first(where: { $0.id == id })?.area
    }

    private func formatCurrency(_ value: Double) -> String {
        Self.currencyFormatter.string(from: NSNumber(value: value)) ?? ""
    }

    private func formatNumber(_ value: Double) -> String {
        value.truncatingRemainder(dividingBy: 1) == 0
        ? String(Int(value))
        : String(format: "%.1f", value)
    }
}

private struct PropertySelectionSheet: View {
    let title: String
    let properties: [PropertyObject]
    @Binding var selection: String
    let onClose: () -> Void

    @State private var mapSelection: String?
    @State private var cameraPosition: MapCameraPosition

    init(
        title: String,
        properties: [PropertyObject],
        selection: Binding<String>,
        onClose: @escaping () -> Void
    ) {
        self.title = title
        self.properties = properties
        self._selection = selection
        self.onClose = onClose

        let selectedProperty = properties.first { $0.id == selection.wrappedValue }
        self._mapSelection = State(initialValue: selectedProperty?.id)
        self._cameraPosition = State(initialValue: .region(Self.region(for: selectedProperty)))
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                propertyMap
                    .frame(height: 260)

                List(properties, id: \.id) { property in
                    Button {
                        selection = property.id
                        onClose()
                    } label: {
                        propertyRow(property)
                    }
                }
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Закрыть", action: onClose)
                }
            }
            .onChange(of: mapSelection) { _, id in
                guard
                    let id,
                    let property = properties.first(where: { $0.id == id })
                else { return }

                selection = id
                focusCamera(on: property)
            }
        }
    }

    private var propertyMap: some View {
        Map(position: $cameraPosition, selection: $mapSelection) {
            ForEach(properties, id: \.id) { property in
                Annotation(
                    "\(Int(property.area)) м²",
                    coordinate: CLLocationCoordinate2D(
                        latitude: property.latitude,
                        longitude: property.longitude
                    )
                ) {
                    propertyMarker(for: property)
                }
                .tag(property.id)
            }
        }
        .mapControls {
            MapCompass()
            MapScaleView()
        }
    }

    private func propertyRow(_ property: PropertyObject) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "house.fill")
                .foregroundStyle(.blue)

            VStack(alignment: .leading, spacing: 2) {
                Text(property.address)
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .truncationMode(.tail)

                Text("\(Int(property.area)) м²")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if selection == property.id {
                Image(systemName: "checkmark")
                    .foregroundStyle(.blue)
            }
        }
    }

    private func propertyMarker(for property: PropertyObject) -> some View {
        VStack(spacing: 3) {
            Image(systemName: selection == property.id ? "house.fill" : "house")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 34, height: 34)
                .background(selection == property.id ? .blue : .gray, in: Circle())
                .shadow(radius: 3, y: 2)

            Text("\(Int(property.area)) м²")
                .font(.caption2)
                .fontWeight(.semibold)
                .foregroundStyle(.primary)
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 6))
        }
    }

    private func focusCamera(on property: PropertyObject) {
        cameraPosition = .region(Self.region(for: property))
    }

    private static func region(for property: PropertyObject?) -> MKCoordinateRegion {
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(
                latitude: property?.latitude ?? 55.751244,
                longitude: property?.longitude ?? 37.618423
            ),
            span: MKCoordinateSpan(latitudeDelta: 0.04, longitudeDelta: 0.04)
        )
    }
}

private func makeComparisonResult(
    property: PropertyData,
    terms: MortgageTerms,
    calculator: MortgageCalculatorProtocol
) -> MortgageComparisonResult {
    let predictedPrice = calculator.predictPrice(property: property)
    let monthlyPayment = calculator.calculateMonthlyPayment(
        price: predictedPrice,
        terms: terms
    )
    let loanAmount = predictedPrice * (100 - terms.downPayment) / 100
    let totalPayment = monthlyPayment * terms.loanTerm * 12

    return MortgageComparisonResult(
        predictedPrice: predictedPrice,
        monthlyPayment: monthlyPayment,
        loanAmount: loanAmount,
        overpayment: totalPayment - loanAmount
    )
}

#Preview {
    MortgageComparisonScreen()
}
