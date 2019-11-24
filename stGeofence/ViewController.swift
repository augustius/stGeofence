//
//  ViewController.swift
//  stGeofence
//
//  Created by Augustius on 23/11/2019.
//  Copyright © 2019 august. All rights reserved.
//
//

import UIKit
import MapKit
import CoreLocation

class ViewController: UIViewController, CLLocationManagerDelegate {

    @IBOutlet private weak var mapView: MKMapView!
    @IBOutlet private weak var textView: UITextView!

    private var viewModel: GeofenceViewModel!

    override func viewDidLoad() {
        super.viewDidLoad()
        configureViewModel()
        mapView.delegate = viewModel
    }

    private func configureViewModel() {
        viewModel = GeofenceViewModel()
        viewModel.addNewOverLay = addNewOverLay
        viewModel.removeOverLay = removeOverLay
        viewModel.showMessage = showMessage
        viewModel.fetchAllGeo()
    }

    // MARK: - Callback
    private func addNewOverLay(_ geo: Geofence) {
        mapView.addAnnotation(geo)
        mapView.addOverlay(MKCircle(center: geo.coordinate, radius: geo.radius))
    }

    private func removeOverLay(_ geo: Geofence) {
        mapView.removeAnnotation(geo)
        guard let overlays = mapView?.overlays else { return }
        for overlay in overlays {
            guard let circleOverlay = overlay as? MKCircle else { continue }
            let coord = circleOverlay.coordinate
            if coord.latitude == geo.coordinate.latitude && coord.longitude == geo.coordinate.longitude && circleOverlay.radius == geo.radius {
                mapView?.removeOverlay(circleOverlay)
                break
            }
        }
    }

    func showMessage(_ msg: String) {
        textView.insertText("\n\(msg)")
    }

    // MARK: - IBAction Method
    @IBAction private func currentLocationDidTap() {
        mapView.zoomToUserLocation()
    }

    @IBAction private func longPressTap(_ gestureRecognizer: UILongPressGestureRecognizer) {
        let point = gestureRecognizer.location(in: mapView)
        let coordinate = mapView.convert(point, toCoordinateFrom: view)
        print("\(coordinate.latitude),\(coordinate.longitude)")
        presentAddAlert(coordinate)
    }

    private func presentAddAlert(_ coordinate: CLLocationCoordinate2D) {
        let alert = UIAlertController(title: "New GeoFence Area", message: "Fill in detail below", preferredStyle: .alert)
        let saveAction = UIAlertAction(title: "Save", style: .default) { action in
            let locName = alert.textFields?.first?.text ?? "no name"
            let radius: Double = Double(alert.textFields?[1].text ?? "") ?? 500
            let wifiName = alert.textFields?.last?.text ?? ""
            let param = GeofenceParam(coordinate: coordinate, locationName: locName, radius: radius, wifiName: wifiName)
            self.viewModel.save(param)
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        alert.addTextField { (textfield) in
            textfield.placeholder = "Enter new GeoFence area name"
        }
        alert.addTextField { (textfield) in
            textfield.keyboardType = .numberPad
            textfield.placeholder = "Enter area radius in meter (default 500m)"
        }
        alert.addTextField { (textfield) in
            textfield.placeholder = "Enter wifi name associated with GeoFence"
        }
        alert.addAction(saveAction)
        alert.addAction(cancelAction)
        present(alert, animated: true)
    }
}
