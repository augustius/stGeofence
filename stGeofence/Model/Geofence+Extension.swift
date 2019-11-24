//
//  Geofence+Extension.swift
//  stGeofence
//
//  Created by Augustius on 24/11/2019.
//  Copyright © 2019 august. All rights reserved.
//

import Foundation
import CoreLocation
import MapKit
import CoreData

struct GeofenceParam {
    var coordinate: CLLocationCoordinate2D
    var locationName: String
    var radius: Double
    var wifiName: String
}

enum GeoState {
    case inside(CLRegion), outside(CLRegion)
}

extension GeoState {
    func readableStatus() -> String {
        switch self {
        case .inside(let region):
            return "INSIDE \(region.identifier)"
        case .outside(let region):
            return "OUTSIDE \(region.identifier)"
        }
    }
}

extension Geofence: MKAnnotation {

    public var coordinate: CLLocationCoordinate2D {
        return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    public var title: String? {
        return locationName
    }

    public var subtitle: String? {
        return "Radius : \(radius)"
    }

    func toCLCircularRegion() -> CLCircularRegion {
        return CLCircularRegion(center: coordinate, radius: radius, identifier: locationName ?? "")
    }

    func getDistanceFrom(_ location: CLLocation) -> CLLocationDistance {
        return location.distance(from: coordinate.toCLLocation())
    }
}

extension Array where Element: Geofence {

    func sortByClosest(_ location: CLLocation) -> [Geofence] {
        return self.sorted { (firstGeo, secondGeo) -> Bool in
            return firstGeo.coordinate.toCLLocation().distance(from: location) < secondGeo.coordinate.toCLLocation().distance(from: location)
        }
    }
}

extension Set where Element: CLRegion {

    func sortByFurthest(_ location: CLLocation) -> [CLRegion] {
        return self.sorted { (firstGeo, secondGeo) -> Bool in
            guard
                let firstGeoCircle = firstGeo as? CLCircularRegion,
                let secondGeoCircle = secondGeo as? CLCircularRegion
            else { return false }
            return firstGeoCircle.center.toCLLocation().distance(from: location) > secondGeoCircle.center.toCLLocation().distance(from: location)
        }
    }
}

extension CLLocationCoordinate2D: Equatable {
    public static func == (lhs: CLLocationCoordinate2D, rhs: CLLocationCoordinate2D) -> Bool {
        return (lhs.latitude == rhs.latitude) && (lhs.longitude == rhs.longitude)
    }

    func toCLLocation() -> CLLocation {
        return CLLocation(latitude: latitude, longitude: longitude)
    }
}

extension MKMapView {
    func zoomToUserLocation() {
        guard let coordinate = userLocation.location?.coordinate else { return }
        let region = MKCoordinateRegion(center: coordinate, latitudinalMeters: 10000, longitudinalMeters: 10000)
        setRegion(region, animated: true)
    }
}
