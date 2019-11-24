//
//  GeofenceViewModelUnitTest.swift
//  stGeofenceTests
//
//  Created by Augustius on 24/11/2019.
//  Copyright © 2019 august. All rights reserved.
//

import Foundation
import CoreLocation
import UIKit
import MapKit
import XCTest
@testable import stGeofence

class GeofenceViewModelTests: XCTestCase {

    override class func setUp() {
        super.setUp()
    }

    private func prepareMock(_ dataSource: GeoFenceDSProtocol = GeoFenceDataSourceMock(), _ locationManager: CLLocationManager = CLLocationManagerMock()) -> GeofenceViewModelMock {
        let viewModel = GeofenceViewModelMock(dataSource, locationManager: locationManager)
        viewModel.fetchAllGeo()
        return viewModel
    }

    func testDecideWhichRegionToStartMonitoring() {
        let coordinate = CLLocationCoordinate2D(latitude: +37.33033674, longitude: -122.02252593)
        let mockGeo = Geofence.mockGeofence()
        mockGeo.latitude = coordinate.latitude
        mockGeo.longitude = coordinate.longitude
        mockGeo.locationName = "first"

        let coordinate2 = CLLocationCoordinate2D(latitude: +37.32602276, longitude: -122.03215808)
        let mockGeo2 = Geofence.mockGeofence()
        mockGeo2.latitude = coordinate2.latitude
        mockGeo2.longitude = coordinate2.longitude
        mockGeo2.locationName = "second" //closer to user location

        let locationManager = CLLocationManagerMock()
        let dataSource = GeoFenceDataSourceMock()
        dataSource.geofences = [mockGeo, mockGeo2]
        let viewModel = prepareMock(dataSource, locationManager)
        viewModel.geoMonitoringLimit = 1
        let location = CLLocation(latitude: +37.33525815, longitude: -122.03254639)
        viewModel.decideWhichRegionToStartMonitoring(location)
        XCTAssertEqual(locationManager.mockMonitoredRegion.first, mockGeo2.toCLCircularRegion())
        XCTAssertEqual(locationManager.mockMonitoredRegion.count, 1)
    }

    func testDecideWhetherExitRegionOrNot() {
        /// test no wifi configured
        let coordinate = CLLocationCoordinate2D(latitude: -1, longitude: -1)
        let mockGeo = Geofence.mockGeofence()
        mockGeo.latitude = coordinate.latitude
        mockGeo.longitude = coordinate.longitude
        mockGeo.wifiName = nil
        mockGeo.locationName = "setel - 45"
        let region = mockGeo.toCLCircularRegion()

        let mockWifi = NetworkInfo(interface: "en1", success: true, ssid: "setel45", bssid: nil)
        let dataSource = GeoFenceDataSourceMock()
        dataSource.geofences = [mockGeo]
        dataSource.networkInfos = [mockWifi]
        let viewModel = prepareMock(dataSource)
        viewModel.decideWhetherExitRegionOrNot(region)
        XCTAssertEqual(viewModel.showMessageCalled, 1)
        XCTAssertEqual(viewModel.lastMessageShown?.readableStatus(), GeoState.outside(region).readableStatus())
    }

    func testDecideWhetherExitRegionOrNot2() {
        /// test wifi configured and current wifi name same as exiting region wifi name
        let coordinate = CLLocationCoordinate2D(latitude: -1, longitude: -1)
        let mockGeo = Geofence.mockGeofence()
        mockGeo.latitude = coordinate.latitude
        mockGeo.longitude = coordinate.longitude
        mockGeo.wifiName = "setel45"
        mockGeo.locationName = "setel - 45"
        let region = mockGeo.toCLCircularRegion()

        let mockWifi = NetworkInfo(interface: "en1", success: true, ssid: "setel45", bssid: nil)
        let dataSource = GeoFenceDataSourceMock()
        dataSource.geofences = [mockGeo]
        dataSource.networkInfos = [mockWifi]
        let viewModel = prepareMock(dataSource)
        viewModel.decideWhetherExitRegionOrNot(region)
        XCTAssertEqual(viewModel.showMessageCalled, 0)
        XCTAssertEqual(viewModel.startDelayToDecideWhetherExitRegionOrNotCalled, 1)
        XCTAssertEqual(viewModel.lastMessageShown?.readableStatus(), nil)
    }

    func testDecideWhetherExitRegionOrNot3() {
        /// test wifi configured and current wifi name not same as exiting region wifi name
        let coordinate = CLLocationCoordinate2D(latitude: -1, longitude: -1)
        let mockGeo = Geofence.mockGeofence()
        mockGeo.latitude = coordinate.latitude
        mockGeo.longitude = coordinate.longitude
        mockGeo.wifiName = "setel45"
        mockGeo.locationName = "setel - 45"
        let region = mockGeo.toCLCircularRegion()

        let mockWifi = NetworkInfo(interface: "en1", success: true, ssid: "setel451", bssid: nil)
        let dataSource = GeoFenceDataSourceMock()
        dataSource.geofences = [mockGeo]
        dataSource.networkInfos = [mockWifi]
        let viewModel = prepareMock(dataSource)
        viewModel.decideWhetherExitRegionOrNot(region)
        XCTAssertEqual(viewModel.showMessageCalled, 1)
        XCTAssertEqual(viewModel.startDelayToDecideWhetherExitRegionOrNotCalled, 0)
        XCTAssertEqual(viewModel.lastMessageShown?.readableStatus(), GeoState.outside(region).readableStatus())
    }

    func testMapViewForAnnotation() {
        let viewModel = prepareMock()
        let mockGeo = Geofence.mockGeofence()
        let mapView = MKMapView()
        XCTAssertNotNil(viewModel.mapView(mapView, viewFor: mockGeo))
        XCTAssertEqual(viewModel.createAnnotationViewCalled, 1)
    }

    func testMKOverlayCircleRenderer() {
        let viewModel = prepareMock()
        let mockCircle = MKCircle(center: CLLocationCoordinate2D(latitude: 0, longitude: 0), radius: 50)
        _ = viewModel.mapView(MKMapView(), rendererFor: mockCircle)
        XCTAssertEqual(viewModel.handleMKCircleRendererCalled, 1)
    }

    func testDeleteGeoFence() {
        let coordinate = CLLocationCoordinate2D(latitude: -1, longitude: -1)
        let mockGeo = Geofence.mockGeofence()
        mockGeo.latitude = coordinate.latitude
        mockGeo.longitude = coordinate.longitude
        mockGeo.wifiName = "setel45"
        mockGeo.locationName = "setel - 45"

        let dataSource = GeoFenceDataSourceMock()
        dataSource.geofences = [mockGeo]
        let viewModel = prepareMock(dataSource)
        let annotationView = viewModel.createAnnotationView(mockGeo)
        XCTAssertEqual(viewModel.geofences.count, 1)
        
        viewModel.mapView(MKMapView(), annotationView: annotationView, calloutAccessoryControlTapped: UIControl())
        XCTAssertEqual(viewModel.removeGeoCalled, 1)
        XCTAssertEqual(viewModel.geofences.count, 0)
    }

    func testDeleteGeoFenceFail() {
        let viewModel = prepareMock()
        viewModel.mapView(MKMapView(), annotationView: MKAnnotationView(), calloutAccessoryControlTapped: UIControl())
        XCTAssertEqual(viewModel.removeGeoCalled, 0)
    }

}
