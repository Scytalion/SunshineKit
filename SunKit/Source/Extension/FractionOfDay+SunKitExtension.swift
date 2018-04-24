//
//  FractionOfDay+SunKitExtension.swift
//  SunBalcony
//
//  Created by Oleg Mueller on 11.07.16.
//  Copyright © 2016 Oleg Mueller. All rights reserved.
//

import Foundation


extension FractionOfDay {
    
    
    // MARK: - internal
    
    
    func hours() -> Int {
        let hours = Int(self)
        return hours
    }
    
    
    func minutes() -> Int {
        let minutes = doubleMinutes()
        return Int(minutes)
    }
    
    
    func seconds() -> Int {
        let seconds = 60*(doubleMinutes() - Double(Int(doubleMinutes())))
        return Int(seconds)
    }
    
    
    func dateByAdding(_ date: Date) -> Date {
        let hours = self.hours()
        let minutes = self.minutes()
        let seconds = self.seconds()
        
        var dateComponents = Calendar.current.dateComponents([.era, .year, .month, .day], from: date)
        dateComponents.hour = hours
        dateComponents.minute = minutes
        dateComponents.second = seconds
        
        let date = Calendar.current.date(from: dateComponents) ?? date
        
        return date
    }
    
    
    // MARK: - private
    
    
    private func doubleMinutes() -> Double {
        let minutes = (self - Double(Int(self)))*60
        return minutes
    }
}
