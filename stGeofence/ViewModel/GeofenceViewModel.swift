//
//  GeofenceViewModel.swift
//  stGeofence
//
//  Created by Augustius on 24/11/2019.
//  Copyright © 2019 august. All rights reserved.
//

import Foundation
import CoreLocation
import MapKit

class GeofenceViewModel: NSObject, CLLocationManagerDelegate, MKMapViewDelegate {

    // Core Location prevents any single app from monitoring more than 20 regions simultaneously
    // https://developer.apple.com/documentation/corelocation/monitoring_the_user_s_proximity_to_geographic_regions
    var geoMonitoringLimit: Int = 10

    var addNewOverLay: ((_ geo: Geofence) -> Void)?
    var removeOverLay: ((_ geo: Geofence) -> Void)?
    var showMessage: ((_  state: GeoState) -> Void)?
    var dataSource: GeoFenceDSProtocol = GeoFenceCoreDataSource()
    var locationManager: CLLocationManager = CLLocationManager()
    var geofences: [Geofence] = []

    private let annotationIdentifier = "GeofenceIdentifier"

    override init() {
        super.init()
        configureLocationManager()
    }

    func configureLocationManager() {
        locationManager.delegate = self
        locationManager.requestAlwaysAuthorization()
        locationManager.startUpdatingLocation()
    }

    func fetchAllGeo() {
        geofences = dataSource.fetchAllGeoFence()
        geofences.forEach({
            addNewOverLay?($0)
            locationManager.requestState(for: $0.toCLCircularRegion())
            print($0)
        })
    }

    func remove(_ geo: Geofence) {
        guard let index = geofences.firstIndex(of: geo) else { return }
        geofences.remove(at: index)
        removeOverLay?(geo)
        stopMonitoring(geo: geo)
        dataSource.delete(geo)
    }

    func stopMonitoring(geo: Geofence) {
        for region in locationManager.monitoredRegions {
            guard let circularRegion = region as? CLCircularRegion, circularRegion.identifier == geo.locationName else { continue }
            locationManager.stopMonitoring(for: circularRegion)
        }
    }

    func save(_ param: GeofenceParam) {
        let geo = dataSource.save(param)
        addNewOverLay?(geo)
        geofences.append(geo)
    }

    func decideWhichRegionToStartMonitoring(_ location: CLLocation) {
        let sortedGeos = geofences.sortByClosest(location).prefix(geoMonitoringLimit)
        var sortedMonitoredGeos = locationManager.monitoredRegions.sortByFurthest(location)

        sortedGeos.forEach({ geo in
            let notYetMonitored = !sortedMonitoredGeos.contains(geo.toCLCircularRegion())
            if notYetMonitored {
                let limitReach = !(locationManager.monitoredRegions.count < geoMonitoringLimit)
                if limitReach {
                    if let lastRegion = sortedMonitoredGeos.last {
                        locationManager.stopMonitoring(for: lastRegion)
                        sortedMonitoredGeos.removeLast()
                    }
                }
                locationManager.startMonitoring(for: geo.toCLCircularRegion())
            }
        })
    }

    func decideWhetherExitRegionOrNot(_ region: CLRegion) {
        guard
            let circleRegion = region as? CLCircularRegion,
            let geo = geofences.first(where: { $0.coordinate == circleRegion.center }),
            let geoWifiName = geo.wifiName
            else {
                showMessage?(.outside(region))
                return
        }

        let currentWifiInfos = dataSource.fetchNetworkInfo()
        let allWifiName = currentWifiInfos.compactMap({ $0.ssid })
        if !allWifiName.contains(geoWifiName) {
            showMessage?(.outside(region))
        } else {
            startDelayToDecideWhetherExitRegionOrNot(region)
        }
    }

    func startDelayToDecideWhetherExitRegionOrNot(_ region: CLRegion) {
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 30.0) { [weak self] in
            self?.decideWhetherExitRegionOrNot(region)
        }
    }

    // MARK: - MKMapViewDelegate
    func locationManager(_ manager: CLLocationManager, didDetermineState state: CLRegionState, for region: CLRegion) {
        switch state {
        case .inside:
            showMessage?(.inside(region))
        case .outside, .unknown: break
        }
    }

    func mapView(_ mapView: MKMapView, didUpdate userLocation: MKUserLocation) {
        if let location = userLocation.location {
            decideWhichRegionToStartMonitoring(location)
        }
    }

    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        showMessage?(.inside(region))
    }

    func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        decideWhetherExitRegionOrNot(region)
    }

    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if annotation is Geofence {
            var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: annotationIdentifier) as? MKPinAnnotationView
            if annotationView == nil {
                annotationView = createAnnotationView(annotation)
            } else {
                annotationView?.annotation = annotation
            }
            return annotationView
        } else {
            return nil
        }
    }

    func createAnnotationView(_ annotation: MKAnnotation) -> MKPinAnnotationView {
        let annotationView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: annotationIdentifier)
        annotationView.canShowCallout = true
        let removeButton = UIButton(type: .custom)
        removeButton.frame = CGRect(x: 0, y: 0, width: 23, height: 23)
        removeButton.setImage(UIImage.remove, for: .normal)
        annotationView.leftCalloutAccessoryView = removeButton
        return annotationView
    }

    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if overlay is MKCircle {
            return handleMKCircleRenderer(overlay)
        }
        return MKOverlayRenderer(overlay: overlay)
    }

    func handleMKCircleRenderer(_ overlay: MKOverlay) -> MKOverlayRenderer {
        let circleRenderer = MKCircleRenderer(overlay: overlay)
        circleRenderer.lineWidth = 1.0
        circleRenderer.strokeColor = .systemIndigo
        circleRenderer.fillColor = UIColor.systemIndigo.withAlphaComponent(0.4)
        return circleRenderer
    }

    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        if let geo = view.annotation as? Geofence {
            remove(geo)
        }
    }
}
