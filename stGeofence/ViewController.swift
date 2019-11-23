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
import UserNotifications

class ViewController: UIViewController, CLLocationManagerDelegate, MKMapViewDelegate {

    @IBOutlet private weak var mapView: MKMapView!

    private var locationManager : CLLocationManager = CLLocationManager()

    override func viewDidLoad() {
        super.viewDidLoad()
        self.mapView.delegate = self
        self.locationManager.delegate = self
        self.locationManager.requestAlwaysAuthorization()
        self.locationManager.startUpdatingLocation()
    }

    func mapView(_ mapView: MKMapView, didUpdate userLocation: MKUserLocation) {
        print("location updating......")
    }

    @IBAction private func currentLocationDidTap() {
        mapView.zoomToUserLocation()
    }

    @IBAction private func addGeofence() {

    }
}

extension MKMapView {
  func zoomToUserLocation() {
    guard let coordinate = userLocation.location?.coordinate else { return }
    let region = MKCoordinateRegion(center: coordinate, latitudinalMeters: 10000, longitudinalMeters: 10000)
    setRegion(region, animated: true)
  }
}
