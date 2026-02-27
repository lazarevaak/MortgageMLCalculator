//
//  PredictionResultView.swift
//  MortgageMLCalculator
//
//  Created by Alexandra Lazareva on 25.02.2026.
//
import UIKit

final class PredictionResultView: UIView {
    
    // MARK: - UI
    
    private let mainStack = UIStackView()
    
    private let priceTitleLabel = UILabel()
    private let priceValueLabel = UILabel()
    
    private let divider = UIView()
    private let mortgageStack = UIStackView()
    
    // MARK: - Formatter
    
    private static let currencyFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = "₽"
        formatter.maximumFractionDigits = 0
        formatter.locale = Locale(identifier: "ru_RU")
        formatter.groupingSeparator = " "
        return formatter
    }()
    
    // MARK: - Init
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Configure
    
    func configure(
        price: Double,
        monthlyPayment: Double?,
        downPayment: Double,
        loanTerm: Double,
        interestRate: Double
    ) {
        priceValueLabel.text = formatCurrency(price)
        
        mortgageStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        
        guard let payment = monthlyPayment else {
            divider.isHidden = true
            mortgageStack.isHidden = true
            return
        }
        
        divider.isHidden = false
        mortgageStack.isHidden = false
        
        let creditAmount = price * (100 - downPayment) / 100
        let totalPayment = payment * loanTerm * 12
        let overpayment = totalPayment - creditAmount
        let overpaymentPercent = creditAmount > 0
        ? (overpayment / creditAmount) * 100
        : 0
        
        mortgageStack.addArrangedSubview(makeSectionTitle("Ипотечный расчет"))
        mortgageStack.addArrangedSubview(makeRow(
            title: "Первоначальный взнос:",
            value: "\(Int(downPayment))%"
        ))
        
        mortgageStack.addArrangedSubview(makeRow(
            title: "Сумма кредита:",
            value: formatCurrency(creditAmount)
        ))
        
        mortgageStack.addArrangedSubview(makeRow(
            title: "Ежемесячный платеж:",
            value: formatCurrency(payment),
            valueColor: .systemGreen,
            bold: true
        ))
        
        mortgageStack.addArrangedSubview(makeRow(
            title: "Переплата за \(Int(loanTerm)) лет:",
            value: formatCurrency(overpayment),
            valueColor: .systemRed
        ))
        
        if creditAmount > 0 {
            mortgageStack.addArrangedSubview(makeRow(
                title: "Переплата:",
                value: String(format: "%.1f%%", overpaymentPercent),
                valueColor: .systemOrange,
                font: .systemFont(ofSize: 13)
            ))
        }
    }
    
    // MARK: - Setup
    
    private func setupUI() {
        
        // Карточка
        backgroundColor = .systemBackground
        layer.cornerRadius = 16
        layer.masksToBounds = true
        
        mainStack.axis = .vertical
        mainStack.spacing = 16
        mainStack.isLayoutMarginsRelativeArrangement = true
        mainStack.layoutMargins = UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)
        
        addSubview(mainStack)
        mainStack.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            mainStack.topAnchor.constraint(equalTo: topAnchor),
            mainStack.bottomAnchor.constraint(equalTo: bottomAnchor),
            mainStack.leadingAnchor.constraint(equalTo: leadingAnchor),
            mainStack.trailingAnchor.constraint(equalTo: trailingAnchor)
        ])
        
        priceTitleLabel.text = "Прогнозируемая стоимость"
        priceTitleLabel.font = .systemFont(ofSize: 13)
        priceTitleLabel.textColor = .secondaryLabel
        
        priceValueLabel.font = .boldSystemFont(ofSize: 24)
        priceValueLabel.textColor = .systemBlue
        
        let priceStack = UIStackView(arrangedSubviews: [
            priceTitleLabel,
            priceValueLabel
        ])
        priceStack.axis = .vertical
        priceStack.spacing = 6
        
        mainStack.addArrangedSubview(priceStack)
        
        divider.backgroundColor = .separator
        divider.heightAnchor.constraint(equalToConstant: 0.5).isActive = true
        mainStack.addArrangedSubview(divider)
        
        mortgageStack.axis = .vertical
        mortgageStack.spacing = 12
        mainStack.addArrangedSubview(mortgageStack)
    }
    
    // MARK: - Row Builders
    
    private func makeSectionTitle(_ text: String) -> UILabel {
        let label = UILabel()
        label.text = text
        label.font = .systemFont(ofSize: 13)
        label.textColor = .secondaryLabel
        return label
    }
    
    private func makeRow(
        title: String,
        value: String,
        valueColor: UIColor = .label,
        bold: Bool = false,
        font: UIFont? = nil
    ) -> UIView {
        
        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = .systemFont(ofSize: 15)
        titleLabel.textColor = .secondaryLabel
        
        let valueLabel = UILabel()
        valueLabel.text = value
        valueLabel.textAlignment = .right
        valueLabel.textColor = valueColor
        
        if let font = font {
            valueLabel.font = font
        } else if bold {
            valueLabel.font = .boldSystemFont(ofSize: 16)
        } else {
            valueLabel.font = .systemFont(ofSize: 15)
        }
        
        let stack = UIStackView(arrangedSubviews: [
            titleLabel,
            UIView(),
            valueLabel
        ])
        stack.axis = .horizontal
        
        return stack
    }
    
    private func formatCurrency(_ value: Double) -> String {
        return Self.currencyFormatter.string(from: NSNumber(value: value)) ?? ""
    }
}
