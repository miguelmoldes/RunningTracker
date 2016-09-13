//
// Created by MIGUEL MOLDES on 12/7/16.
// Copyright (c) 2016 MIGUEL MOLDES. All rights reserved.
//

import Foundation
import CoreLocation

struct ActivityPropertyKey{
    static let locationsKey = "locations"
    static let startTimeKey = "startTime"
    static let endTimeKey = "endTime"
    static let pausedTimeKey = "pausedTime"
    static let distanceKey = "distance"
    static let afterResumedKey = "locationsafterresumed"
}

class RTActivity:NSObject , NSCoding {

    private(set) var activities = [RTActivityLocation]()
    var startTime : Double = 0
    var pausedTime : Double = 0
    private(set) var finishTime : Double = 0
    var distance : Double = 0
    private(set) var checkMarks = [Int:CLLocation]()
    private var nextMarker = 1000
    private(set) var locationsAfterResumed = [CLLocation]()

    init?(activities:[RTActivityLocation], startTime:Double, finishTime:Double, pausedTime2:Double, distance:Double, locationsAfterResumed:[CLLocation]){
        self.startTime = startTime
        self.finishTime = finishTime
        self.pausedTime = pausedTime2
        self.distance = distance
        self.locationsAfterResumed = locationsAfterResumed
        self.activities = activities.sort({$0.timestamp < $1.timestamp})
        super.init()
        self.setMarkers()
    }

    init?(startTime:Double){
        self.startTime = startTime
        super.init()
    }

    func addActivityLocation(activityLocation:RTActivityLocation, checkMarkers:Bool) -> Bool{

        if activityLocation.location.horizontalAccuracy > 20 {
            return false
        }

        var lastActivityLocation:RTActivityLocation?
        if activities.count > 0 {
            lastActivityLocation = activities[activities.count - 1]

            if lastActivityLocation != nil{
                let coords = lastActivityLocation!.location.coordinate
                if coords.latitude == activityLocation.location.coordinate.latitude && coords.longitude == activityLocation.location.coordinate.longitude {
                    return false
                }
            }
        }

        activities.append(activityLocation)
        if lastActivityLocation != nil && !activityLocation.firstAfterResumed {
            let distanceDone = activityLocation.location.distanceFromLocation(lastActivityLocation!.location)
            distance += distanceDone

            activityLocation.distance = distanceDone
        }

        if activityLocation.firstAfterResumed {
            self.locationsAfterResumed.append(activityLocation.location)
        }

        self.checkMarkers(checkMarkers)
        return true
    }

    private func checkMarkers(drawLastMarker:Bool) {
        var location : CLLocation!
        var index : Int = -1
        let activitiesLocations = activities

        if activitiesLocations.count == 1 {
            location = activitiesLocations[0].location
            index = 0
        }
        if Int(distance) >= nextMarker {
            location = activitiesLocations.last!.location
            index = Int(nextMarker / 1000)
            nextMarker = nextMarker + 1000
        }
        if index > -1 {
            checkMarks[index] = CLLocation(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
            if drawLastMarker {
                self.drawMarker(["location": location, "km":index])
            }
        }
    }

    private func setMarkers(){
        var distance = 0.0
        var index = 0
        var nextMark = 0
        var previousLocation:CLLocation!
        for activityLocation : RTActivityLocation in self.activities {
            let location = activityLocation.location
            if previousLocation != nil {
                distance += location.distanceFromLocation(previousLocation)
            }

            if Int(distance) >= nextMark {
                checkMarks[index] = location
                index = index + 1
                nextMark = nextMark + 1000
            }

            previousLocation = location
        }
    }

    private func drawMarker(userInfo:[NSObject:AnyObject]?) {
        NSNotificationCenter.defaultCenter().postNotificationName("addKMMarker", object: nil, userInfo: userInfo)
    }

    func activityFinished(time:NSTimeInterval){
        self.finishTime = time
    }

    func getActivitiesCopy()->[RTActivityLocation]{
        var copyList = [RTActivityLocation]()
        for activity:RTActivityLocation in activities {
            let copyActivity : RTActivityLocation = NSKeyedUnarchiver.unarchiveObjectWithData(NSKeyedArchiver.archivedDataWithRootObject(activity)) as! RTActivityLocation
            copyList.append(copyActivity)
        }
        return copyList
    }

    func getDuration() -> Double {
        return self.finishTime - self.pausedTime - self.startTime
    }

    func getPace() -> Double {
        let totalTime = self.getDuration()
        if totalTime <= 0 || distance <= 0 {
            return 0.00
        }

        let pace = 1000 * totalTime / distance
        return pace
    }


// MARK NSCoding

    internal func encodeWithCoder(aCoder: NSCoder){
        aCoder.encodeDouble(startTime, forKey:ActivityPropertyKey.startTimeKey)
        aCoder.encodeDouble(finishTime, forKey:ActivityPropertyKey.endTimeKey)
        aCoder.encodeDouble(pausedTime, forKey:ActivityPropertyKey.pausedTimeKey)
        aCoder.encodeDouble(distance, forKey:ActivityPropertyKey.distanceKey)
        aCoder.encodeObject(activities, forKey:ActivityPropertyKey.locationsKey)
        aCoder.encodeObject(locationsAfterResumed, forKey:ActivityPropertyKey.afterResumedKey)
    }

    required convenience init?(coder aDecoder: NSCoder){
        let activities = aDecoder.decodeObjectForKey(ActivityPropertyKey.locationsKey) as! [RTActivityLocation]
        let locationsAfterResumed = aDecoder.decodeObjectForKey(ActivityPropertyKey.afterResumedKey) as! [CLLocation]
        let startTime = aDecoder.decodeDoubleForKey(ActivityPropertyKey.startTimeKey)
        let endTime = aDecoder.decodeDoubleForKey(ActivityPropertyKey.endTimeKey)
        let pausedTime = aDecoder.decodeDoubleForKey(ActivityPropertyKey.pausedTimeKey)
        let distance = aDecoder.decodeDoubleForKey(ActivityPropertyKey.distanceKey)
        self.init(activities: activities, startTime:startTime, finishTime:endTime, pausedTime2: pausedTime, distance:distance, locationsAfterResumed:locationsAfterResumed)
    }

}
