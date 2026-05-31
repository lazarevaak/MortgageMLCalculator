//
//  UserLocationManager.swift
//  MortgageMLCalculator
//
//  Created by Alexandra Lazareva on 25.02.2026.
//

import Combine
import CoreLocation
import Foundation

@MainActor
final class UserLocationManager: NSObject, ObservableObject {
    @Published private(set) var coordinate: CLLocationCoordinate2D?
    @Published private(set) var errorMessage: String?
    @Published private(set) var authorizationStatus: CLAuthorizationStatus

    private let manager: CLLocationManager

    override init() {
        let manager = CLLocationManager()
        self.manager = manager
        self.authorizationStatus = manager.authorizationStatus

        super.init()

        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.distanceFilter = kCLDistanceFilterNone
    }

    func requestCurrentLocation() {
        let status = manager.authorizationStatus
        authorizationStatus = status
        handleAuthorizationStatus(status)
    }

    private func handleAuthorizationStatus(_ status: CLAuthorizationStatus) {
        switch status {
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        case .authorizedAlways, .authorizedWhenInUse:
            requestPreciseLocationIfNeeded()
            manager.requestLocation()
        case .denied, .restricted:
            errorMessage = "Разрешите доступ к геолокации в настройках iOS"
        @unknown default:
            errorMessage = "Неизвестный статус доступа к геолокации"
        }
    }

    private func requestPreciseLocationIfNeeded() {
        guard manager.accuracyAuthorization == .reducedAccuracy else {
            return
        }

        manager.requestTemporaryFullAccuracyAuthorization(
            withPurposeKey: "MortgageMapPreciseLocation"
        )
    }
}

extension UserLocationManager: CLLocationManagerDelegate {
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        authorizationStatus = status
        handleAuthorizationStatus(status)
    }

    func locationManager(
        _ manager: CLLocationManager,
        didUpdateLocations locations: [CLLocation]
    ) {
        guard let location = locations.last else {
            return
        }

        coordinate = location.coordinate
        errorMessage = nil
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        errorMessage = "Не удалось определить геолокацию: \(error.localizedDescription)"
    }
}
