//
//  WikipediaSPA.swift
//  SunBalcony
//
//  Created by Oleg Mueller on 06.07.16.
//  Copyright © 2016 Oleg Mueller. All rights reserved.
//

import Foundation
import CoreLocation

/**
 Calculates the SunPosition for a date and location.
 
 Source is a German Wikipedia [Article](https://de.wikipedia.org/wiki/Sonnenstand)
 
 - parameter date: The point in time to calculate the sun position
 - parameter coordinate: The point on earth to calculate the sun position for
 - returns: A SunPosition object with date, azimuth and height
 */
func WikipediaSunPosition(for date: Date, coordinate: CLLocationCoordinate2D) -> SunPosition {
    let components = Set<Calendar.Component>([.year, .month, .day, .hour, .minute, .second])
    
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(secondsFromGMT: 0)!
    var dateComponents = calendar.dateComponents(components, from: date)
    let hour = dateComponents.hour ?? 0
    let minute = dateComponents.minute
    let second = dateComponents.second
    
    dateComponents.hour = 0
    dateComponents.minute = 0
    dateComponents.second = 0
    
    guard let zerothDate = calendar.date(from: dateComponents) else { return SunPosition.empty }
    
    let jDay = julianDay(from: date)
    let n = jDay - 2451545
    let L: Angle = 280.46 + 0.9856474*n
    let g: Angle = 357.528 + 0.9856003*n
    let delta: Rad = angleToRad(L) + angleToRad(1.915)*sin(angleToRad(g)) + angleToRad(0.01997)*sin(angleToRad(2*g))
    let epsilon: Rad = angleToRad(23.439 - 0.0000004*n)
    
    let alphaNominator = cos(delta)
    var alpha: Angle = radToAngle(atan((cos(epsilon)*sin(delta))/alphaNominator))
    
    if radToAngle(alphaNominator) < 0 {
        alpha += 180.0
    }
    
    let gamma: Rad = asin(sin(epsilon)*sin(delta))
    
    let zerothJulianDay = julianDay(from: zerothDate)
    
    let timeZero = (zerothJulianDay - 2451545.0)/36525.0
    
    let hours: Double = Double(hour) + Double(minute!)/60.0 + Double(second!)/3600.0 // hours of day, e.g. 17,75 for 17:45h
    
    let meanRaiseTime = 6.697376 + 2400.05134*timeZero + 1.002738*hours
    
    let greenwichHourAngleSpringpoint: Angle = meanRaiseTime*15.0
    
    let hourAngleSpringPoint: Angle = greenwichHourAngleSpringpoint + coordinate.longitude
    
    let tau: Rad = angleToRad(hourAngleSpringPoint - alpha)
    
    let nominatorForAzimuth: Rad = cos(tau)*sin(angleToRad(coordinate.latitude)) - tan(gamma)*cos(angleToRad(coordinate.latitude))
    
    var azimuth: Angle = radToAngle(atan(sin(tau)/nominatorForAzimuth))
    
    if radToAngle(nominatorForAzimuth) < 0 {
        azimuth -= 180.0;
    }
    
    azimuth += 180.0
    
    if azimuth < 0 {
        azimuth += 360.0
    }
    
    var height: Angle = radToAngle(asin(cos(gamma)*cos(tau)*cos(angleToRad(coordinate.latitude)) + sin(gamma)*sin(angleToRad(coordinate.latitude))))
    
    // corrected height for refraction
    let r: Angle = 1.02/tan(angleToRad(height + 10.3/(height + 5.11)))
    height = height + r/60.0;
    
    let sunPosition = SunPosition(date: date, azimuth: azimuth, height: height)
    
    return sunPosition
}


/**
 Calculates the Julian Day for a Date object.
 
 - parameter date: The point in time
 - returns: The Julian Day
 */
func julianDay(from date: Date) -> Double {
    let julianDay = date.timeIntervalSince1970/86400.0 + 2440587.5
    var intpart = 0.0
    let fractpart = modf(julianDay, &intpart)
    
    switch fractpart {
    case let fractpart where fractpart <= 0.25:
        return intpart + 0.25
    case let fractpart where fractpart <= 0.5:
        return intpart + 0.5
    case let fractpart where fractpart <= 0.75:
        return intpart + 0.75
    default:
        return intpart + 1
    }
}
