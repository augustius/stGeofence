//
//  GeofenceViewModelMock.swift
//  stGeofenceTests
//
//  Created by Augustius on 24/11/2019.
//  Copyright © 2019 august. All rights reserved.
//

import Foundation
import CoreLocation
import UIKit
import MapKit
@testable import stGeofence

class CLLocationManagerMock: CLLocationManager {

    var mockMonitoredRegion: [CLRegion] = []

    override func startMonitoring(for region: CLRegion) {
        mockMonitoredRegion.append(region)
    }

    override func stopMonitoring(for region: CLRegion) {
        if let index = mockMonitoredRegion.firstIndex(where: {$0 == region}) {
            mockMonitoredRegion.remove(at: index)
        }
    }
}

extension Geofence {
    static func mockGeofence() -> Geofence {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { fatalError() }
        let context = appDelegate.persistentContainer.viewContext
        let mockGeo = Geofence(context: context)
        return mockGeo
    }
}

class GeoFenceDataSourceMock: GeoFenceDSProtocol {

    var geofences: [Geofence] = []
    var networkInfos: [NetworkInfo] = []
    var deleteCalled = 0
    var saveCalled = 0

    func fetchAllGeoFence() -> [Geofence] {
        return geofences
    }

    func delete(_ geo: Geofence) {
        deleteCalled += 1
    }

    func save(_ param: GeofenceParam) -> Geofence {
        saveCalled += 1

        let mockGeo = Geofence.mockGeofence()
        mockGeo.latitude = param.coordinate.latitude
        mockGeo.longitude = param.coordinate.longitude
        mockGeo.locationName = param.locationName
        mockGeo.radius = param.radius
        mockGeo.wifiName = param.wifiName

        return mockGeo
    }

    func fetchNetworkInfo() -> [NetworkInfo] {
        return networkInfos
    }
}

class GeofenceViewModelMock: GeofenceViewModel {

    var addNewOverLayCalled = 0
    var removeOverLayCalled = 0
    var showMessageCalled = 0
    var removeGeoCalled = 0
    var createAnnotationViewCalled = 0
    var handleMKCircleRendererCalled = 0
    var startDelayToDecideWhetherExitRegionOrNotCalled = 0

    var lastMessageShown: GeoState?

    init(_ dataSource: GeoFenceDSProtocol, locationManager: CLLocationManager) {
        super.init()
        super.dataSource = dataSource
        super.locationManager = locationManager
        super.removeOverLay = removeOverLayMock
        super.addNewOverLay = addNewOverLayMock
        super.showMessage = showMessageMock
        super.configureLocationManager()
    }

    private func addNewOverLayMock(_ geo: Geofence) {
        addNewOverLayCalled += 1
    }

    private func removeOverLayMock(_ geo: Geofence) {
        removeOverLayCalled += 1
    }

    private func showMessageMock(_ state: GeoState) {
        showMessageCalled += 1
        lastMessageShown = state
    }

    override func remove(_ geo: Geofence) {
        super.remove(geo)
        removeGeoCalled += 1
    }

    override func startDelayToDecideWhetherExitRegionOrNot(_ region: CLRegion) {
        startDelayToDecideWhetherExitRegionOrNotCalled += 1
    }

    override func createAnnotationView(_ annotation: MKAnnotation) -> MKPinAnnotationView {
        createAnnotationViewCalled += 1
        return super.createAnnotationView(annotation)
    }

    override func handleMKCircleRenderer(_ overlay: MKOverlay) -> MKOverlayRenderer {
        handleMKCircleRendererCalled += 1
        return super.handleMKCircleRenderer(overlay)
    }
}
