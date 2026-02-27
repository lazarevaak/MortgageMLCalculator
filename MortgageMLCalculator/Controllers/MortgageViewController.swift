//
//  MortgageViewController.swift
//  MortgageMLCalculator
//
//  Created by Alexandra Lazareva on 25.02.2026.
//

import UIKit

final class MortgageViewController: UIViewController {
    
    private let viewModel: MortgageViewModel
    
    init(viewModel: MortgageViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - UI
    
    private let scrollView = UIScrollView()
    private let contentStack = UIStackView()
    
    private let areaRow = ParameterRowView(title: "Площадь", unit: "м²")
    private let roomsRow = ParameterRowView(title: "Комнаты", unit: "шт.")
    private let bathroomsRow = ParameterRowView(title: "Санузлы", unit: "шт.")
    private let garageRow = ParameterRowView(title: "Парковочные места", unit: "шт.")
    private let distanceRow = ParameterRowView(title: "Расстояние", unit: "км")
    private let floorRow = ParameterRowView(title: "Этаж", unit: "эт.")
    private let buildYearRow = ParameterRowView(title: "Год постройки", unit: "год")
    
    private let downPaymentSlider = UISlider()
    private let loanTermSlider = UISlider()
    private let interestRateSlider = UISlider()
    
    private let downPaymentLabel = UILabel()
    private let loanTermLabel = UILabel()
    private let interestRateLabel = UILabel()
    
    private let resultView = PredictionResultView()
    private let activityIndicator = UIActivityIndicatorView(style: .medium)
    private let placeholderLabel = UILabel()
    
    private var calculationWorkItem: DispatchWorkItem?
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Ипотечный калькулятор"
        view.backgroundColor = .systemGroupedBackground
        
        setupUI()
        prefillPropertyData()
        setupActions()
        buildYearRow.setSeparatorHidden(true)
        
        debouncedCalculate()
    }
}

// MARK: - Prefill

private extension MortgageViewController {
    
    func prefillPropertyData() {
        let property = viewModel.property
        
        areaRow.value = String(property.area)
        roomsRow.value = String(property.rooms)
        floorRow.value = String(property.floor)
        buildYearRow.value = String(property.buildYear)
    }
}


// MARK: - UI Setup

private extension MortgageViewController {
    
    func setupUI() {
        
        scrollView.keyboardDismissMode = .interactive
        view.addSubview(scrollView)
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
        
        contentStack.axis = .vertical
        contentStack.spacing = 32
        
        scrollView.addSubview(contentStack)
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            contentStack.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 16),
            contentStack.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentStack.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: 16),
            contentStack.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -16),
            contentStack.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -32)
        ])
        
        addPropertySection()
        addMortgageSection()
        addResultSection()
    }
    
    func addPropertySection() {
        let section = SectionView(title: "Характеристики недвижимости")
        
        [
            areaRow, roomsRow, bathroomsRow,
            garageRow, distanceRow,
            floorRow, buildYearRow
        ].forEach { section.cardStack.addArrangedSubview($0) }
        
        contentStack.addArrangedSubview(section)
    }
    
    func addMortgageSection() {
        
        let section = SectionView(title: "Условия ипотеки")
        
        configureSlider(downPaymentSlider, min: 10, max: 50, value: 20)
        configureSlider(loanTermSlider, min: 5, max: 30, value: 20)
        configureSlider(interestRateSlider, min: 3, max: 15, value: 7.5)
        
        updateSliderLabels()
        
        [createSliderBlock(label: downPaymentLabel, slider: downPaymentSlider),
         createSliderBlock(label: loanTermLabel, slider: loanTermSlider),
         createSliderBlock(label: interestRateLabel, slider: interestRateSlider)
        ].forEach { section.cardStack.addArrangedSubview($0) }
        
        contentStack.addArrangedSubview(section)
    }
    
    func addResultSection() {
        
        let section = SectionView(title: "Результаты расчета")
        
        placeholderLabel.text = "Введите параметры для расчета"
        placeholderLabel.textColor = .secondaryLabel
        
        section.cardStack.addArrangedSubview(activityIndicator)
        section.cardStack.addArrangedSubview(placeholderLabel)
        section.cardStack.addArrangedSubview(resultView)
        
        resultView.isHidden = true
        activityIndicator.isHidden = true
        
        contentStack.addArrangedSubview(section)
    }
    
    func createSliderBlock(label: UILabel, slider: UISlider) -> SliderBlockView {
        let block = SliderBlockView()
        block.label.text = label.text
        block.slider.minimumValue = slider.minimumValue
        block.slider.maximumValue = slider.maximumValue
        block.slider.value = slider.value
        block.slider.addTarget(self, action: #selector(sliderChanged), for: .valueChanged)
        return block
    }
}

