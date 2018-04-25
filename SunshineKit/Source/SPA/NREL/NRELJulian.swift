//
//  Julian.swift
//  SunshineKit
//
//  Created by Oleg Mueller on 06.07.16.
//  Copyright © 2016 Oleg Mueller. All rights reserved.
//

import Foundation
import Accelerate


// MARK: - JulianDay


public enum JulianDayResolution {
    case hour
    case minute
    case second
}


// MARK: - internal


typealias JulianDay = Double


let ΔT = 67.0


/**
 Calculates Julian Days for the whole day or hour with the desired resolution (one Julian Day per hour or per minute or per second).
 
 - parameter date: The point in time (day) to calculate the Julian Day for
 - parameter forHour: An optional hour, if set Julian Days are only calculated for this hour
 - parameter timeZoneOffset: Offset from UTC in hours
 - parameter withResolution: The desired resolution
 
 - returns: Julian Days for the selected date with the given resolution
 */
func julianDays(for date: Date, forHour: Int? = nil, timeZoneOffset: Int, withResolution resolution: JulianDayResolution) -> [JulianDay] {
    
    
    func addHourPart(to day_decimals: inout [JulianDay], day: Int, hour: Int = 0) {
        let length = vDSP_Length(day_decimals.count)
        var temp = day_decimals
        
        // add timezone offset
        var negativeTimeZoneOffset = Double(hour) - Double(timeZoneOffset)
        vDSP_vsaddD(&temp, 1, &negativeTimeZoneOffset, &day_decimals, 1, length)
        
        // divide through 24
        var twentyFour = 24.0
        vDSP_vsdivD(&day_decimals, 1, &twentyFour, &temp, 1, length)
        
        // add hourPart to day
        var dayDouble = Double(day)
        vDSP_vsaddD(&temp, 1, &dayDouble, &day_decimals, 1, length)
    }
    
    
    func divideThroughSixty(_ day_decimals: inout [JulianDay]) {
        let length = vDSP_Length(day_decimals.count)
        var sixty = 60.0
        var temp = day_decimals
        vDSP_vsdivD(&temp, 1, &sixty, &day_decimals, 1, length)
    }
    
    let components = Set<Calendar.Component>([.year, .month, .day])
    let dateComponents = Calendar.current.dateComponents(components, from: date)
    var year = dateComponents.year ?? 2016
    var month = dateComponents.month ?? 1
    let day = dateComponents.day ?? 1
    
    if month < 3 {
        month += 12
        year -= 1
    }
    
    let left = Int(365.25*Double(year + 4716))
    let right = Int(30.6001*Double(month + 1))
    let leftAndRight = Double(left + right)
    
    let secondsPerMinute = 60
    let minutesPerHour = 60
    
    let fromHour = forHour == nil ? 0 : (forHour! - 1 < 0 ? 0 : forHour! - 1 )
    let toHour = forHour == nil ? 24 : forHour! + 1
    
    let hoursPerDay = forHour == nil ? 24 : toHour - fromHour
    
    let count: Int
    switch resolution {
    case .second:
        count = hoursPerDay*minutesPerHour*secondsPerMinute
    case .minute:
        count = hoursPerDay*minutesPerHour
    case .hour:
        count = hoursPerDay
    }
    
    var julianDates = Array<Double>(repeating: leftAndRight, count: count)
    
    var A = 0.0
    var B = 1.0
    var subArrayCount: vDSP_Length = 0
    
    switch resolution {
    case .second:
        subArrayCount = vDSP_Length(secondsPerMinute)
        
        var index = 0
        for hour in fromHour..<toHour {
            for minute in 0..<minutesPerHour {
                var day_decimals = Array<Double>(repeating: 0, count: Int(subArrayCount))
                
                // create second vector: 0...59
                vDSP_vrampD(&A, &B, &day_decimals, 1, subArrayCount)
                
                divideThroughSixty(&day_decimals)
                
                // create minute vector
                let minutesArray = Array<Double>(repeating: Double(minute), count: Int(subArrayCount))
                // add minutes to second part
                vDSP_vaddD(minutesArray, 1, day_decimals, 1, &day_decimals, 1, subArrayCount)
                
                divideThroughSixty(&day_decimals)
                
                addHourPart(to: &day_decimals, day: day, hour: hour)
                
                // add day_decimal
                let value1 = Int(index*minutesPerHour*secondsPerMinute + minute*secondsPerMinute)
                vDSP_vaddD(&julianDates + value1, 1, &day_decimals, 1, &julianDates[index*minutesPerHour*secondsPerMinute + minute*secondsPerMinute], 1, subArrayCount)
            }
            
            index += 1
        }
    case .minute:
        subArrayCount = vDSP_Length(minutesPerHour)
        
        var index = 0
        for hour in fromHour..<toHour {
            var day_decimals = Array<Double>(repeating: 0, count: Int(subArrayCount))
            
            // create minute vector: 0...59
            vDSP_vrampD(&A, &B, &day_decimals, 1, subArrayCount)
            
            divideThroughSixty(&day_decimals)
            
            addHourPart(to: &day_decimals, day: day, hour: hour)
            
            // add day_decimal
            vDSP_vaddD(&julianDates + Int(index*minutesPerHour), 1, &day_decimals, 1, &julianDates[index*minutesPerHour], 1, subArrayCount)
            
            index += 1
        }
    case .hour:
        subArrayCount = vDSP_Length(hoursPerDay)
        var day_decimals = Array<Double>(repeating: 0, count: Int(subArrayCount))
        
        // create hour vector: 0...23
        var index = 0
        for hour in fromHour..<toHour {
            day_decimals[index] = Double(hour)
            index += 1
        }
        
        addHourPart(to: &day_decimals, day: day)
        
        var temp = julianDates
        
        // add day_decimal
        vDSP_vaddD(&temp, 1, &day_decimals, 1, &julianDates, 1, subArrayCount)
    }
    
    let length = vDSP_Length(count)
    
    var minusValue = -1524.5
    var temp = julianDates
    vDSP_vsaddD(&temp, 1, &minusValue, &julianDates, 1, length)
    
    if julianDates[0] > 2299160.0 {
        let a = Int(year/100)
        var addValue = Double(2 - a + Int(a/4))
        vDSP_vsaddD(&julianDates, 1, &addValue, &temp, 1, length)
        
        return temp
    } else {
        return julianDates
    }
}


