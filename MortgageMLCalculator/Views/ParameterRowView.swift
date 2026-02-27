//
//  ParameterRowView.swift
//  MortgageMLCalculator
//
//  Created by Alexandra Lazareva on 25.02.2026.
//

import UIKit

final class ParameterRowView: UIView {
    
    // MARK: - UI
    
    private let titleLabel = UILabel()
    private let textField = UITextField()
    private let unitLabel = UILabel()
    private let separator = UIView()
    
    private let stackView = UIStackView()
    private let valueStack = UIStackView()
    
    // MARK: - Init
    
    init(title: String, unit: String) {
        super.init(frame: .zero)
        setupUI()
        titleLabel.text = title
        unitLabel.text = unit
    }
    
    required init?(coder: NSCoder) {
        fatalError()
    }
    
    // MARK: - Public API
    
    var value: String {
        get { textField.text ?? "" }
        set { textField.text = newValue }
    }
    
    func addTarget(_ target: Any?, action: Selector, for events: UIControl.Event) {
        textField.addTarget(target, action: action, for: events)
    }
    
    func setSeparatorHidden(_ hidden: Bool) {
        separator.isHidden = hidden
    }
    
    // MARK: - Setup
    
    private func setupUI() {
        
        titleLabel.font = .systemFont(ofSize: 17)
        
        unitLabel.font = .systemFont(ofSize: 17)
        unitLabel.textColor = .secondaryLabel
        unitLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        
        // TextField
        textField.keyboardType = .decimalPad
        textField.textAlignment = .right
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.widthAnchor.constraint(equalToConstant: 70).isActive = true
        textField.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        
        valueStack.axis = .horizontal 
        valueStack.spacing = 4
        valueStack.alignment = .center
        valueStack.addArrangedSubview(textField)
        valueStack.addArrangedSubview(unitLabel)
        
        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.spacing = 8
        
        stackView.addArrangedSubview(titleLabel)
        stackView.addArrangedSubview(UIView())
        stackView.addArrangedSubview(valueStack)
        
        stackView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stackView)
        
        separator.backgroundColor = .separator
        separator.translatesAutoresizingMaskIntoConstraints = false
        addSubview(separator)
        
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: topAnchor, constant: 16),
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            
            separator.topAnchor.constraint(equalTo: stackView.bottomAnchor, constant: 16),
            separator.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            separator.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            separator.heightAnchor.constraint(equalToConstant: 0.5),
            separator.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }
}
