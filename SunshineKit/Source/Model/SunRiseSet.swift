//
//  SunRiseSet.swift
//  SunshineKit
//
//  Created by Oleg Mueller on 07.07.16.
//  Copyright © 2016 Oleg Mueller. All rights reserved.
//

import Foundation


public struct SunRiseSet {
    public struct DateHeight {
        public let date: Date?
        public let height: Angle?
    }
    
    
    public let sunrise: DateHeight?
    public let sunset: DateHeight?
    public let transit: DateHeight?
    
    
    public static var empty: SunRiseSet {
        return SunRiseSet(sunriseDate: nil, sunriseHeight: nil, sunsetDate: nil, sunsetHeight: nil, transitDate: nil, transitHeight: nil)
    }
    
    
    public func isDaylight(at sunPosition: SunPosition, with resolution: JulianDayResolution = .minute) -> Bool {
        let resolutionValue: Double
        
        switch resolution {
        case .hour:
            resolutionValue = 3600
        case .minute:
            resolutionValue = 60
        case .second:
            resolutionValue = 0
        }
        
        if sunrise?.date?.timeIntervalSince(sunPosition.date) ?? 0 <= resolutionValue && sunset?.date?.timeIntervalSince(sunPosition.date) ?? 0 > 0 {
            return true
        } else {
            return false
        }
    }
    
    
    // MARK: - internal
    
    
    init(sunriseDate: Date?, sunriseHeight: Angle?, sunsetDate: Date?, sunsetHeight: Angle?, transitDate: Date?, transitHeight: Angle?) {
        self.sunrise = DateHeight(date: sunriseDate, height: sunriseHeight)
        self.sunset = DateHeight(date: sunsetDate, height: sunsetHeight)
        self.transit = DateHeight(date: transitDate, height: transitHeight)
    }
}
