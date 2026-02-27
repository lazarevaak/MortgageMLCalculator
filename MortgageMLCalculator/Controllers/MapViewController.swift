//
//  MapViewController.swift
//  MortgageMLCalculator
//
//  Created by Alexandra Lazareva on 25.02.2026.
//

import UIKit
import MapKit
import CoreLocation
import RxSwift

final class MapViewController: UIViewController {

    private let mapView = MKMapView()
    private let locationManager = CLLocationManager()
    private let viewModel: MapViewModel
    private let disposeBag = DisposeBag()

    init(viewModel: MapViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        setupUI()
        setupLocation()
        bind()

        viewModel.load()
    }

    // MARK: - Setup

    private func setupUI() {
        view.addSubview(mapView)
        mapView.frame = view.bounds
        mapView.autoresizingMask = [.flexibleWidth, .flexibleHeight]

        mapView.showsUserLocation = true
        mapView.delegate = self
    }

    private func setupLocation() {
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
    }

    // MARK: - Binding

    private func bind() {
        viewModel.properties
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] properties in
                self?.addAnnotations(properties)
            })
            .disposed(by: disposeBag)
    }

    // MARK: - Map Logic

    private func addAnnotations(_ properties: [PropertyObject]) {
        mapView.removeAnnotations(mapView.annotations)

        let annotations = properties.map {
            PropertyAnnotation(property: $0)
        }

        mapView.addAnnotations(annotations)
    }

    private func openMortgage(for property: PropertyObject) {

        let mortgageViewModel = MortgageViewModel(property: property)

        let controller = MortgageViewController(viewModel: mortgageViewModel)
        controller.modalPresentationStyle = .fullScreen

        present(controller, animated: true)
    }
}

// MARK: - MKMapViewDelegate

extension MapViewController: MKMapViewDelegate {

    func mapView(
        _ mapView: MKMapView,
        didSelect view: MKAnnotationView
    ) {
        guard let annotation = view.annotation as? PropertyAnnotation else { return }

        openMortgage(for: annotation.property)
    }
}

// MARK: - CLLocationManagerDelegate

extension MapViewController: CLLocationManagerDelegate {

    func locationManager(
        _ manager: CLLocationManager,
        didUpdateLocations locations: [CLLocation]
    ) {
        guard let location = locations.first else { return }

        let region = MKCoordinateRegion(
            center: location.coordinate,
            latitudinalMeters: 5000,
            longitudinalMeters: 5000
        )

        mapView.setRegion(region, animated: true)
        locationManager.stopUpdatingLocation()
    }
}
