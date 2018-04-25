//
//  NSDate+SunKitExtension.swift
//  SunBalcony
//
//  Created by Oleg Mueller on 04.07.16.
//  Copyright © 2016 Oleg Mueller. All rights reserved.
//

import Foundation


extension Date {
    public var yesterday: Date {
        let components = Set<Calendar.Component>([.year, .month, .day, .hour, .minute, .second])
        var dateComponents = Calendar.current.dateComponents(components, from: self)
        dateComponents.day = (dateComponents.day ?? 1) - 1
        
        guard let yesterday = Calendar.current.date(from: dateComponents) else { return self }
        
        return yesterday
    }
    
    
    /**
     Creates date objects for the given JulianDayResolution.
     
     - parameter resolution: The desired time resolution
     - parameter hour: Set if you need date objects only for this hour
     - returns: Date objects for the whole day with the given resolution. If hour is set, only date objects for this hour are returned.
    */
    func allDatesForDateWith(resolution: JulianDayResolution, for hour: Int? = nil) -> [Date] {
        
        
        func appendDateFromComponents(_ dateComponents: DateComponents, toDates dates: inout [Date]) {
            if let date = Calendar.current.date(from: dateComponents) {
                dates.append(date)
            }
        }
        
        
        let components = Set<Calendar.Component>([.year, .month, .day])
        var dateComponents = Calendar.current.dateComponents(components, from: self)
        
        var dates = [Date]()
        
        if let hour = hour {
            switch resolution {
            case .second:
                for hour in hour - 1..<hour + 1 {
                    dateComponents.hour = hour
                    
                    for minute in 0..<60 {
                        dateComponents.minute = minute
                        
                        for second in 0..<60 {
                            dateComponents.second = second
                            
                            appendDateFromComponents(dateComponents, toDates: &dates)
                        }
                    }
                }
            case .minute:
                for hour in hour - 1..<hour + 1 {
                    dateComponents.hour = hour
                    
                    for minute in 0..<60 {
                        dateComponents.minute = minute
                        
                        appendDateFromComponents(dateComponents, toDates: &dates)
                    }
                }
            case .hour:
                for hour in hour - 1..<hour + 1 {
                    dateComponents.hour = hour
                    
                    appendDateFromComponents(dateComponents, toDates: &dates)
                }
            }
        } else {
            switch resolution {
            case .second:
                for hour in 0..<24 {
                    dateComponents.hour = hour
                    
                    for minute in 0..<60 {
                        dateComponents.minute = minute
                        
                        for second in 0..<60 {
                            dateComponents.second = second
                            
                            appendDateFromComponents(dateComponents, toDates: &dates)
                        }
                    }
                }
            case .minute:
                for hour in 0..<24 {
                    dateComponents.hour = hour
                    
                    for minute in 0..<60 {
                        dateComponents.minute = minute
                        
                        appendDateFromComponents(dateComponents, toDates: &dates)
                    }
                }
            case .hour:
                for hour in 0..<24 {
                    dateComponents.hour = hour
                    
                    appendDateFromComponents(dateComponents, toDates: &dates)
                }
            }
        }
        
        return dates
    }
}
