//
//  NRELSunriseTests.swift
//  SunshineKit
//
//  Created by Oleg Mueller on 11.07.16.
//  Copyright © 2016 Oleg Mueller. All rights reserved.
//

import Foundation
import XCTest
import CoreLocation
@testable import SunshineKit


final class NRELSunriseTests: XCTestCase {
    func testNRELSunsetForSanktPeterOrding() {
        var dateComponents = DateComponents()
        dateComponents.year = 2016
        dateComponents.month = 7
        dateComponents.day = 18
        let date = Calendar.current.date(from: dateComponents)!
        let coordinate = CLLocationCoordinate2D(latitude: 54.339262, longitude: 8.600417)
        
        let fragments: [SunRiseSetFragment] = [.sunset([SunRiseSetFragment.DateHeightFragment.date])]
        let sunriseset = NRELSunrise(for: date, timeZoneOffset: 2, coordinate: coordinate, fragments: fragments)
        let components = Calendar.current.dateComponents([.hour, .minute, .second], from: sunriseset.sunset!.date!)
        XCTAssertEqual(components.hour, 21)
        XCTAssertEqual(components.minute, 47)
        XCTAssertEqual(components.second, 16) // seen live: 50
    }
    
    
    func testNRELSunriseWithSubsetFragmentsForDate() {
        var dateComponents = DateComponents()
        dateComponents.year = 1994
        dateComponents.month = 1
        dateComponents.day = 2
        let date = Calendar.current.date(from: dateComponents)!
        let coordinate = CLLocationCoordinate2D(latitude: 35, longitude: 0)
        
        
        let transitDateFragments: [SunRiseSetFragment] = [.transit([SunRiseSetFragment.DateHeightFragment.date])]
        var sunriseset = NRELSunrise(for: date, timeZoneOffset: 0, coordinate: coordinate, fragments: transitDateFragments)
        var components = Calendar.current.dateComponents([.hour, .minute, .second], from: sunriseset.transit!.date!)
        XCTAssertEqual(components.hour, 12)
        XCTAssertEqual(components.minute, 4)
        XCTAssertEqual(components.second, 0)
        
        let transitHeightFragments: [SunRiseSetFragment] = [.transit([SunRiseSetFragment.DateHeightFragment.height])]
        sunriseset = NRELSunrise(for: date, timeZoneOffset: 0, coordinate: coordinate, fragments: transitHeightFragments)
        XCTAssertEqual(sunriseset.transit!.height!, 32.0912504, accuracy: SunshineKitAccuracy)
        
        let transitBothFragments: [SunRiseSetFragment] = [.transit([SunRiseSetFragment.DateHeightFragment.date, SunRiseSetFragment.DateHeightFragment.height])]
        sunriseset = NRELSunrise(for: date, timeZoneOffset: 0, coordinate: coordinate, fragments: transitBothFragments)
        components = Calendar.current.dateComponents([.hour, .minute, .second], from: sunriseset.transit!.date!)
        XCTAssertEqual(components.hour, 12)
        XCTAssertEqual(components.minute, 4)
        XCTAssertEqual(components.second, 0)
        XCTAssertEqual(sunriseset.transit!.height!, 32.0912504, accuracy: SunshineKitAccuracy)
        
        
        let sunsetDateFragments: [SunRiseSetFragment] = [.sunset([SunRiseSetFragment.DateHeightFragment.date])]
        sunriseset = NRELSunrise(for: date, timeZoneOffset: 0, coordinate: coordinate, fragments: sunsetDateFragments)
        components = Calendar.current.dateComponents([.hour, .minute, .second], from: sunriseset.sunset!.date!)
        XCTAssertEqual(components.hour, 16)
        XCTAssertEqual(components.minute, 59)
        XCTAssertEqual(components.second, 56)
        
        let sunsetHeightFragments: [SunRiseSetFragment] = [.sunset([SunRiseSetFragment.DateHeightFragment.height])]
        sunriseset = NRELSunrise(for: date, timeZoneOffset: 0, coordinate: coordinate, fragments: sunsetHeightFragments)
        XCTAssertEqual(sunriseset.sunset!.height!, -0.73393324, accuracy: SunshineKitAccuracy)
        
        let sunsetBothFragments: [SunRiseSetFragment] = [.sunset([SunRiseSetFragment.DateHeightFragment.date, SunRiseSetFragment.DateHeightFragment.height])]
        sunriseset = NRELSunrise(for: date, timeZoneOffset: 0, coordinate: coordinate, fragments: sunsetBothFragments)
        XCTAssertEqual(sunriseset.sunset!.height!, -0.73393324, accuracy: SunshineKitAccuracy)
        components = Calendar.current.dateComponents([.hour, .minute, .second], from: sunriseset.sunset!.date!)
        XCTAssertEqual(components.hour, 16)
        XCTAssertEqual(components.minute, 59)
        XCTAssertEqual(components.second, 56)
        
        
        let sunriseDateFragments: [SunRiseSetFragment] = [.sunrise([SunRiseSetFragment.DateHeightFragment.date])]
        sunriseset = NRELSunrise(for: date, timeZoneOffset: 0, coordinate: coordinate, fragments: sunriseDateFragments)
        components = Calendar.current.dateComponents([.hour, .minute, .second], from: sunriseset.sunrise!.date!)
        XCTAssertEqual(components.hour, 7)
        XCTAssertEqual(components.minute, 8)
        XCTAssertEqual(components.second, 13)
        
        let sunriseHeightFragments: [SunRiseSetFragment] = [.sunrise([SunRiseSetFragment.DateHeightFragment.height])]
        sunriseset = NRELSunrise(for: date, timeZoneOffset: 0, coordinate: coordinate, fragments: sunriseHeightFragments)
        XCTAssertEqual(sunriseset.sunrise!.height!, -0.843002484, accuracy: SunshineKitAccuracy)
        
        let sunriseBothFragments: [SunRiseSetFragment] = [.sunrise([SunRiseSetFragment.DateHeightFragment.date, SunRiseSetFragment.DateHeightFragment.height])]
        sunriseset = NRELSunrise(for: date, timeZoneOffset: 0, coordinate: coordinate, fragments: sunriseBothFragments)
        XCTAssertEqual(sunriseset.sunrise!.height!, -0.843002484, accuracy: SunshineKitAccuracy)
        components = Calendar.current.dateComponents([.hour, .minute, .second], from: sunriseset.sunrise!.date!)
        XCTAssertEqual(components.hour, 7)
        XCTAssertEqual(components.minute, 8)
        XCTAssertEqual(components.second, 13)
    }
    
    
    func testNRELSunriseWithALlFragmentsForDate() {
        var dateComponents = DateComponents()
        dateComponents.year = 1994
        dateComponents.month = 1
        dateComponents.day = 2
        
        var date = Calendar.current.date(from: dateComponents)!
        
        var coordinate = CLLocationCoordinate2D(latitude: 35, longitude: 0)
        
        var sunriseset = NRELSunrise(for: date, timeZoneOffset: 0, coordinate: coordinate, fragments: FullSunRiseSetFragments)
        
        var components = Calendar.current.dateComponents([.hour, .minute, .second], from: sunriseset.sunrise!.date!)
        XCTAssertEqual(components.hour, 7)
        XCTAssertEqual(components.minute, 8)
        XCTAssertEqual(components.second, 13)
        
        components = Calendar.current.dateComponents([.hour, .minute, .second], from: sunriseset.transit!.date!)
        XCTAssertEqual(components.hour, 12)
        XCTAssertEqual(components.minute, 4)
        XCTAssertEqual(components.second, 0)
        
        components = Calendar.current.dateComponents([.hour, .minute, .second], from: sunriseset.sunset!.date!)
        XCTAssertEqual(components.hour, 16)
        XCTAssertEqual(components.minute, 59)
        XCTAssertEqual(components.second, 56)
        
        dateComponents.year = 2016
        dateComponents.month = 7
        dateComponents.day = 9
        
        date = Calendar.current.date(from: dateComponents)!
        
        coordinate = CLLocationCoordinate2D(latitude: 53.3249, longitude: 10)
        
        sunriseset = NRELSunrise(for: date, timeZoneOffset: 2, coordinate: coordinate, fragments: FullSunRiseSetFragments)
        
        components = Calendar.current.dateComponents([.hour, .minute, .second], from: sunriseset.sunrise!.date!)
        XCTAssertEqual(components.hour, 5)
        XCTAssertEqual(components.minute, 4)
        XCTAssertEqual(components.second, 11)
        
        components = Calendar.current.dateComponents([.hour, .minute, .second], from: sunriseset.transit!.date!)
        XCTAssertEqual(components.hour, 13)
        XCTAssertEqual(components.minute, 25)
        XCTAssertEqual(components.second, 17)
        
        components = Calendar.current.dateComponents([.hour, .minute, .second], from: sunriseset.sunset!.date!)
        XCTAssertEqual(components.hour, 21)
        XCTAssertEqual(components.minute, 45)
        XCTAssertEqual(components.second, 43)
    }
    
    
    func testSunRiseSetPerformance() {
        let now = Date()
        let coordinate = CLLocationCoordinate2D(latitude: 13.0, longitude: 53.0)
        
        measure {
            _ = NRELSunrise(for: now, timeZoneOffset: 0, coordinate: coordinate, fragments: FullSunRiseSetFragments)
        }
    }
}