/**
 Calculates Julian Day for the given date
 
 - parameter date: The point in time (day) to calculate the Julian Day for
 - parameter timeZoneOffset: Offset from UTC in hours
 
 - returns: Julian Day for the selected date
 */
func julianDay(for date: Date, timeZoneOffset: Int) -> JulianDay {
    let dateComponents = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second], from: date)
    
    var year = dateComponents.year ?? 2016
    var month = dateComponents.month ?? 1
    let hour = dateComponents.hour ?? 0
    let minute = dateComponents.minute ?? 0
    let second = dateComponents.second ?? 0
    let day = dateComponents.day ?? 0
    
    let secondPart = (Double(second))/60.0
    let minutePart = (Double(minute) + secondPart)/60.0
    let hourPart = (Double(hour - timeZoneOffset) + minutePart)/24.0
    let day_decimal = Double(day) + hourPart
    
    if month < 3 {
        month += 12
        year -= 1
    }
    
    let left = Int(365.25*Double(year + 4716))
    let right = Int(30.6001*Double(month + 1))
    var julian_day = Double(left + right) + day_decimal - 1524.5
    
    if julian_day > 2299160.0 {
        let a = Int(year/100)
        julian_day += Double(2 - a + Int(a/4))
    }
    
    return julian_day
}


// MARK: - JulianCentury


typealias JulianCentury = Double


/**
 Calculates Julian Century for the given Julian Day
 
 - parameter day: The Julian Day to calculate the Julian Century for
 
 - returns: Julian Century for the selected Julian Day
 */
func julianCentury(for day: JulianDay) -> JulianCentury {
    let century = (day - 2451545.0)/36525.0
    return century
}


/**
 Calculates Julian Centuries for the given Julian Days
 
 - parameter days: The Julian Days to calculate the Julian Centuries for
 
 - returns: Julian Centuries for the given Julian Days
 */
func julianCenturies(for days: [JulianDay]) -> [JulianCentury] {
    // create vector of -2451545.0 values
    var centuries = Array<JulianCentury>(repeating: -2451545.0, count: days.count)
    var temp = centuries
    
    // add days vector to centuries vector
    let length = vDSP_Length(days.count)
    vDSP_vaddD(days, 1, &temp, 1, &centuries, 1, length)
    
    // divide with 36525.0
    var divider = 36525.0
    vDSP_vsdivD(&centuries, 1, &divider, &temp, 1, length)
    
    return temp
}


// MARK: - JulianEphemeris Day, Century and Millenium


typealias JulianEphemerisDay = Double


/**
 Calculates Julian Ephemeris Day for the given Julian Day
 
 - parameter day: The Julian Day to calculate the Julian Ephemeris for
 
 - returns: Julian Ephemeris for the selected Julian Day
 */
func julianEphemerisDay(for day: JulianDay) -> JulianEphemerisDay {
    let ephemerisDay = day + ΔT/86400.0
    return ephemerisDay
}


/**
 Calculates Julian Ephemerises Day for the given Julian Days
 
 - parameter days: The Julian Days to calculate the Julian Ephemeris for
 
 - returns: Julian Ephemerises for the selected Julian Days
 */
func julianEphemerisDays(for days: [JulianDay]) -> [JulianEphemerisDay] {
    // create vector of ΔT/86400.0 values
    var ephemerisDays = Array<JulianEphemerisDay>(repeating: ΔT/86400.0, count: days.count)
    var temp = ephemerisDays
    
    // add days vector to ephemerisDays vector
    let length = vDSP_Length(days.count)
    vDSP_vaddD(days, 1, &temp, 1, &ephemerisDays, 1, length)
    
    return ephemerisDays
}


typealias JulianEphemerisMillenium = Double


/**
 Calculates Julian Ephemeris Millenium for the given Julian Century
 
 - parameter century: The Julian Century to calculate the Julian Ephemeris Millenium for
 
 - returns: Julian Ephemeris Millenium for the selected Julian Century
 */
func julianEphemerisMillenium(for century: JulianCentury) -> JulianEphemerisMillenium {
    let millenium = century/10.0
    return millenium
}


/**
 Calculates Julian Ephemeris Millenias for the given Julian Centuries
 
 - parameter centuries: The Julian Centuries to calculate the Julian Ephemeris Millenias for
 
 - returns: Julian Ephemeris Millenias for the selected Julian Centuries
 */
func julianEphemerisMillenias(for centuries: [JulianCentury]) -> [JulianEphemerisMillenium] {
    var millenias = Array<JulianEphemerisMillenium>(repeating: 0, count: centuries.count)
    
    let length = vDSP_Length(centuries.count)
    
    var ten = 10.0
    vDSP_vsdivD(centuries, 1, &ten, &millenias, 1, length)
    
    return millenias
}
