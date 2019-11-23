//
//  MGeofence.swift
//  stGeofence
//
//  Created by Augustius on 24/11/2019.
//  Copyright © 2019 august. All rights reserved.
//

import Foundation
import CoreLocation
import MapKit
import CoreData

class MGeofence: NSObject, MKAnnotation {

    var coordinate: CLLocationCoordinate2D
    var locationName: String
    var radius: Double
    var title: String?
    var subtitle: String?

    static var entityName = "Geofence"

    static var appDelegate: AppDelegate? = {
        return UIApplication.shared.delegate as? AppDelegate
    }()

    init(_ coordinate: CLLocationCoordinate2D, locationName: String, radius: Double) {
        self.coordinate = coordinate
        self.locationName = locationName
        self.radius = radius
    }

    init?(_ object: NSManagedObject) {
        guard
            let latitude = object.value(forKeyPath: "latitude") as? Double,
            let longitude = object.value(forKeyPath: "longitude") as? Double,
            let radius = object.value(forKeyPath: "radius") as? Double,
            let locationName = object.value(forKeyPath: "locationName") as? String
            else { return nil }
        self.coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        self.locationName = locationName
        self.radius = radius
    }

    static func fetchAll() -> [MGeofence] {
        guard
            let managedContext = appDelegate?.persistentContainer.viewContext
            else {
                print("managedContext OR entity is nil")
                return []
        }

        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: entityName)
        do {
            let geofences = try managedContext.fetch(fetchRequest)
            return geofences.compactMap({ MGeofence.init($0) })
        } catch let error as NSError {
            print("Could not fetch. \(error), \(error.userInfo)")
            return []
        }
    }

    func save() throws {
        guard
            let managedContext = MGeofence.appDelegate?.persistentContainer.viewContext,
            let entity = NSEntityDescription.entity(forEntityName: MGeofence.entityName, in: managedContext)
            else {
                throw NSError(domain: "", code: -1, userInfo: nil)
        }

        let geo = NSManagedObject(entity: entity, insertInto: managedContext)
        geo.setValue(locationName, forKeyPath: "locationName")
        geo.setValue(coordinate.latitude, forKey: "latitude")
        geo.setValue(coordinate.longitude, forKey: "longitude")
        geo.setValue(radius, forKey: "radius")

        return try managedContext.save()
    }

}
