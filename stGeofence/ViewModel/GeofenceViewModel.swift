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

class GeofenceViewModel: NSObject, CLLocationManagerDelegate {

    // Core Location prevents any single app from monitoring more than 20 regions simultaneously
    // https://developer.apple.com/documentation/corelocation/monitoring_the_user_s_proximity_to_geographic_regions
    var geoMonitoringLimit: Int = 10

    var addNewOverLay: ((_ geo: Geofence) -> Void)?
    var removeOverLay: ((_ geo: Geofence) -> Void)?
    var showMessage: ((_ msg: String) -> Void)?
    var dataSource: GeoFenceDSProtocol = GeoFenceCoreDataSource()

    private var locationManager : CLLocationManager = CLLocationManager()
    private var geofences: [Geofence] = []
    private var currentEnterRegions: [CLRegion] = []
    private let annotationIdentifier = "GeofenceIdentifier"

    override init() {
        super.init()
        configureLocationManager()
    }

    private func configureLocationManager() {
        locationManager.delegate = self
        locationManager.requestAlwaysAuthorization()
        locationManager.startUpdatingLocation()
    }

    func fetchAllGeo() {
        geofences = dataSource.fetchAllGeoFence()
        geofences.forEach({ addNewOverLay?($0) })
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
}

extension GeofenceViewModel: MKMapViewDelegate {

    func mapViewWillStartLocatingUser(_ mapView: MKMapView) {
        showMessage?("mapViewWillStartLocatingUser")
    }

    func mapView(_ mapView: MKMapView, didUpdate userLocation: MKUserLocation) {
        let sortedGeos = geofences.sortByClosest(userLocation.location).prefix(geoMonitoringLimit)
        var sortedMonitoredGeos = locationManager.monitoredRegions.sortByFurthest(userLocation.location)

        sortedGeos.forEach({ geo in
            if !sortedMonitoredGeos.contains(geo.toCLCircularRegion()) {
                let limitReach = !(locationManager.monitoredRegions.count < geoMonitoringLimit)
                if limitReach {
                    if let lastRegion = sortedMonitoredGeos.last {
                        locationManager.stopMonitoring(for: lastRegion)
                        sortedMonitoredGeos.removeLast()
                        print("\(lastRegion.identifier) stopMonitoring")
                    }
                }
                locationManager.startMonitoring(for: geo.toCLCircularRegion())
                print("\(geo.locationName ?? "") startMonitoring")
            } else {
                print("\(geo.locationName ?? "") aldy Monitoring")
            }
        })
    }

    func locationManager(_ manager: CLLocationManager, didStartMonitoringFor region: CLRegion) {
        print("didStartMonitoringFor \(region.identifier)")
    }

    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        showMessage?("didEnterRegion \(region.identifier)")
    }

    func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        if let circleRegion = region as? CLCircularRegion,
            let geo = geofences.first(where: { $0.coordinate == circleRegion.center }),
            let geoWifiName = geo.wifiName {
            let currentWifiInfos = SSID.fetchNetworkInfo() ?? []
            let allWifiName = currentWifiInfos.compactMap({ $0.ssid })
            if !allWifiName.contains(geoWifiName) {
                showMessage?("didExitRegion \(region.identifier)")
            }
        } else {
            showMessage?("didExitRegion \(region.identifier)")
        }
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





//extension GeofenceViewModel: CLLocationManagerDelegate {
//
//    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
//
//    }
//
//}
