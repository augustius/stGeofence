//
//  GeoFenceDataSource.swift
//  stGeofence
//
//  Created by Augustius on 24/11/2019.
//  Copyright © 2019 august. All rights reserved.
//

import Foundation
import CoreData
import UIKit

protocol GeoFenceDSProtocol {
    func fetchAllGeoFence() -> [Geofence]
    func delete(_ geo: Geofence)
    func save(_ param: GeofenceParam) -> Geofence
    func fetchNetworkInfo() -> [NetworkInfo]
}

class GeoFenceCoreDataSource: GeoFenceDSProtocol {
    func fetchAllGeoFence() -> [Geofence] {
        guard
            let appDelegate = UIApplication.shared.delegate as? AppDelegate
            else { return [] }

        let managedContext = appDelegate.persistentContainer.viewContext
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "Geofence")
        do {
            let geofences = try managedContext.fetch(fetchRequest)
            return (geofences as? [Geofence]) ?? []
        } catch let error as NSError {
            print("Could not fetch. \(error), \(error.userInfo)")
            return []
        }
    }

    func delete(_ geo: Geofence) {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return }

        let managedContext = appDelegate.persistentContainer.viewContext
        managedContext.delete(geo)
        appDelegate.saveContext()
    }

    func save(_ param: GeofenceParam) -> Geofence {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { fatalError() }

        let context = appDelegate.persistentContainer.viewContext
        let geo = Geofence(context: context)
        geo.latitude = param.coordinate.latitude
        geo.longitude = param.coordinate.longitude
        geo.locationName = param.locationName
        geo.radius = param.radius
        geo.wifiName = param.wifiName

        appDelegate.saveContext()
        return geo
    }

    func fetchNetworkInfo() -> [NetworkInfo] {
        return SSID.fetchNetworkInfo() ?? []
    }
}
