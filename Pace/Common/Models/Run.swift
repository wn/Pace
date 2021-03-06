//
//  Pace.swift
//  Pace
//
//  Created by Yuntong Zhang on 16/3/19.
//  Copyright © 2019 nus.cs3217.pace. All rights reserved.
//

import Foundation
import CoreLocation
import RealmSwift
import GoogleMaps
import Firebase

class Run: IdentifiableObject {
    @objc dynamic var realmCameraPosition: RealmGMSCameraPosition?
    @objc dynamic var runner: UserReference?
    @objc dynamic var dateCreated = Date()
    @objc dynamic var timeSpent: Double = 0.0
    @objc dynamic var distance: Double = 0.0
    @objc dynamic var thumbnailData: Data?
    @objc dynamic var routeId: String?
    var thumbnail: UIImage? {
        guard let thumbnailData = thumbnailData else {
            return UIImage(named: "run.jpeg")
        }
        return UIImage(data: thumbnailData)
    }
    var checkpoints = List<CheckPoint>()
    var cameraPosition: GMSCameraPosition? {
        return realmCameraPosition?.asGMSCameraPosition
    }
    var route: Route? {
        get {
            return realm?.objects(Route.self)
                .filter(NSPredicate(format: "objectId = %@", routeId ?? "")).first
        }
    }

    // computed properties, ignored by Realm
    var startingLocation: CLLocation? {
        return checkpoints.first?.location
    }
    var endingLocation: CLLocation? {
        return checkpoints.last?.location
    }
    var totalDistance: Double? {
        return checkpoints.last?.routeDistance
    }
    var locations: [CLLocation] {
        return checkpoints.compactMap { $0.location }
    }

    /// Constructs a Run with the given runner and checkpoints.
    /// - Parameters:
    ///   - runner: The runner of this Run.
    ///   - checkpoints: The array of normalized checkpoints for this Run.
    convenience init(runner: UserReference, checkpoints: [CheckPoint],
                     routeId: String? = nil, thumbnail: Data? = nil) {
        self.init()
        guard let lastPoint = checkpoints.last else {
            return
        }
        self.runner = runner
        self.timeSpent = lastPoint.time
        self.distance = lastPoint.routeDistance
        self.checkpoints = {
            let checkpointsList = List<CheckPoint>()
            checkpointsList.append(objectsIn: checkpoints)
            return checkpointsList
        }()
        self.routeId = routeId
        self.thumbnailData = thumbnail
    }

    /// Gets the latitude and longitude boundaries for this run.
    /// - Returns: A tuple of range of latitude and range of longitude.
    func getBoundaries() -> (ClosedRange<CLLocationDegrees>, ClosedRange<CLLocationDegrees>) {
        let latitudes = locations.map { $0.latitude }
        let longitudes = locations.map { $0.longitude }
        guard let minLatitude = latitudes.min(),
            let maxLatitude = latitudes.max(),
            let minLongitude = longitudes.min(),
            let maxLongitude = longitudes.max() else {
                fatalError("There should be locations in the run.")
        }
        return (latitudeRange: minLatitude...maxLatitude, longitudeRange: minLongitude...maxLongitude)
    }

    /// Normalizes an array of CheckPoints based on the checkPoints array of this Run.
    /// - Precondition: the given runner record does not deviate from this Run.
    /// - Parameter runnerRecords: the array of CheckPoints to be normalized.
    /// - Returns: an array of normalized CheckPoints.
    func normalize(_ runnerRecords: [CheckPoint]) -> [CheckPoint] {
        // normalize the records which are within the original run.
        var normalizedPoints: [CheckPoint] = checkpoints.compactMap { basePoint in
            basePoint.extractNormalizedPoint(from: runnerRecords)
        }
        guard let originalMaxDistance = checkpoints.last?.routeDistance else {
            fatalError("The checkpoints from the original Run should not be empty.")
        }
        let outsidePoints = runnerRecords.filter { $0.actualDistance > originalMaxDistance }
        guard let outsideStartDistance = outsidePoints.first?.actualDistance else {
            // there are no outside points to be normalized
            return normalizedPoints
        }
        // normalize the records outside the original run range based on routeDistance
        let initialNormalizedPoints = Route.normalizeFrom(distance: outsideStartDistance, for: outsidePoints)
        normalizedPoints.append(contentsOf: initialNormalizedPoints)
        return normalizedPoints
    }

    /// Gets the Checkpoint of the runner based on the distance run by the runner
    /// - Parameter distance: distance completed by the runner at the point in time
    /// - Returns: the Checkpoint of the runner at the run percentage
    func getCheckpointAt(distance distanceCompleted: Double) -> CheckPoint? {
        guard let totalDist = totalDistance,
            distanceCompleted < totalDist else {
            return checkpoints.last
        }
        var leftIdx = 0
        var rightIdx = checkpoints.count - 1
        // Binary search to find segment which bounds timeAtPercentage
        while leftIdx + 1 < rightIdx {
            let idx = Int((rightIdx + leftIdx) / 2)
            if checkpoints[idx].routeDistance < distanceCompleted {
                leftIdx = idx
            } else if checkpoints[idx].routeDistance > distanceCompleted {
                rightIdx = idx
            } else {
                return checkpoints[idx]
            }
        }

        // Interpolate to get the CLLocation between the left and right checkpoints
        return CheckPoint.interpolate(with: distanceCompleted,
                                      between: checkpoints[leftIdx],
                                      and: checkpoints[rightIdx],
                                      on: nil)
    }
}
