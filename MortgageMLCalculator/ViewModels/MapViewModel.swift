//
//  MapViewModel.swift
//  MortgageMLCalculator
//
//  Created by Alexandra Lazareva on 25.02.2026.
//

import Combine
import Foundation

@MainActor
final class MapViewModel: ObservableObject {

    @Published private(set) var properties: [PropertyObject] = []
    @Published private(set) var errorMessage: String?

    private let repository: PropertyRepository

    init(repository: PropertyRepository? = nil) {
        self.repository = repository ?? PropertyRepository()
    }

    func load() {
        do {
            properties = try repository.loadProperties()
            errorMessage = nil
        } catch {
            properties = []
            errorMessage = "Не удалось загрузить объекты: \(error.localizedDescription)"
        }
    }
}
