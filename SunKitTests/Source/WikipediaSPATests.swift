//
//  WikipediaSPATests.swift
//  SunBalcony
//
//  Created by Oleg Mueller on 06.07.16.
//  Copyright © 2016 Oleg Mueller. All rights reserved.
//

import XCTest
@testable import SunKit
import CoreLocation


final class WikipediaSPATests: XCTestCase {
    var coordinate: CLLocationCoordinate2D {
        return CLLocationCoordinate2D(latitude: 48.1, longitude: 11.6)
    }
    
    
    func testSPAWithMunichWikipediaExample() {
        var dateComponents = DateComponents()
        dateComponents.year = 2006
        dateComponents.month = 8
        dateComponents.day = 6
        dateComponents.hour = 8
        dateComponents.minute = 0
        dateComponents.second = 0
        
        let date = Calendar.current.date(from: dateComponents)!
        
        let coordinate = CLLocationCoordinate2D(latitude: 48.1, longitude: 11.6)
        
        let sunPosition = WikipediaSunPosition(for: date, coordinate: coordinate)
        
        XCTAssertEqual(sunPosition.height!, 19.109, accuracy: 0.001)
        XCTAssertEqual(sunPosition.azimuth!, 85.938, accuracy: 0.001)
    }
    
    
    func testSunPositionPerformance() {
        measure {
            for _ in 0..<60 {
                _ = WikipediaSunPosition(for: Date(), coordinate: self.coordinate)
            }
        }
    }
}
