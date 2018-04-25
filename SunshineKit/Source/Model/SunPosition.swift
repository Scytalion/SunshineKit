//
//  SunPosition.swift
//  SunshineKit
//
//  Created by Oleg Mueller on 14.05.16.
//  Copyright © 2016 Oleg Mueller. All rights reserved.
//

import Foundation


public struct SunPosition: Equatable {
    public struct Shadow: Equatable {
        public let length: Double?
        public let direction: Double?
    }
    
    
    public let ascension: Angle?
    public let zenith: Angle?
    public let incidence: Angle?
    public let azimuth: Angle?
    public let height: Angle?
    public let shadow: Shadow?
    public let date: Date
    
    
    public static var empty: SunPosition {
        return SunPosition(date: Date())
    }
    
    
    public init(date: Date, ascension: Angle? = nil, azimuth: Angle? = nil, height: Angle? = nil, zenith: Angle? = nil, incidence: Angle? = nil, shadowDirection: Angle? = nil, shadowLength: Double? = nil) {
        self.ascension = ascension
        self.azimuth = azimuth
        self.height = height
        self.date = date
        self.zenith = zenith
        self.incidence = incidence
        
        if shadowDirection != nil || shadowLength != nil {
            self.shadow = Shadow(length: shadowLength, direction: shadowDirection)
        } else {
            self.shadow = nil
        }
    }
}


public func ==(lhs: SunPosition, rhs: SunPosition) -> Bool {
    return lhs.ascension == rhs.ascension
        && lhs.azimuth == rhs.azimuth
        && lhs.height == rhs.height
        && lhs.date.timeIntervalSince1970 == rhs.date.timeIntervalSince1970
        && lhs.zenith == rhs.zenith
        && lhs.incidence == rhs.incidence
        && lhs.shadow == rhs.shadow
}


public func ==(lhs: SunPosition.Shadow, rhs: SunPosition.Shadow) -> Bool {
    return lhs.direction == rhs.direction
        && lhs.length == rhs.length
}
