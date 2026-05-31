//
//  ParameterRow.swift
//  MortgageMLCalculator
//
//  Created by Alexandra Lazareva on 25.02.2026.
//

import SwiftUI

struct ParameterRow: View {

    let title: String
    @Binding var value: String
    let unit: String
    var isEditable = true

    var body: some View {
        HStack {
            Text(title)

            Spacer()

            TextField("", text: $value)
                .multilineTextAlignment(.trailing)
                .frame(width: 80)
                .keyboardType(.decimalPad)
                .disabled(!isEditable)
                .foregroundStyle(isEditable ? .primary : .secondary)

            Text(unit)
                .foregroundStyle(.secondary)
        }
    }
}

#Preview {
    @Previewable @State var value = "75"

    Form {
        ParameterRow(title: "Площадь", value: $value, unit: "м²")
    }
}
