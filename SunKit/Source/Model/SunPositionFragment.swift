//
//  SunPositionFragment.swift
//  SunBalcony
//
//  Created by Oleg Mueller on 11.07.16.
//  Copyright © 2016 Oleg Mueller. All rights reserved.
//

import Foundation


public enum SunPositionFragment {
    
    
    public enum Shadow {
        case length
        case direction
    }
    
    
    case ascension
    case azimuth
    case height
    case incidence
    case zenith
    case shadow([Shadow])
}


let FullSunPositionFragments: [SunPositionFragment] = [.ascension, .azimuth, .height, .incidence, .zenith, .shadow([
    SunPositionFragment.Shadow.direction, SunPositionFragment.Shadow.length
    ])]
