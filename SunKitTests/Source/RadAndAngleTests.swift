//
//  RadAndAngleTests.swift
//  SunBalcony
//
//  Created by Oleg Mueller on 06.07.16.
//  Copyright © 2016 Oleg Mueller. All rights reserved.
//

import Foundation
import XCTest
@testable import SunKit


final class RadAndAngleTests: XCTestCase {
    func testAngleToRadAndRadToAngle() {
        let angle1 = 45.0
        
        let rad = angleToRad(angle1)
        
        let angle2 = radToAngle(rad)
        
        XCTAssertEqual(angle1, angle2)
    }
    
    
    func testAnglesToRadsAndRadsToAngles() {
        let angle1 = 33.0
        let angles1 = Array(repeating: angle1, count: 100)
        
        let rads1 = anglesToRads(angles1)
        XCTAssertEqual(rads1.count, 100)
        
        let angles2 = radsToAngles(rads1)
        XCTAssertEqual(angles2.count, 100)
        
        for angle in angles2 {
            XCTAssertEqual(angle1, angle)
        }
    }
}
