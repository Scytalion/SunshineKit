//
//  NRELJulianTests.swift
//  SunBalcony
//
//  Created by Oleg Mueller on 06.07.16.
//  Copyright © 2016 Oleg Mueller. All rights reserved.
//

import XCTest
@testable import SunshineKit


final class NRELJulianTests: XCTestCase {
    func testJulianEphemerisMilleniumForJulianCentury() {
        var dateComponents1 = DateComponents()
        dateComponents1.year = 2010
        dateComponents1.month = 5
        dateComponents1.day = 3
        dateComponents1.hour = 12
        
        let date = Calendar.current.date(from: dateComponents1)!
        
        let jd = julianDay(for: date, timeZoneOffset: 0)
        
        let century = julianCentury(for: jd)
        
        let millenium = julianEphemerisMillenium(for: century)
        XCTAssertEqual(millenium, 0.010335386721423683, accuracy: SunKitAccuracy)
    }
    
    
    func testJulianEphemerisMilleniaForJulianCenturies() {
        var dateComponents1 = DateComponents()
        dateComponents1.year = 2010
        dateComponents1.month = 5
        dateComponents1.day = 3
        dateComponents1.hour = 12
        
        let date = Calendar.current.date(from: dateComponents1)!
        
        let jd = julianDay(for: date, timeZoneOffset: 0)
        
        let century = julianCentury(for: jd)
        
        let millenium = julianEphemerisMillenium(for: century)
        
        let centuries = Array<Double>(repeating: century, count: 100)
        
        let otherMillenias = julianEphemerisMillenias(for: centuries)
        XCTAssertEqual(otherMillenias.count, 100)
        for m in otherMillenias {
            XCTAssertEqual(m, millenium, accuracy: SunKitAccuracy)
        }
    }
    
    
    func testJulianEphemerisDayForJulianDay() {
        var dateComponents1 = DateComponents()
        dateComponents1.year = 2000
        dateComponents1.month = 1
        dateComponents1.day = 1
        dateComponents1.hour = 12
        
        let date = Calendar.current.date(from: dateComponents1)!
        
        let jd = julianDay(for: date, timeZoneOffset: 0)
        
        let day = julianEphemerisDay(for: jd)
        XCTAssertEqual(day, 2451545.0007754629, accuracy: SunKitAccuracy)
    }
    
    
    func testJulianEphemerisDaysForJulianDays() {
        var dateComponents1 = DateComponents()
        dateComponents1.year = 2000
        dateComponents1.month = 1
        dateComponents1.day = 1
        dateComponents1.hour = 12
        
        let date = Calendar.current.date(from: dateComponents1)!
        
        let jd = julianDay(for: date, timeZoneOffset: 0)
        let ephemerisDay = julianEphemerisDay(for: jd)
        let julianDays = Array<Double>(repeating: jd, count: 100)
        
        let otherDays = julianEphemerisDays(for: julianDays)
        XCTAssertEqual(otherDays.count, 100)
        
        for e in otherDays {
            XCTAssertEqual(e, ephemerisDay, accuracy: SunKitAccuracy)
        }
    }
    
    
    func testJulianCenturyForJulianDay() {
        var dateComponents1 = DateComponents()
        dateComponents1.year = 2000
        dateComponents1.month = 1
        dateComponents1.day = 1
        dateComponents1.hour = 12
        
        let date = Calendar.current.date(from: dateComponents1)!
        
        let jd = julianDay(for: date, timeZoneOffset: 0)
        
        let century = julianCentury(for: jd)
        XCTAssertEqual(0, century)
    }
    
    
    func testJulianCenturiesForJulianDays() {
        var dateComponents1 = DateComponents()
        dateComponents1.year = 2003
        dateComponents1.month = 10
        dateComponents1.day = 17
        dateComponents1.hour = 12
        dateComponents1.minute = 30
        dateComponents1.second = 30
        
        let date = Calendar.current.date(from: dateComponents1)!
        
        let jd = julianDay(for: date, timeZoneOffset: 0)
        let century = julianCentury(for: jd)
        
        let julianDays = Array<Double>(repeating: jd, count: 100)
        
        let centuries = julianCenturies(for: julianDays)
        XCTAssertEqual(centuries.count, 100)
        
        for c in centuries {
            XCTAssertEqual(c, century, accuracy: SunKitAccuracy)
        }
    }
    
    
    func testJulianDayFromDate() {
        var dateComponents1 = DateComponents()
        dateComponents1.year = 2000
        dateComponents1.month = 1
        dateComponents1.day = 1
        dateComponents1.hour = 12
        
        let date = Calendar.current.date(from: dateComponents1)!
        
        let jd = julianDay(for: date, timeZoneOffset: 0)
        
        XCTAssertEqual(jd, 2451545.0, accuracy: SunKitAccuracy)
        
        var dateComponents2 = DateComponents()
        dateComponents2.year = 1988
        dateComponents2.month = 6
        dateComponents2.day = 19
        dateComponents2.hour = 12
        
        let date2 = Calendar.current.date(from: dateComponents2)!
        
        let julianDay2 = julianDay(for: date2, timeZoneOffset: 0)
        
        XCTAssertEqual(julianDay2, 2447332.0, accuracy: SunKitAccuracy)
        
        var dateComponents3 = DateComponents()
        dateComponents3.year = 2003
        dateComponents3.month = 10
        dateComponents3.day = 17
        dateComponents3.hour = 12
        dateComponents3.minute = 30
        dateComponents3.second = 30
        
        let date3 = Calendar.current.date(from: dateComponents3)!
        
        let julianDay3 = julianDay(for: date3, timeZoneOffset: -7)
        
        XCTAssertEqual(julianDay3, 2452930.312847, accuracy: SunKitAccuracy)
    }
    
    
    func testJulianDaysForDateWithSecondResolution() {
        var julianDates = [Double]()
        
        let now = Date()
        
        let nowDateComponents = Calendar.current.dateComponents([.year, .month, .day], from: now)
        
        var dateComponents = DateComponents()
        dateComponents.year = nowDateComponents.year
        dateComponents.month = nowDateComponents.month
        dateComponents.day = nowDateComponents.day
        
        for hour in 0..<24 {
            dateComponents.hour = hour
            
            for minute in 0..<60 {
                dateComponents.minute = minute
                
                for second in 0..<60 {
                    dateComponents.second = second
                    
                    let date = Calendar.current.date(from: dateComponents)!
                    
                    let julianDate = julianDay(for: date, timeZoneOffset: 0)
                    
                    julianDates.append(julianDate)
                }
            }
        }
        
        let fromDate = Calendar.current.date(from: nowDateComponents)!
        
        let otherJulianDates = julianDays(for: fromDate, timeZoneOffset: 0, withResolution: .second)
        XCTAssertEqual(otherJulianDates.count, 24*60*60)
        
        for i in 0..<24*60*60 {
            let value1 = julianDates[i]
            let value2 = otherJulianDates[i]
            
            XCTAssertEqual(value1, value2)
        }
    }
    
    
    func testJulianDaysForDateWithMinuteResolution() {
        var julianDates = [Double]()
        
        let now = Date()
        
        let nowDateComponents = Calendar.current.dateComponents([.year, .month, .day], from: now)
        
        for hour in 0..<24 {
            for minute in 0..<60 {
                var dateComponents = DateComponents()
                dateComponents.year = nowDateComponents.year
                dateComponents.month = nowDateComponents.month
                dateComponents.day = nowDateComponents.day
                dateComponents.hour = hour
                dateComponents.minute = minute
                
                let date = Calendar.current.date(from: dateComponents)!
                
                let julianDate = julianDay(for: date, timeZoneOffset: 0)
                
                julianDates.append(julianDate)
            }
        }
        
        let fromDate = Calendar.current.date(from: nowDateComponents)!
        
        let otherJulianDates = julianDays(for: fromDate, timeZoneOffset: 0, withResolution: .minute)
        XCTAssertEqual(otherJulianDates.count, 1440)
        
        for i in 0..<24*60 {
            let value1 = julianDates[i]
            let value2 = otherJulianDates[i]
            
            XCTAssertEqual(value1, value2)
        }
    }
    
    
    func testJulianDaysForDateWithHourResolution() {
        var julianDates = [Double]()
        
        let now = Date()
        
        let nowDateComponents = Calendar.current.dateComponents([.year, .month, .day], from: now)
        
        for hour in 0..<24 {
            var dateComponents = DateComponents()
            dateComponents.year = nowDateComponents.year
            dateComponents.month = nowDateComponents.month
            dateComponents.day = nowDateComponents.day
            dateComponents.hour = hour
            
            let date = Calendar.current.date(from: dateComponents)!
            
            let julianDate = julianDay(for: date, timeZoneOffset: 0)
            
            julianDates.append(julianDate)
        }
        
        let fromDate = Calendar.current.date(from: nowDateComponents)!
        
        let otherJulianDates = julianDays(for: fromDate, timeZoneOffset: 0, withResolution: .hour)
        XCTAssertEqual(otherJulianDates.count, 24)
        
        for i in 0..<24 {
            let value1 = julianDates[i]
            let value2 = otherJulianDates[i]
            
            XCTAssertEqual(value1, value2)
        }
    }
    
    
    func testJulianDaysForHour() {
        let now = Date()
        
        let nowDateComponents = Calendar.current.dateComponents([.year, .month, .day], from: now)
        let fromDate = Calendar.current.date(from: nowDateComponents)!
        
        let otherJulianDates1 = julianDays(for: fromDate, forHour: 8, timeZoneOffset: 0, withResolution: .hour)
        XCTAssertEqual(otherJulianDates1.count, 2)
        var dateComponents = DateComponents()
        var index = 0
        for hour in 7..<9 {
            dateComponents.hour = hour
            let date = Calendar.current.date(byAdding: dateComponents, to: fromDate)!
            let julianDate = julianDay(for: date, timeZoneOffset: 0)
            XCTAssertEqual(julianDate, otherJulianDates1[index])
            index += 1
        }
        
        
        let otherJulianDates2 = julianDays(for: fromDate, forHour: 0, timeZoneOffset: 0, withResolution: .hour)
        XCTAssertEqual(otherJulianDates2.count, 1)
        dateComponents = DateComponents()
        dateComponents.hour = 0
        var date = Calendar.current.date(byAdding: dateComponents, to: fromDate)!
        var julianDate = julianDay(for: date, timeZoneOffset: 0)
        XCTAssertEqual(julianDate, otherJulianDates2[0])
        
        
        let otherJulianDates3 = julianDays(for: fromDate, forHour: 23, timeZoneOffset: 0, withResolution: .hour)
        XCTAssertEqual(otherJulianDates3.count, 2)
        dateComponents = DateComponents()
        index = 0
        for hour in 22..<24 {
            dateComponents.hour = hour
            let date = Calendar.current.date(byAdding: dateComponents, to: fromDate)!
            let julianDate = julianDay(for: date, timeZoneOffset: 0)
            XCTAssertEqual(julianDate, otherJulianDates3[index])
            index += 1
        }
        
        
        let otherJulianDates4 = julianDays(for: fromDate, forHour: 8, timeZoneOffset: 0, withResolution: .minute)
        XCTAssertEqual(otherJulianDates4.count, 2*60)
        dateComponents = DateComponents()
        index = 0
        for hour in 7..<9 {
            dateComponents.hour = hour
            for minute in 0..<60 {
                dateComponents.minute = minute
                date = Calendar.current.date(byAdding: dateComponents, to: fromDate)!
                julianDate = julianDay(for: date, timeZoneOffset: 0)
                XCTAssertEqual(julianDate, otherJulianDates4[index*60 + minute])
            }
            index += 1
        }
        
        
        let otherJulianDates5 = julianDays(for: fromDate, forHour: 0, timeZoneOffset: 0, withResolution: .minute)
        XCTAssertEqual(otherJulianDates5.count, 1*60)
        dateComponents = DateComponents()
        dateComponents.hour = 0
        for minute in 0..<60 {
            dateComponents.minute = minute
            date = Calendar.current.date(byAdding: dateComponents, to: fromDate)!
            julianDate = julianDay(for: date, timeZoneOffset: 0)
            XCTAssertEqual(julianDate, otherJulianDates5[minute])
        }
        
        
        let otherJulianDates6 = julianDays(for: fromDate, forHour: 23, timeZoneOffset: 0, withResolution: .minute)
        XCTAssertEqual(otherJulianDates6.count, 2*60)
        dateComponents = DateComponents()
        index = 0
        for hour in 22..<24 {
            dateComponents.hour = hour
            
            for minute in 0..<60 {
                dateComponents.minute = minute
                date = Calendar.current.date(byAdding: dateComponents, to: fromDate)!
                julianDate = julianDay(for: date, timeZoneOffset: 0)
                XCTAssertEqual(julianDate, otherJulianDates6[index*60 + minute])
            }
            
            index += 1
        }
        
        
        let otherJulianDates7 = julianDays(for: fromDate, forHour: 8, timeZoneOffset: 0, withResolution: .second)
        XCTAssertEqual(otherJulianDates7.count, 2*60*60)
        dateComponents = DateComponents()
        index = 0
        for hour in 7..<9 {
            dateComponents.hour = hour
            
            for minute in 0..<60 {
                dateComponents.minute = minute
                
                for second in 0..<60 {
                    dateComponents.second = second
                    date = Calendar.current.date(byAdding: dateComponents, to: fromDate)!
                    julianDate = julianDay(for: date, timeZoneOffset: 0)
                    XCTAssertEqual(julianDate, otherJulianDates7[index*3600 + minute*60 + second])
                }
            }
            
            index += 1
        }
        
        
        let otherJulianDates8 = julianDays(for: fromDate, forHour: 0, timeZoneOffset: 0, withResolution: .second)
        XCTAssertEqual(otherJulianDates8.count, 1*60*60)
        dateComponents = DateComponents()
        dateComponents.hour = 0
        for minute in 0..<60 {
            dateComponents.minute = minute
            
            for second in 0..<60 {
                dateComponents.second = second
                date = Calendar.current.date(byAdding: dateComponents, to: fromDate)!
                julianDate = julianDay(for: date, timeZoneOffset: 0)
                XCTAssertEqual(julianDate, otherJulianDates8[minute*60 + second])
            }
        }
        
        let otherJulianDates9 = julianDays(for: fromDate, forHour: 23, timeZoneOffset: 0, withResolution: .second)
        XCTAssertEqual(otherJulianDates9.count, 2*60*60)
        dateComponents = DateComponents()
        index = 0
        for hour in 22..<24 {
            dateComponents.hour = hour
            for minute in 0..<60 {
                dateComponents.minute = minute
                
                for second in 0..<60 {
                    dateComponents.second = second
                    date = Calendar.current.date(byAdding: dateComponents, to: fromDate)!
                    julianDate = julianDay(for: date, timeZoneOffset: 0)
                    XCTAssertEqual(julianDate, otherJulianDates9[index*3600 + minute*60 + second])
                }
            }
            
            index += 1
        }
    }
}
