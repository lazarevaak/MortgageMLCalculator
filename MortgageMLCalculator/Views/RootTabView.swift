//
//  RootTabView.swift
//  MortgageMLCalculator
//

import SwiftUI

struct RootTabView: View {
    var body: some View {
        TabView {
            MapScreen()
                .tabItem {
                    Label("Расчет", systemImage: "house")
                }

            MortgageComparisonScreen()
                .tabItem {
                    Label("Сравнение", systemImage: "rectangle.split.2x1")
                }
        }
    }
}

#Preview {
    RootTabView()
}
