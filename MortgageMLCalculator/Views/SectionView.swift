//
//  SectionView.swift
//  MortgageMLCalculator
//
//  Created by Alexandra Lazareva on 25.02.2026.
//

import UIKit

final class SectionView: UIView {
    
    // MARK: - Public
    
    let cardStack = UIStackView()
    
    // MARK: - Private
    
    private let titleLabel = UILabel()
    private let containerStack = UIStackView()
    
    // MARK: - Init
    
    init(title: String) {
        super.init(frame: .zero)
        setupUI()
        titleLabel.text = title
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup
    
    private func setupUI() {
        
        containerStack.axis = .vertical
        containerStack.spacing = 8
        containerStack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(containerStack)
        
        NSLayoutConstraint.activate([
            containerStack.topAnchor.constraint(equalTo: topAnchor),
            containerStack.leadingAnchor.constraint(equalTo: leadingAnchor),
            containerStack.trailingAnchor.constraint(equalTo: trailingAnchor),
            containerStack.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
        
        // MARK: - Title
        
        titleLabel.font = .systemFont(ofSize: 14, weight: .medium)
        titleLabel.textColor = .secondaryLabel
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        let titleContainer = UIView()
        titleContainer.translatesAutoresizingMaskIntoConstraints = false
        titleContainer.addSubview(titleLabel)
        
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: titleContainer.topAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: titleContainer.leadingAnchor, constant: 14), 
            titleLabel.trailingAnchor.constraint(equalTo: titleContainer.trailingAnchor, constant: -16),
            titleLabel.bottomAnchor.constraint(equalTo: titleContainer.bottomAnchor)
        ])
        
        // MARK: - Card
        
        cardStack.axis = .vertical
        cardStack.spacing = 0
        cardStack.backgroundColor = .systemBackground
        cardStack.layer.cornerRadius = 18
        cardStack.layer.masksToBounds = true
        
        containerStack.addArrangedSubview(titleContainer)
        containerStack.addArrangedSubview(cardStack)
    }
}
