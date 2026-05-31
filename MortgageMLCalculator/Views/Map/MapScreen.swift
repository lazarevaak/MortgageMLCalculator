//
//  MapScreen.swift
//  MortgageMLCalculator
//
//  Created by Alexandra Lazareva on 25.02.2026.
//

import Combine
import MapKit
import SwiftUI

struct MapScreen: View {
    @StateObject private var viewModel = MapViewModel()
    @StateObject private var locationManager = UserLocationManager()
    @State private var selectedPropertyID: String?
    @State private var selectedProperty: PropertyObject?
    @State private var cameraPosition: MapCameraPosition = .region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 55.751244, longitude: 37.618423),
            span: MKCoordinateSpan(latitudeDelta: 0.3, longitudeDelta: 0.3)
        )
    )

    private static let priceFormatter: NumberFormatter = {
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
            Map(position: $cameraPosition, selection: $selectedPropertyID) {
                ForEach(viewModel.properties, id: \.id) { property in
                    Annotation(
                        markerTitle(for: property),
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
            .navigationTitle("Недвижимость")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: centerOnUserLocation) {
                        Image(systemName: "location")
                    }
                    .accessibilityLabel("Моя геолокация")
                }
            }
            .safeAreaInset(edge: .top) {
                propertyPicker
            }
            .overlay(alignment: .bottom) {
                errorOverlay
            }
            .onAppear {
                viewModel.load()
                locationManager.requestCurrentLocation()
            }
            .onReceive(locationManager.$coordinate.compactMap { $0 }) { coordinate in
                cameraPosition = .region(
                    MKCoordinateRegion(
                        center: coordinate,
                        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                    )
                )
            }
            .onChange(of: selectedPropertyID) { _, id in
                guard let property = viewModel.properties.first(where: { $0.id == id }) else {
                    selectedProperty = nil
                    return
                }

                focusCamera(on: property)
                selectedProperty = property
            }
            .sheet(isPresented: selectedPropertyBinding) {
                if let selectedProperty {
                    MortgageScreen(
                        property: PropertyData(property: selectedProperty),
                        showsCloseButton: true
                    )
                }
            }
        }
    }

    @ViewBuilder
    private var propertyPicker: some View {
        if !viewModel.properties.isEmpty {
            HStack(spacing: 8) {
                Image(systemName: "house")
                    .font(.system(size: 26, weight: .medium))
                    .foregroundStyle(.blue)

                Picker(selection: $selectedPropertyID) {
                    Text("Выберите квартиру")
                        .tag(String?.none)

                    ForEach(viewModel.properties, id: \.id) { property in
                        Label(propertyPickerTitle(for: property), systemImage: "house.fill")
                            .tag(Optional(property.id))
                    }
                } label: {
                    HStack(spacing: 4) {
                        Text(selectedPropertyTitle)
                            .lineLimit(1)

                        Image(systemName: "chevron.up.chevron.down")
                            .font(.caption)
                    }
                }
                .pickerStyle(.menu)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))
            .padding(.horizontal)
            .padding(.top, 8)
        }
    }

    private var selectedPropertyTitle: String {
        guard
            let selectedPropertyID,
            let property = viewModel.properties.first(where: { $0.id == selectedPropertyID })
        else {
            return "Выберите квартиру"
        }

        return propertyPickerTitle(for: property)
    }

    private var errorOverlay: some View {
        VStack(spacing: 8) {
            if let errorMessage = viewModel.errorMessage {
                errorText(errorMessage)
            }

            if let errorMessage = locationManager.errorMessage {
                errorText(errorMessage)
            }
        }
        .padding()
    }

    private var selectedPropertyBinding: Binding<Bool> {
        Binding(
            get: { selectedProperty != nil },
            set: { isPresented in
                if !isPresented {
                    selectedProperty = nil
                    selectedPropertyID = nil
                }
            }
        )
    }

    private func markerTitle(for property: PropertyObject) -> String {
        let price = Self.priceFormatter.string(
            from: NSNumber(value: property.price)
        ) ?? "\(Int(property.price)) ₽"
        return "\(price), \(Int(property.area)) м²"
    }

    private func propertyPickerTitle(for property: PropertyObject) -> String {
        "\(property.address), \(Int(property.area)) м², \(Int(property.rooms)) комн."
    }

    private func propertyMarker(for property: PropertyObject) -> some View {
        VStack(spacing: 3) {
            Image(systemName: "house.fill")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 34, height: 34)
                .background(.blue, in: Circle())
                .shadow(radius: 3, y: 2)

            Text(shortPrice(for: property))
                .font(.caption2)
                .fontWeight(.semibold)
                .foregroundStyle(.primary)
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 6))
        }
    }

    private func focusCamera(on property: PropertyObject) {
        cameraPosition = .region(
            MKCoordinateRegion(
                center: CLLocationCoordinate2D(
                    latitude: property.latitude,
                    longitude: property.longitude
                ),
                span: MKCoordinateSpan(latitudeDelta: 0.035, longitudeDelta: 0.035)
            )
        )
    }

    private func shortPrice(for property: PropertyObject) -> String {
        String(format: "%.1f млн ₽", property.price / 1_000_000)
    }

    private func centerOnUserLocation() {
        if let coordinate = locationManager.coordinate {
            cameraPosition = .region(
                MKCoordinateRegion(
                    center: coordinate,
                    span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                )
            )
            return
        }

        locationManager.requestCurrentLocation()
    }

    private func errorText(_ text: String) -> some View {
        Text(text)
            .font(.footnote)
            .foregroundStyle(.white)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(.red.opacity(0.9), in: RoundedRectangle(cornerRadius: 8))
    }
}
