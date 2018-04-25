//
//  SPATests.swift
//  SunshineKit
//
//  Created by Oleg Mueller on 25.06.16.
//  Copyright © 2016 Oleg Mueller. All rights reserved.
//

import XCTest
@testable import SunshineKit
import CoreLocation


final class NRELSPATests: XCTestCase {
    
    
    // MARK: - other tests
    
    
    func testClampedAnglesToThreeSixty() {
        let angle1 = 480.0
        let clampedAngle1 = clampAngleToThreeSixty(angle1)
        
        let anglesToClamp1 = Array<Double>(repeating: angle1, count: 100)
        
        let clampedAngles1 = clampAnglesToThreeSixty(anglesToClamp1)
        XCTAssertEqual(clampedAngles1.count, 100)
        
        for angle in clampedAngles1 {
            XCTAssertEqual(angle, clampedAngle1, accuracy: SunshineKitAccuracy)
        }
        
        
        let angle2 = -380.0
        let clampedAngle2 = clampAngleToThreeSixty(angle2)
        
        let anglesToClamp2 = Array<Double>(repeating: angle2, count: 100)
        
        let clampedAngles2 = clampAnglesToThreeSixty(anglesToClamp2)
        XCTAssertEqual(clampedAngles2.count, 100)
        
        for angle in clampedAngles2 {
            XCTAssertEqual(angle, clampedAngle2, accuracy: SunshineKitAccuracy)
        }
    }
    
    
    func testClampAngleToThreeSixty() {
        let angle1 = 480.0
        let value1 = clampAngleToThreeSixty(angle1)
        
        XCTAssertEqual(value1, 120.0, accuracy: SunshineKitAccuracy)
        
        let angle2 = -380.0
        let value2 = clampAngleToThreeSixty(angle2)
        XCTAssertEqual(value2, 340.0, accuracy: SunshineKitAccuracy)
    }
    
    
    func testCalculateTermsWithArray() {
        let B_TERMS: [[[Double]]] = [
            [
                [280.0,3.199,84334.662],
                [102.0,5.422,5507.553],
                [80,3.88,5223.69],
                [44,3.7,2352.87],
                [32,4,1577.34]
            ],
            [
                [9,3.9,5507.55],
                [6,1.73,5223.69]
            ]
        ]
        
        let JME = 0.0065948002066062907
        let jmeArray = Array<Double>(repeating: JME, count: 100)
        
        let expectedResult = 310.28125065315311
        
        let results = calculateTerms(with: B_TERMS, index: 0, ephemerisMillenia: jmeArray)
        XCTAssertEqual(results.count, 100)
        
        for result in results {
            XCTAssertEqual(expectedResult, result, accuracy: SunshineKitAccuracy)
        }
    }
    
    
    func testCalculateTermWithArray() {
        let B_TERMS: [[[Double]]] = [
            [
                [280.0,3.199,84334.662],
                [102.0,5.422,5507.553],
                [80,3.88,5223.69],
                [44,3.7,2352.87],
                [32,4,1577.34]
            ],
            [
                [9,3.9,5507.55],
                [6,1.73,5223.69]
            ]
        ]
        
        let JME = 0.0065948002066062907
        
        let expectedResult = 310.28125065315311
        
        let result = calculateTerm(with: B_TERMS, index: 0, ephemerisMillenium: JME)
        XCTAssertEqual(expectedResult, result, accuracy: SunshineKitAccuracy)
    }
    
    
    // MARK: - SPA tests
    
    
    func testSPAWithPaperExample() {
        var dateComponents = DateComponents()
        dateComponents.year = 2003
        dateComponents.month = 10
        dateComponents.day = 17
        dateComponents.hour = 12
        dateComponents.minute = 30
        dateComponents.second = 30
        
        let date = Calendar.current.date(from: dateComponents)!
        
        let coordinate = CLLocationCoordinate2D(latitude: 39.742476, longitude: -105.1786)
        let pressure = 820.0
        let elevation = 1830.14
        let temperature = 11.0
        let surfaceAzimuth = SunshineKitDefaultSurfaceAzimuth
        let sunPosition = NRELSunPosition(for: date, timeZoneOffset: -7, coordinate: coordinate, elevation: elevation, fragments: FullSunPositionFragments, pressure: pressure, temperature: temperature, surfaceAzimuth: surfaceAzimuth)
        
        XCTAssertEqual(sunPosition.ascension!, 202.22703929, accuracy: SunshineKitAccuracy)
        XCTAssertEqual(sunPosition.height!, 39.888378, accuracy: SunshineKitAccuracy)
        XCTAssertEqual(sunPosition.azimuth!, 194.340241, accuracy: SunshineKitAccuracy)
        XCTAssertEqual(sunPosition.zenith!, 50.111622024, accuracy: SunshineKitAccuracy)
        XCTAssertEqual(sunPosition.incidence!, 25.187, accuracy: SunshineKitAccuracy)
        XCTAssertEqual(sunPosition.shadow!.direction!, 14.3402405, accuracy: SunshineKitAccuracy)
        XCTAssertEqual(sunPosition.shadow!.length!, 11.9647968, accuracy: SunshineKitAccuracy)
    }
    
    
    func testSunPositionFragmentsSelection() {
        var dateComponents = DateComponents()
        dateComponents.year = 2003
        dateComponents.month = 10
        dateComponents.day = 17
        dateComponents.hour = 12
        dateComponents.minute = 30
        dateComponents.second = 30
        let date = Calendar.current.date(from: dateComponents)!
        let coordinate = CLLocationCoordinate2D(latitude: 39.742476, longitude: -105.1786)
        let pressure = 820.0
        let elevation = 1830.14
        let temperature = 11.0
        let surfaceAzimuth = SunshineKitDefaultSurfaceAzimuth
        
        
        let onlyAscensionFragment: [SunPositionFragment] = [.ascension]
        var sunPosition = NRELSunPosition(for: date, timeZoneOffset: -7, coordinate: coordinate, elevation: elevation, fragments: onlyAscensionFragment, pressure: pressure, temperature: temperature, surfaceAzimuth: surfaceAzimuth)
        XCTAssertNotNil(sunPosition.ascension)
        XCTAssertNil(sunPosition.azimuth)
        XCTAssertNil(sunPosition.incidence)
        XCTAssertNil(sunPosition.height)
        XCTAssertNil(sunPosition.zenith)
        XCTAssertNil(sunPosition.shadow)
        XCTAssertEqual(sunPosition.ascension!, 202.22703929, accuracy: SunshineKitAccuracy)
        
        
        let onlyAzimuthFragment: [SunPositionFragment] = [.azimuth]
        sunPosition = NRELSunPosition(for: date, timeZoneOffset: -7, coordinate: coordinate, elevation: elevation, fragments: onlyAzimuthFragment, pressure: pressure, temperature: temperature, surfaceAzimuth: surfaceAzimuth)
        XCTAssertNil(sunPosition.ascension)
        XCTAssertNotNil(sunPosition.azimuth)
        XCTAssertNil(sunPosition.incidence)
        XCTAssertNil(sunPosition.height)
        XCTAssertNil(sunPosition.zenith)
        XCTAssertNil(sunPosition.shadow)
        XCTAssertEqual(sunPosition.azimuth!, 194.340241, accuracy: SunshineKitAccuracy)
        
        
        let onlyHeightFragment: [SunPositionFragment] = [.height]
        sunPosition = NRELSunPosition(for: date, timeZoneOffset: -7, coordinate: coordinate, elevation: elevation, fragments: onlyHeightFragment, pressure: pressure, temperature: temperature, surfaceAzimuth: surfaceAzimuth)
        XCTAssertNil(sunPosition.ascension)
        XCTAssertNil(sunPosition.azimuth)
        XCTAssertNil(sunPosition.incidence)
        XCTAssertNotNil(sunPosition.height)
        XCTAssertNil(sunPosition.zenith)
        XCTAssertNil(sunPosition.shadow)
        XCTAssertEqual(sunPosition.height!, 39.888378, accuracy: SunshineKitAccuracy)
        
        
        let onlyIncidenceFragment: [SunPositionFragment] = [.incidence] // implies calculation of azmiuth, height and zenith
        sunPosition = NRELSunPosition(for: date, timeZoneOffset: -7, coordinate: coordinate, elevation: elevation, fragments: onlyIncidenceFragment, pressure: pressure, temperature: temperature, surfaceAzimuth: surfaceAzimuth)
        XCTAssertNil(sunPosition.ascension)
        XCTAssertNotNil(sunPosition.azimuth)
        XCTAssertNotNil(sunPosition.incidence)
        XCTAssertNotNil(sunPosition.height)
        XCTAssertNotNil(sunPosition.zenith)
        XCTAssertNil(sunPosition.shadow)
        XCTAssertEqual(sunPosition.incidence!, 25.187, accuracy: SunshineKitAccuracy)
        
        
        let onlyZenithFragment: [SunPositionFragment] = [.zenith] // implies calculation of height
        sunPosition = NRELSunPosition(for: date, timeZoneOffset: -7, coordinate: coordinate, elevation: elevation, fragments: onlyZenithFragment, pressure: pressure, temperature: temperature, surfaceAzimuth: surfaceAzimuth)
        XCTAssertNil(sunPosition.ascension)
        XCTAssertNil(sunPosition.azimuth)
        XCTAssertNil(sunPosition.incidence)
        XCTAssertNotNil(sunPosition.height)
        XCTAssertNotNil(sunPosition.zenith)
        XCTAssertNil(sunPosition.shadow)
        XCTAssertEqual(sunPosition.zenith!, 50.111622024, accuracy: SunshineKitAccuracy)
        
        
        let heightAndAzimuthFragment: [SunPositionFragment] = [.azimuth, .height] // implies calculation of height
        sunPosition = NRELSunPosition(for: date, timeZoneOffset: -7, coordinate: coordinate, elevation: elevation, fragments: heightAndAzimuthFragment, pressure: pressure, temperature: temperature, surfaceAzimuth: surfaceAzimuth)
        XCTAssertNil(sunPosition.ascension)
        XCTAssertNotNil(sunPosition.azimuth)
        XCTAssertNil(sunPosition.incidence)
        XCTAssertNotNil(sunPosition.height)
        XCTAssertNil(sunPosition.zenith)
        XCTAssertNil(sunPosition.shadow)
        XCTAssertEqual(sunPosition.azimuth!, 194.340241, accuracy: SunshineKitAccuracy)
        XCTAssertEqual(sunPosition.height!, 39.888378, accuracy: SunshineKitAccuracy)
        
        
        let shadowFragment: [SunPositionFragment] = [.shadow([SunPositionFragment.Shadow.direction, SunPositionFragment.Shadow.length])]
        sunPosition = NRELSunPosition(for: date, timeZoneOffset: -7, coordinate: coordinate, elevation: elevation, fragments: shadowFragment, pressure: pressure, temperature: temperature, surfaceAzimuth: surfaceAzimuth)
        XCTAssertNil(sunPosition.ascension)
        XCTAssertNotNil(sunPosition.azimuth)
        XCTAssertNil(sunPosition.incidence)
        XCTAssertNotNil(sunPosition.height)
        XCTAssertNil(sunPosition.zenith)
        XCTAssertNotNil(sunPosition.shadow)
        XCTAssertEqual(sunPosition.azimuth!, 194.340241, accuracy: SunshineKitAccuracy)
        XCTAssertEqual(sunPosition.height!, 39.888378, accuracy: SunshineKitAccuracy)
        XCTAssertEqual(sunPosition.shadow!.direction!, 14.3402405, accuracy: SunshineKitAccuracy)
        XCTAssertEqual(sunPosition.shadow!.length!, 11.9647968, accuracy: SunshineKitAccuracy)
        
        
        let shadowDirectionFragment: [SunPositionFragment] = [.shadow([SunPositionFragment.Shadow.direction])]
        sunPosition = NRELSunPosition(for: date, timeZoneOffset: -7, coordinate: coordinate, elevation: elevation, fragments: shadowDirectionFragment, pressure: pressure, temperature: temperature, surfaceAzimuth: surfaceAzimuth)
        XCTAssertNil(sunPosition.ascension)
        XCTAssertNotNil(sunPosition.azimuth)
        XCTAssertNil(sunPosition.incidence)
        XCTAssertNil(sunPosition.height)
        XCTAssertNil(sunPosition.zenith)
        XCTAssertNil(sunPosition.shadow!.length)
        XCTAssertNotNil(sunPosition.shadow!.direction)
        XCTAssertEqual(sunPosition.azimuth!, 194.340241, accuracy: SunshineKitAccuracy)
        XCTAssertEqual(sunPosition.shadow!.direction!, 14.3402405, accuracy: SunshineKitAccuracy)
        
        
        let shadowLengthFragment: [SunPositionFragment] = [.shadow([SunPositionFragment.Shadow.length])]
        sunPosition = NRELSunPosition(for: date, timeZoneOffset: -7, coordinate: coordinate, elevation: elevation, fragments: shadowLengthFragment, pressure: pressure, temperature: temperature, surfaceAzimuth: surfaceAzimuth)
        XCTAssertNil(sunPosition.ascension)
        XCTAssertNil(sunPosition.azimuth)
        XCTAssertNil(sunPosition.incidence)
        XCTAssertNotNil(sunPosition.height)
        XCTAssertNil(sunPosition.zenith)
        XCTAssertNotNil(sunPosition.shadow!.length)
        XCTAssertNil(sunPosition.shadow!.direction)
        XCTAssertEqual(sunPosition.height!, 39.888378, accuracy: SunshineKitAccuracy)
        XCTAssertEqual(sunPosition.shadow!.length!, 11.9647968, accuracy: SunshineKitAccuracy)
        
        
        let now = Date()
        let nowDateComponents = Calendar.current.dateComponents([.year, .month, .day], from: now)
        let hourNow = Calendar.current.date(from: nowDateComponents)!
        let nowSunPosition = NRELSunPosition(for: hourNow, timeZoneOffset: 0, coordinate: coordinate, elevation: 0, fragments: FullSunPositionFragments)
        
        var vdspSunPositions = NRELSunPositions(for: hourNow, withResolution: .hour, timeZoneOffset: 0, coordinate: coordinate, elevation: 0, fragments: onlyAscensionFragment)
        XCTAssertNotNil(vdspSunPositions[0].ascension)
        XCTAssertNil(vdspSunPositions[0].azimuth)
        XCTAssertNil(vdspSunPositions[0].incidence)
        XCTAssertNil(vdspSunPositions[0].height)
        XCTAssertNil(vdspSunPositions[0].zenith)
        XCTAssertNil(vdspSunPositions[0].shadow)
        XCTAssertEqual(vdspSunPositions[0].ascension!, nowSunPosition.ascension!, accuracy: SunshineKitAccuracy)
        
        
        vdspSunPositions = NRELSunPositions(for: hourNow, withResolution: .hour, timeZoneOffset: 0, coordinate: coordinate, elevation: 0, fragments: onlyAzimuthFragment, pressure: pressure, temperature: temperature, surfaceAzimuth: surfaceAzimuth)
        XCTAssertNil(vdspSunPositions[0].ascension)
        XCTAssertNotNil(vdspSunPositions[0].azimuth)
        XCTAssertNil(vdspSunPositions[0].incidence)
        XCTAssertNil(vdspSunPositions[0].height)
        XCTAssertNil(vdspSunPositions[0].zenith)
        XCTAssertNil(vdspSunPositions[0].shadow)
        XCTAssertEqual(vdspSunPositions[0].azimuth!, nowSunPosition.azimuth!, accuracy: SunshineKitAccuracy)
        
        
        vdspSunPositions = NRELSunPositions(for: hourNow, withResolution: .hour, timeZoneOffset: 0, coordinate: coordinate, elevation: 0, fragments: onlyHeightFragment, pressure: pressure, temperature: temperature, surfaceAzimuth: surfaceAzimuth)
        XCTAssertNil(vdspSunPositions[0].ascension)
        XCTAssertNil(vdspSunPositions[0].azimuth)
        XCTAssertNil(vdspSunPositions[0].incidence)
        XCTAssertNotNil(vdspSunPositions[0].height)
        XCTAssertNil(vdspSunPositions[0].zenith)
        XCTAssertNil(vdspSunPositions[0].shadow)
        // TODO: why is the accuracy lower?
        XCTAssertEqual(vdspSunPositions[0].height!, nowSunPosition.height!, accuracy: SunshineKitAccuracy*100000)
        
        
        vdspSunPositions = NRELSunPositions(for: hourNow, withResolution: .hour, timeZoneOffset: 0, coordinate: coordinate, elevation: 0, fragments: onlyIncidenceFragment, pressure: pressure, temperature: temperature, surfaceAzimuth: surfaceAzimuth)
        XCTAssertNil(vdspSunPositions[0].ascension)
        XCTAssertNotNil(vdspSunPositions[0].azimuth)
        XCTAssertNotNil(vdspSunPositions[0].incidence)
        XCTAssertNotNil(vdspSunPositions[0].height)
        XCTAssertNotNil(vdspSunPositions[0].zenith)
        XCTAssertNil(vdspSunPositions[0].shadow)
        // TODO: why is the accuracy lower?
        XCTAssertEqual(vdspSunPositions[0].incidence!, nowSunPosition.incidence!, accuracy: SunshineKitAccuracy*100000)
        
        
        vdspSunPositions = NRELSunPositions(for: hourNow, withResolution: .hour, timeZoneOffset: 0, coordinate: coordinate, elevation: 0, fragments: onlyZenithFragment, pressure: pressure, temperature: temperature, surfaceAzimuth: surfaceAzimuth)
        XCTAssertNil(vdspSunPositions[0].ascension)
        XCTAssertNil(vdspSunPositions[0].azimuth)
        XCTAssertNil(vdspSunPositions[0].incidence)
        XCTAssertNotNil(vdspSunPositions[0].height)
        XCTAssertNotNil(vdspSunPositions[0].zenith)
        XCTAssertNil(vdspSunPositions[0].shadow)
        // TODO: why is the accuracy lower?
        XCTAssertEqual(vdspSunPositions[0].zenith!, nowSunPosition.zenith!, accuracy: SunshineKitAccuracy*1000000)
        
        
        vdspSunPositions = NRELSunPositions(for: hourNow, withResolution: .hour, timeZoneOffset: 0, coordinate: coordinate, elevation: 0, fragments: heightAndAzimuthFragment, pressure: pressure, temperature: temperature, surfaceAzimuth: surfaceAzimuth)
        XCTAssertNil(vdspSunPositions[0].ascension)
        XCTAssertNotNil(vdspSunPositions[0].azimuth)
        XCTAssertNil(vdspSunPositions[0].incidence)
        XCTAssertNotNil(vdspSunPositions[0].height)
        XCTAssertNil(vdspSunPositions[0].zenith)
        XCTAssertNil(vdspSunPositions[0].shadow)
        XCTAssertEqual(vdspSunPositions[0].azimuth!, nowSunPosition.azimuth!, accuracy: SunshineKitAccuracy)
        // TODO: why is the accuracy lower?
        XCTAssertEqual(vdspSunPositions[0].height!, nowSunPosition.height!, accuracy: SunshineKitAccuracy*100000)
        
        
        vdspSunPositions = NRELSunPositions(for: hourNow, withResolution: .hour, timeZoneOffset: 0, coordinate: coordinate, elevation: 0, fragments: shadowFragment, pressure: pressure, temperature: temperature, surfaceAzimuth: surfaceAzimuth)
        XCTAssertNil(vdspSunPositions[0].ascension)
        XCTAssertNotNil(vdspSunPositions[0].azimuth)
        XCTAssertNil(vdspSunPositions[0].incidence)
        XCTAssertNotNil(vdspSunPositions[0].height)
        XCTAssertNil(vdspSunPositions[0].zenith)
        XCTAssertNotNil(vdspSunPositions[0].shadow!.direction!)
        XCTAssertNotNil(vdspSunPositions[0].shadow!.length!)
        XCTAssertEqual(vdspSunPositions[0].azimuth!, nowSunPosition.azimuth!, accuracy: SunshineKitAccuracy)
        // TODO: why is the accuracy lower?
        XCTAssertEqual(vdspSunPositions[0].height!, nowSunPosition.height!, accuracy: SunshineKitAccuracy*100000)
        XCTAssertEqual(vdspSunPositions[0].shadow!.direction!, nowSunPosition.shadow!.direction!, accuracy: SunshineKitAccuracy)
        XCTAssertEqual(vdspSunPositions[0].shadow!.length!, nowSunPosition.shadow!.length!, accuracy: SunshineKitAccuracy*100000)
        
        
        vdspSunPositions = NRELSunPositions(for: hourNow, withResolution: .hour, timeZoneOffset: 0, coordinate: coordinate, elevation: 0, fragments: shadowDirectionFragment, pressure: pressure, temperature: temperature, surfaceAzimuth: surfaceAzimuth)
        XCTAssertNil(vdspSunPositions[0].ascension)
        XCTAssertNotNil(vdspSunPositions[0].azimuth)
        XCTAssertNil(vdspSunPositions[0].incidence)
        XCTAssertNil(vdspSunPositions[0].height)
        XCTAssertNil(vdspSunPositions[0].zenith)
        XCTAssertNotNil(vdspSunPositions[0].shadow!.direction!)
        XCTAssertNil(vdspSunPositions[0].shadow!.length)
        XCTAssertEqual(vdspSunPositions[0].azimuth!, nowSunPosition.azimuth!, accuracy: SunshineKitAccuracy)
        XCTAssertEqual(vdspSunPositions[0].shadow!.direction!, nowSunPosition.shadow!.direction!, accuracy: SunshineKitAccuracy)
        
        
        vdspSunPositions = NRELSunPositions(for: hourNow, withResolution: .hour, timeZoneOffset: 0, coordinate: coordinate, elevation: 0, fragments: shadowLengthFragment, pressure: pressure, temperature: temperature, surfaceAzimuth: surfaceAzimuth)
        XCTAssertNil(vdspSunPositions[0].ascension)
        XCTAssertNil(vdspSunPositions[0].azimuth)
        XCTAssertNil(vdspSunPositions[0].incidence)
        XCTAssertNotNil(vdspSunPositions[0].height)
        XCTAssertNil(vdspSunPositions[0].zenith)
        XCTAssertNil(vdspSunPositions[0].shadow!.direction)
        XCTAssertNotNil(vdspSunPositions[0].shadow!.length)
        // TODO: why is the accuracy lower?
        XCTAssertEqual(vdspSunPositions[0].height!, nowSunPosition.height!, accuracy: SunshineKitAccuracy*100000)
        XCTAssertEqual(vdspSunPositions[0].shadow!.length!, nowSunPosition.shadow!.length!, accuracy: SunshineKitAccuracy*100000)
    }
    
    
    func testAllDaySPAForDateWithSecondResolution() {
        var dateComponents = DateComponents()
        dateComponents.year = 2003
        dateComponents.month = 10
        dateComponents.day = 17
        
        let coordinate = CLLocationCoordinate2D(latitude: 39.742476, longitude: -105.1786)
        let offset = -7
        let elevation = 1830.14
        
        let date = Calendar.current.date(from: dateComponents)!
        
        var slowPositions = [SunPosition]()
        
        for hour in 0..<24 {
            dateComponents.hour = hour
            
            for minute in 0..<60 {
                dateComponents.minute = minute
                
                for second in 0..<60 {
                    dateComponents.second = second
                    
                    let date = Calendar.current.date(from: dateComponents)!
                    
                    let sunPosition = NRELSunPosition(for: date, timeZoneOffset: offset, coordinate: coordinate, elevation: elevation, fragments: FullSunPositionFragments)
                    slowPositions.append(sunPosition)
                }
            }
        }
        
        let fastPositions = NRELSunPositions(for: date, withResolution: .second, timeZoneOffset: offset, coordinate: coordinate, elevation: elevation, fragments: FullSunPositionFragments)
        
        XCTAssertEqual(fastPositions.count, 24*60*60)
        
        for index in 0..<24*60*60 {
            let value1 = slowPositions[index]
            let value2 = fastPositions[index]
            
            XCTAssertEqual(value1.ascension!, value2.ascension!, accuracy: SunshineKitAccuracy)
            XCTAssertEqual(value1.azimuth!, value2.azimuth!, accuracy: SunshineKitAccuracy)
            // TODO: why is the accuracy lower?
            XCTAssertEqual(value1.height!, value2.height!, accuracy: SunshineKitAccuracy*10, "index \(index) failed")
            XCTAssertEqual(value1.incidence!, value2.incidence!, accuracy: SunshineKitAccuracy*10, "index \(index) failed")
            XCTAssertEqual(value1.zenith!, value2.zenith!, accuracy: SunshineKitAccuracy*10, "index \(index) failed")
            XCTAssertEqual(value1.shadow!.direction!, value2.shadow!.direction!, accuracy: SunshineKitAccuracy)
            XCTAssertEqual(value1.shadow!.length!, value2.shadow!.length!, accuracy: SunshineKitAccuracy*10000, "index \(index) failed")
        }
    }
    
    
    func testAllDaySPAForDateWithMinuteResolution() {
        var dateComponents = DateComponents()
        dateComponents.year = 2003
        dateComponents.month = 10
        dateComponents.day = 17
        
        let coordinate = CLLocationCoordinate2D(latitude: 39.742476, longitude: -105.1786)
        let offset = -7
        let elevation = 1830.14
        
        let date = Calendar.current.date(from: dateComponents)!
        
        var slowPositions = [SunPosition]()
        
        for hour in 0..<24 {
            dateComponents.hour = hour
            
            for minute in 0..<60 {
                dateComponents.minute = minute
                
                let date = Calendar.current.date(from: dateComponents)!
                
                let sunPosition = NRELSunPosition(for: date, timeZoneOffset: offset, coordinate: coordinate, elevation: elevation, fragments: FullSunPositionFragments)
                slowPositions.append(sunPosition)
            }
        }
        
        let fastPositions = NRELSunPositions(for: date, withResolution: .minute, timeZoneOffset: offset, coordinate: coordinate, elevation: elevation, fragments: FullSunPositionFragments)
        
        XCTAssertEqual(fastPositions.count, 1440)
        
        for index in 0..<24*60 {
            let value1 = slowPositions[index]
            let value2 = fastPositions[index]
            
            XCTAssertEqual(value1.ascension!, value2.ascension!, accuracy: SunshineKitAccuracy)
            XCTAssertEqual(value1.azimuth!, value2.azimuth!, accuracy: SunshineKitAccuracy)
            XCTAssertEqual(value1.height!, value2.height!, accuracy: SunshineKitAccuracy)
            XCTAssertEqual(value1.incidence!, value2.incidence!, accuracy: SunshineKitAccuracy)
            XCTAssertEqual(value1.zenith!, value2.zenith!, accuracy: SunshineKitAccuracy)
            XCTAssertEqual(value1.shadow!.direction!, value2.shadow!.direction!, accuracy: SunshineKitAccuracy)
            XCTAssertEqual(value1.shadow!.length!, value2.shadow!.length!, accuracy: SunshineKitAccuracy)
        }
    }
    
    
    func testAllDaySPAForDateWithHourResolution() {
        var dateComponents = DateComponents()
        dateComponents.year = 2003
        dateComponents.month = 10
        dateComponents.day = 17
        
        let coordinate = CLLocationCoordinate2D(latitude: 39.742476, longitude: -105.1786)
        let offset = -7
        let elevation = 1830.14
        
        let date = Calendar.current.date(from: dateComponents)!
        
        var slowPositions = [SunPosition]()
        
        for hour in 0..<24 {
            dateComponents.hour = hour
            
            let date = Calendar.current.date(from: dateComponents)!
            
            let sunPosition = NRELSunPosition(for: date, timeZoneOffset: offset, coordinate: coordinate, elevation: elevation, fragments: FullSunPositionFragments)
            slowPositions.append(sunPosition)
        }
        
        let fastPositions = NRELSunPositions(for: date, withResolution: .hour, timeZoneOffset: offset, coordinate: coordinate, elevation: elevation, fragments: FullSunPositionFragments)
        
        XCTAssertEqual(fastPositions.count, 24)
        
        for index in 0..<24 {
            let value1 = slowPositions[index]
            let value2 = fastPositions[index]
            
            XCTAssertEqual(value1.ascension!, value2.ascension!, accuracy: SunshineKitAccuracy)
            XCTAssertEqual(value1.azimuth!, value2.azimuth!, accuracy: SunshineKitAccuracy)
            XCTAssertEqual(value1.height!, value2.height!, accuracy: SunshineKitAccuracy)
            XCTAssertEqual(value1.incidence!, value2.incidence!, accuracy: SunshineKitAccuracy)
            XCTAssertEqual(value1.zenith!, value2.zenith!, accuracy: SunshineKitAccuracy)
            XCTAssertEqual(value1.shadow!.direction!, value2.shadow!.direction!, accuracy: SunshineKitAccuracy)
            XCTAssertEqual(value1.shadow!.length!, value2.shadow!.length!, accuracy: SunshineKitAccuracy)
        }
    }
    
    
    // MARK: - Performance tests
    
    
    func testFullSunPositionPerformance() {
        let now = Date()
        let coordinate = CLLocationCoordinate2D(latitude: 13.0, longitude: 53.0)
        
        measure {
            for _ in 0..<60 {
                _ = NRELSunPosition(for: now, timeZoneOffset: 0, coordinate: coordinate, elevation: 0, fragments: FullSunPositionFragments)
            }
        }
    }
    
    
    func testOnePropertySunPositionPerformance() {
        let now = Date()
        let coordinate = CLLocationCoordinate2D(latitude: 13.0, longitude: 53.0)
        let onlyAzimuthFragment: [SunPositionFragment] = [.azimuth]
        
        measure {
            for _ in 0..<60 {
                _ = NRELSunPosition(for: now, timeZoneOffset: 0, coordinate: coordinate, elevation: 0, fragments: onlyAzimuthFragment)
            }
        }
    }
    
    
    func testSunPositionVDSPPerformance() {
        let now = Date()
        let coordinate = CLLocationCoordinate2D(latitude: 13.0, longitude: 53.0)
        
        measure {
            _ = NRELSunPositions(for: now, forHour: 12, withResolution: .minute, timeZoneOffset: 0, coordinate: coordinate, elevation: 0, fragments: FullSunPositionFragments)
        }
    }
    
    
    func testOnePropertySunPositionVDSPPerformance() {
        let now = Date()
        let coordinate = CLLocationCoordinate2D(latitude: 13.0, longitude: 53.0)
        let onlyAzimuthFragment: [SunPositionFragment] = [.azimuth]
        
        measure {
            _ = NRELSunPositions(for: now, forHour: 12, withResolution: .minute, timeZoneOffset: 0, coordinate: coordinate, elevation: 0, fragments: onlyAzimuthFragment)
        }
    }
}
