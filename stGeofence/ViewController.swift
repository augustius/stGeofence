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

    private var locationManager : CLLocationManager = CLLocationManager()

    var geofence: [MGeofence] = MGeofence.fetchAll()

    override func viewDidLoad() {
        super.viewDidLoad()
        self.mapView.delegate = self
        self.locationManager.delegate = self
        self.locationManager.requestAlwaysAuthorization()
        self.locationManager.startUpdatingLocation()

        geofence.forEach { (geo) in
            self.addNewOverLay(geo)
        }
    }

    func addNewOverLay(_ geo: MGeofence) {
        self.mapView.addAnnotation(geo)
        self.mapView.addOverlay(MKCircle(center: geo.coordinate, radius: geo.radius))
    }

    func mapView(_ mapView: MKMapView, didUpdate userLocation: MKUserLocation) {
        print("location updating......")
    }

    @IBAction private func currentLocationDidTap() {
        mapView.zoomToUserLocation()
    }

    @IBAction private func longPressTap(_ gestureRecognizer: UILongPressGestureRecognizer) {
        let point = gestureRecognizer.location(in: mapView)
        let coordinate = mapView.convert(point, toCoordinateFrom: view)
        print("\(coordinate.latitude),\(coordinate.longitude)")
        presentAlert(coordinate)
    }

    private func presentAlert(_ coordinate: CLLocationCoordinate2D) {
        let alert = UIAlertController(title: "New GeoFence Area", message: "Fill in detail below", preferredStyle: .alert)
        let saveAction = UIAlertAction(title: "Save", style: .default) { action in
            let nameToSave = alert.textFields?.first?.text ?? "no name"
            let radius: Double = Double(alert.textFields?.last?.text ?? "") ?? 500
            self.saveNewGeoFence(name: nameToSave, coordinate: coordinate, radius: radius)
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        alert.addTextField { (textfield) in
            textfield.placeholder = "Enter new GeoFence area name"
        }
        alert.addTextField { (textfield) in
            textfield.keyboardType = .numberPad
            textfield.placeholder = "Enter new GeoFence area radius"
        }
        alert.addAction(saveAction)
        alert.addAction(cancelAction)
        present(alert, animated: true)
    }

    func saveNewGeoFence(name: String, coordinate: CLLocationCoordinate2D, radius: Double) {
        let geo = MGeofence(coordinate, locationName: name, radius: radius)
        do {
            try geo.save()
            addNewOverLay(geo)
        } catch let error {
            print(error.localizedDescription)
        }
    }
}

extension MKMapView {
    func zoomToUserLocation() {
        guard let coordinate = userLocation.location?.coordinate else { return }
        let region = MKCoordinateRegion(center: coordinate, latitudinalMeters: 10000, longitudinalMeters: 10000)
        setRegion(region, animated: true)
    }
}

extension ViewController: MKMapViewDelegate {

    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        let identifier = "MGeofenceIdentifier"
        if annotation is MGeofence {
            var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? MKPinAnnotationView
            if annotationView == nil {
                annotationView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: identifier)
            } else {
                annotationView?.annotation = annotation
            }
            return annotationView
        } else {
            return nil
        }
    }


    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if overlay is MKCircle {
            let circleRenderer = MKCircleRenderer(overlay: overlay)
            circleRenderer.lineWidth = 1.0
            circleRenderer.strokeColor = .systemIndigo
            circleRenderer.fillColor = UIColor.systemIndigo.withAlphaComponent(0.4)
            return circleRenderer
        }
        return MKOverlayRenderer(overlay: overlay)
    }
}