// MARK: - Actions

private extension MortgageViewController {
    
    func setupActions() {
        [
            areaRow, roomsRow, bathroomsRow,
            garageRow, distanceRow,
            floorRow, buildYearRow
        ].forEach {
            $0.addTarget(self, action: #selector(inputChanged), for: .editingChanged)
        }
        
        [downPaymentSlider, loanTermSlider, interestRateSlider].forEach {
            $0.addTarget(self, action: #selector(sliderChanged), for: .valueChanged)
        }
    }
    
    @objc func inputChanged() {
        debouncedCalculate()
    }
    
    @objc func sliderChanged() {
        updateSliderLabels()
        debouncedCalculate()
    }
    
    func updateSliderLabels() {
        downPaymentLabel.text = "Первоначальный взнос: \(Int(downPaymentSlider.value))%"
        loanTermLabel.text = "Срок кредита: \(Int(loanTermSlider.value)) лет"
        interestRateLabel.text = String(format: "Процентная ставка: %.1f%%", interestRateSlider.value)
    }
    
    func configureSlider(_ slider: UISlider, min: Float, max: Float, value: Float) {
        slider.minimumValue = min
        slider.maximumValue = max
        slider.value = value
    }
}

// MARK: - Calculation

private extension MortgageViewController {
    
    func debouncedCalculate() {
        calculationWorkItem?.cancel()
        
        let workItem = DispatchWorkItem { [weak self] in
            self?.calculateFull()
        }
        
        calculationWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: workItem)
    }
    
    func calculateFull() {
        
        showLoading()
        
        guard let propertyData = PropertyData(
            area: areaRow.value,
            rooms: roomsRow.value,
            bathrooms: bathroomsRow.value,
            garage: garageRow.value,
            distance: distanceRow.value,
            floor: floorRow.value,
            year: buildYearRow.value
        ) else {
            showResult()
            return
        }
        
        let mortgage = MortgageTerms(
            downPayment: Double(downPaymentSlider.value),
            loanTerm: Double(loanTermSlider.value),
            interestRate: Double(interestRateSlider.value)
        )
        
        let input = MortgageViewModel.Input(
            property: propertyData,
            mortgage: mortgage
        )
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self else { return }
            
            let output = self.viewModel.calculate(input: input)
            
            DispatchQueue.main.async { [weak self] in
                guard let self else { return }
                
                self.resultView.configure(
                    price: output.price,
                    monthlyPayment: output.monthlyPayment,
                    downPayment: mortgage.downPayment,
                    loanTerm: mortgage.loanTerm,
                    interestRate: mortgage.interestRate
                )
                
                self.showResult()
            }
        }
    }
    
    func showLoading() {
        activityIndicator.isHidden = false
        activityIndicator.startAnimating()
        resultView.isHidden = true
        placeholderLabel.isHidden = true
    }
    
    func showResult() {
        activityIndicator.stopAnimating()
        activityIndicator.isHidden = true
        resultView.isHidden = false
    }
}
