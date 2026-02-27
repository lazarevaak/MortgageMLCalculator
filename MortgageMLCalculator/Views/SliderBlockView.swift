//
//  SliderBlockView.swift
//  MortgageMLCalculator
//
//  Created by Alexandra Lazareva on 25.02.2026.
//

import UIKit

final class SliderBlockView: UIView {
    
    let label = UILabel()
    let slider = UISlider()
    
    init() {
        super.init(frame: .zero)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError()
    }
    
    private func setupUI() {
        let stack = UIStackView(arrangedSubviews: [label, slider])
        stack.axis = .vertical
        stack.spacing = 6
        stack.layoutMargins = UIEdgeInsets(top: 14, left: 16, bottom: 14, right: 16)
        stack.isLayoutMarginsRelativeArrangement = true
        
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)
        
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: topAnchor),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }
}
