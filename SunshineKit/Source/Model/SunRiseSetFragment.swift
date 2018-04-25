//
//  SunRiseSet+Fragments.swift
//  SunBalcony
//
//  Created by Oleg Mueller on 11.07.16.
//  Copyright © 2016 Oleg Mueller. All rights reserved.
//

import Foundation


public enum SunRiseSetFragment {
    public enum DateHeightFragment {
        case date
        case height
    }
    
    
    case sunrise([DateHeightFragment])
    case sunset([DateHeightFragment])
    case transit([DateHeightFragment])
}


let FullSunRiseSetFragments: [SunRiseSetFragment] = [.transit([SunRiseSetFragment.DateHeightFragment.date, SunRiseSetFragment.DateHeightFragment.height]),
                                                     .sunrise([SunRiseSetFragment.DateHeightFragment.date, SunRiseSetFragment.DateHeightFragment.height]),
                                                     .sunset([SunRiseSetFragment.DateHeightFragment.date, SunRiseSetFragment.DateHeightFragment.height])]
