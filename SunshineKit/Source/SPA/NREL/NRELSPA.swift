//
//  SPACalculator.swift
//  SunshineKit
//
//  Created by Oleg Mueller on 25.06.16.
//  Copyright © 2016 Oleg Mueller. All rights reserved.
//


import Foundation
import CoreLocation
import Accelerate


/// Used for unit tests
public let SunshineKitAccuracy = 0.000001

public let SunshineKitDefaultPressure = 1010.0
public let SunshineKitDefaultTemperature = 10.0
public let SunshineKitDefaultSlope = 30.0
public let SunshineKitDefaultSurfaceAzimuth = -10.0
public let SunshineKitDefaultBuildingHeight = 10.0


// MARK: - SPA


/**
 Calculates SunPositions for the whole day or hour with the desired resolution (one SunPosition per hour or per minute or per second).
 
 Source is the NREL [Article](http://rredc.nrel.gov/solar/codesandalgorithms/spa/)
 
 - parameter date: The point in time (day) to calculate the sun positions for
 - parameter forHour: An optional hour, if set SunPositions are only calculated for this hour
 - parameter withResolution: The desired resolution
 - parameter timeZoneOffset: Offset from UTC in hours
 - parameter coordinate: The point on earth to calculate the sun positions for
 - parameter elevation: The height above Zero for the given location
 - parameter fragments: The selected SunPosition properties you need to calculate (fewer means faster processing)
 - parameter pressure: In Millibar, defaults to 1010
 - parameter temperature: In Celcius, defaults to 10
 - parameter slope: In Meter, defaults to 30
 - parameter surfaceAzimuth: In Meter, defaults to -10
 - parameter buildingHeight: In Meter, defaults to 10 (for shadow calculation)
 
 - returns: One SunPosition object per date with the given resolution and selected properties (Fragments)
 */
public func NRELSunPositions(for date: Date, forHour hour: Int? = nil, withResolution resolution: JulianDayResolution, timeZoneOffset: Int, coordinate: CLLocationCoordinate2D, elevation: Double, fragments: [SunPositionFragment], pressure: Double = SunshineKitDefaultPressure, temperature: Double = SunshineKitDefaultTemperature, slope: Double = SunshineKitDefaultSlope, surfaceAzimuth: Double = SunshineKitDefaultSurfaceAzimuth, buildingHeight: Double = SunshineKitDefaultBuildingHeight) -> [SunPosition] {
    let calculation_tupel = bool(for: fragments)
    
    var JD = julianDays(for: date, forHour: hour, timeZoneOffset: timeZoneOffset, withResolution: resolution) // 2452930.312847
    
    let count = JD.count
    
    // 3.1.2. Calculate the Julian Ephemeris Day (JDE)
    var JDE = julianEphemerisDays(for: JD) // 2452930.3136226851
    
    // 3.1.3. Calculate the Julian century (JC) and the Julian Ephemeris Century (JCE) for the 2000 standard epoch
    var JC = julianCenturies(for: JD) // 0.03792779869191517 0.03792779869191517
    var JCE = julianCenturies(for: JDE) // 0.037927819922933585
    
    // free memory
    JDE = []
    
    // 3.1.4. Calculate the Julian Ephemeris Millennium (JME) for the 2000 standard epoch
    var JME = julianEphemerisMillenias(for: JCE) // 0.0037927819922933584
    
    
    var tempArray = Array<Double>(repeating: 0, count: count)
    var secondTempArray = tempArray
    let length = vDSP_Length(count)
    var int32Count = Int32(count)
    
    
    // 3.2.1. and 3.2.2. Calculate the term L0 (in radians)
    var L0 = calculateTerms(with: L_TERMS, index: 0, ephemerisMillenia: JME) // 172067561.52658555
    // 3.2.3. Calculate the terms L1, L2, L3, L4, and L5
    var L1 = calculateTerms(with: L_TERMS, index: 1, ephemerisMillenia: JME) // 628332010650.05115
    var L2 = calculateTerms(with: L_TERMS, index: 2, ephemerisMillenia: JME) // 61368.682493387161
    var L3 = calculateTerms(with: L_TERMS, index: 3, ephemerisMillenia: JME) // -26.90281881244934
    var L4 = calculateTerms(with: L_TERMS, index: 4, ephemerisMillenia: JME) // -121.27953627276293
    var L5 = calculateTerms(with: L_TERMS, index: 5, ephemerisMillenia: JME) // -0.9999987317275395
    var L = Array<Double>(repeating: 0, count: count)
    // 3.2.4. Calculate the Earth heliocentric longitude, L (in radians)
    // multiply L1 with JME add L0 vector and save in L
    vDSP_vmaD(L1, 1, JME, 1, L0, 1, &L, 1, length)
    // jme power 2
    var power2Array = Array<Double>(repeating: 2.0, count: count)
    vvpow(&tempArray, &power2Array, JME, &int32Count)
    // multiply L2 with JME*2 and add to L vector
    secondTempArray = L
    vDSP_vmaD(L2, 1, &tempArray, 1, &secondTempArray, 1, &L, 1, length)
    // jme power 3
    var power3Array = Array<Double>(repeating: 3.0, count: count)
    vvpow(&tempArray, &power3Array, JME, &int32Count)
    // multiply L3 with JME*3 and add to L vector
    secondTempArray = L
    vDSP_vmaD(L3, 1, &tempArray, 1, &secondTempArray, 1, &L, 1, length)
    // jme power 4
    var power4Array = Array<Double>(repeating: 4.0, count: count)
    vvpow(&tempArray, &power4Array, JME, &int32Count)
    // multiply L4 with JME*4 and add to L vector
    secondTempArray = L
    vDSP_vmaD(L4, 1, &tempArray, 1, &secondTempArray, 1, &L, 1, length)
    // jme power 5
    var power5Array = Array<Double>(repeating: 5.0, count: count)
    vvpow(&tempArray, &power5Array, JME, &int32Count)
    // multiply L5 with JME*5 and add to L vector
    secondTempArray = L
    vDSP_vmaD(L5, 1, &tempArray, 1, &secondTempArray, 1, &L, 1, length) // 2555193897.5843773
    // divide L through 100000000.0
    var divider = 100000000.0
    secondTempArray = L
    vDSP_vsdivD(&secondTempArray, 1, &divider, &L, 1, length)
    // 3.2.5. Calculate L in degrees,
    var L_degree_values = radsToAngles(L) // 25.551938975843772
    // 3.2.6. Limit L to the range from 0/ to 360/
    L_degree_values = clampAnglesToThreeSixty(L_degree_values) // 24.018261691679399
    
    // free memory
    L0 = []
    L1 = []
    L2 = []
    L3 = []
    L4 = []
    L5 = []
    L = []
    
    
    // 3.2.7. Calculate the Earth heliocentric latitude,
    var B = Array<Double>(repeating: 0, count: count) // -0.0000017649105337201631
    var B0 = calculateTerms(with: B_TERMS, index: 0, ephemerisMillenia: JME)
    B0 = radsToAngles(B0)
    var B1 = calculateTerms(with: B_TERMS, index: 1, ephemerisMillenia: JME)
    B1 = radsToAngles(B1)
    // multiply B1Values with JME and add it to B0Values
    vDSP_vmaD(B1, 1, JME, 1, B0, 1, &B, 1, length)
    // divide B through 100000000.0
    secondTempArray = B
    vDSP_vsdivD(&secondTempArray, 1, &divider, &B, 1, length)
    
    // free memory
    B0 = []
    B1 = []
    
    
    // 3.2.8. Calculate the Earth radius vector, R
    var R = Array<Double>(repeating: 0, count: count)
    var R0 = calculateTerms(with: R_TERMS, index: 0, ephemerisMillenia: JME)
    var R1 = calculateTerms(with: R_TERMS, index: 1, ephemerisMillenia: JME)
    var R2 = calculateTerms(with: R_TERMS, index: 2, ephemerisMillenia: JME)
    var R3 = calculateTerms(with: R_TERMS, index: 3, ephemerisMillenia: JME)
    var R4 = calculateTerms(with: R_TERMS, index: 4, ephemerisMillenia: JME)
    // add R0 vector
    vDSP_vaddD(R0, 1, R, 1, &R, 1, length)
    // multiply R1 with JME and add to R vector
    vDSP_vmaD(R1, 1, JME, 1, R, 1, &R, 1, length)
    // jme power 2
    vvpow(&tempArray, &power2Array, JME, &int32Count)
    // multiply R2 with JME*2 and add to R vector
    secondTempArray = R
    vDSP_vmaD(R2, 1, &tempArray, 1, &secondTempArray, 1, &R, 1, length)
    // jme power 3
    vvpow(&tempArray, &power3Array, JME, &int32Count)
    // multiply R3 with JME*3 and add to R vector
    secondTempArray = R
    vDSP_vmaD(R3, 1, &tempArray, 1, &secondTempArray, 1, &R, 1, length)
    // jme power 4
    vvpow(&tempArray, &power4Array, JME, &int32Count)
    // multiply R4 with JME*4 and add to R vector
    secondTempArray = R
    vDSP_vmaD(R4, 1, &tempArray, 1, &secondTempArray, 1, &R, 1, length)
    // divide R through 100000000.0
    secondTempArray = R
    vDSP_vsdivD(&secondTempArray, 1, &divider, &R, 1, length)
    
    // make some memory free again
    R0 = []
    R1 = []
    R2 = []
    R3 = []
    R4 = []
    power2Array = []
    power3Array = []
    power4Array = []
    power5Array = []
    
    
    // 3.3.1. Calculate the geocentric longitude, 1 (in degrees)
    var Θ: [Angle] = Array<Angle>(repeating: 0, count: count)
    var oneHundredEighty = 180.0
    vDSP_vsaddD(L_degree_values, 1, &oneHundredEighty, &Θ, 1, length)
    
    
    // free memory
    L_degree_values = []
    
    
    // 3.3.2. Limit 1 to the range from 0 to 360
    Θ = clampAnglesToThreeSixty(Θ)
    //let Θ_rad: [Rad] = anglesToRads(Θ)
    
    
    // 3.3.3. Calculate the geocentric latitude, beta (in degrees),
    var βValues: [Angle] = Array<Angle>(repeating: 0, count: count)
    var minusOne = -1.0
    vDSP_vsmulD(B, 1, &minusOne, &βValues, 1, length)
    var β_rad = anglesToRads(βValues)
    
    // free memory
    βValues = []
    B = []
    
    
    // 3.4.1. Calculate the mean elongation of the moon from the sun, X0 (in degrees) // ((a*x + b)*x + c)*x + d;
    var X0: [Angle] = Array<Angle>(repeating: 0, count: count)
    let X0_coefficients = [1.0/189474.0, -0.0019142, 445267.111480, 297.85036]
    vDSP_vpolyD(X0_coefficients, 1, JCE, 1, &X0, 1, length, vDSP_Length(X0_coefficients.count - 1))
    
    
    // 3.4.2. Calculate the mean anomaly of the sun (Earth), X1 (in degrees)
    var X1: [Angle] = Array<Angle>(repeating: 0, count: count)
    let X1_coefficients = [-1.0/300000.0, -0.0001603, 35999.050340, 357.52772]
    vDSP_vpolyD(X1_coefficients, 1, JCE, 1, &X1, 1, length, vDSP_Length(X1_coefficients.count - 1))
    
    
    // 3.4.3. Calculate the mean anomaly of the moon, X2 (in degrees)
    var X2: [Angle] = Array<Angle>(repeating: 0, count: count)
    let X2_coefficients = [1.0/56250.0, 0.0086972, 477198.867398, 134.96298]
    vDSP_vpolyD(X2_coefficients, 1, JCE, 1, &X2, 1, length, vDSP_Length(X2_coefficients.count - 1))
    
    
    // 3.4.4. Calculate the moon’s argument of latitude, X3 (in degrees)
    var X3: [Angle] = Array<Angle>(repeating: 0, count: count)
    let X3_coefficients = [1.0/327270.0, -0.0036825, 483202.017538, 93.27191]
    vDSP_vpolyD(X3_coefficients, 1, JCE, 1, &X3, 1, length, vDSP_Length(X3_coefficients.count - 1))
    
    
    // 3.4.5. Calculate the longitude of the ascending node of the moon’s mean orbit on the ecliptic, measured from the mean equinox of the date, X4 (in degrees)
    var X4: [Angle] = Array<Angle>(repeating: 0, count: count)
    let X4_coefficients = [1.0/450000.0, 0.0020708, -1934.136261, 125.04452]
    vDSP_vpolyD(X4_coefficients, 1, JCE, 1, &X4, 1, length, vDSP_Length(X4_coefficients.count - 1))
    
    
    // 3.4.6. to 3.4.8
    var ΔΨ: [Angle] = Array<Angle>(repeating: 0, count: count)
    var Δε: [Angle] = Array<Angle>(repeating: 0, count: count)
    
    for i in 0..<Y_TERMS.count {
        var Ψ: [Angle] = Array<Angle>(repeating: 0, count: count)
        var ε: [Angle] = Array<Angle>(repeating: 0, count: count)
        
        var sum: [Angle] = Array<Angle>(repeating: 0, count: count)
        
        let y_array = Y_TERMS[i]
        var y0 = y_array[0]
        var y1 = y_array[1]
        var y2 = y_array[2]
        var y3 = y_array[3]
        var y4 = y_array[4]
        
        let pe_array = PE_TERMS[i]
        var a = pe_array[0]
        var b = pe_array[1]
        var c = pe_array[2]
        var d = pe_array[3]
        
        // X0*y0
        vDSP_vsmulD(X0, 1, &y0, &sum, 1, length)
        // + X1*y1
        tempArray = sum
        vDSP_vsmaD(X1, 1, &y1, &tempArray, 1, &sum, 1, length)
        // + X2*y2
        tempArray = sum
        vDSP_vsmaD(X2, 1, &y2, &tempArray, 1, &sum, 1, length)
        // + X3*y3
        tempArray = sum
        vDSP_vsmaD(X3, 1, &y3, &tempArray, 1, &sum, 1, length)
        // + X4*y4
        tempArray = sum
        vDSP_vsmaD(X4, 1, &y4, &tempArray, 1, &sum, 1, length)
        
        let sum_rad: [Rad] = anglesToRads(sum)
        
        // (a + b*JCE)
        vDSP_vsmulD(JCE, 1, &b, &sum, 1, length)
        tempArray = sum
        vDSP_vsaddD(&tempArray, 1, &a, &sum, 1, length)
        
        var temp: [Rad] = Array<Rad>(repeating: 0, count: count)
        // sin(sum_rad)
        vvsin(&temp, sum_rad, &int32Count)
        
        // (a + b*JCE)*sin(sum_rad)
        vDSP_vmulD(&sum, 1, &temp, 1, &Ψ, 1, length)
        // ΔΨ += Ψ
        vDSP_vaddD(ΔΨ, 1, Ψ, 1, &ΔΨ, 1, length)
        
        // cos(sum_rad)
        vvcos(&temp, sum_rad, &int32Count)
        
        // (c + d*JCE)
        vDSP_vsmulD(JCE, 1, &d, &sum, 1, length)
        tempArray = sum
        vDSP_vsaddD(&tempArray, 1, &c, &sum, 1, length)
        
        // (c + d*JCE)*cos(sum_rad)
        vDSP_vmulD(&sum, 1, &temp, 1, &ε, 1, length)
        // Δε += ε
        vDSP_vaddD(Δε, 1, ε, 1, &Δε, 1, length)
    }
    
    // free memory
    JCE = []
    X0 = []
    X1 = []
    X2 = []
    X3 = []
    X4 = []
    
    // ΔΨ = ΔΨ/36000000.0 // -0.003998404
    divider = 36000000.0
    vDSP_vsdivD(ΔΨ, 1, &divider, &ΔΨ, 1, length)
    // Δε = Δε/36000000.0 // 0.001666568
    vDSP_vsdivD(Δε, 1, &divider, &Δε, 1, length)
    
    
    // 3.5.1. Calculate the mean obliquity of the ecliptic, use tempArray as "U"
    divider = 10.0
    vDSP_vsdivD(JME, 1, &divider, &tempArray, 1, length)
    var ε0: [Angle] = Array<Angle>(repeating: 0, count: count)
    let ε0_coefficients = [2.45, 5.79, 27.87, 7.12, -39.05, -249.67, -51.38, 1999.25, -1.55, -4680.93, 84381.448]
    vDSP_vpolyD(ε0_coefficients, 1, tempArray, 1, &ε0, 1, length, vDSP_Length(ε0_coefficients.count - 1))
    
    // free memory
    JME = []
    
    // 3.5.2. Calculate the true obliquity of the ecliptic,
    var ε: [Angle] = Array<Angle>(repeating: 0, count: count)
    divider = 3600.0
    // ε0/3600.0
    vDSP_vsdivD(ε0, 1, &divider, &ε, 1, length)
    // ε0/3600.0 + Δε // 23.440465
    vDSP_vaddD(ε, 1, Δε, 1, &ε, 1, length)
    var ε_rad: [Rad] = anglesToRads(ε) // 0.409113
    
    
    // free memory
    ε = []
    Δε = []
    ε0 = []
    
    
    // 3.6. Calculate the aberration correction
    var Δτ: [Angle] = Array<Angle>(repeating: 0, count: count)
    var multiplier = 3600.0
    vDSP_vsmulD(R, 1, &multiplier, &Δτ, 1, length)
    tempArray = Array<Angle>(repeating: -20.4898, count: count)
    vDSP_vdivD(Δτ, 1, tempArray, 1, &Δτ, 1, length)
    
    
    // 3.7 Calculate the apparent sun longitude
    var λ: [Angle] = Array<Angle>(repeating: 0, count: count)
    // Θ + ΔΨ + Δτ // 204.008552
    vDSP_vaddD(Θ, 1, ΔΨ, 1, &λ, 1, length)
    vDSP_vaddD(λ, 1, Δτ, 1, &λ, 1, length)
    var λ_rad: [Rad] = anglesToRads(λ) // 3.560621
    
    // free memory
    Θ = []
    Δτ = []
    λ = []
    
    
    // 3.8.1. Calculate the mean sidereal time at Greenwich
    // 280.46061837 + 360.98564736629*(JD - 2451545.0) + JC*JC*(0.000387933 - JC/38710000.0)
    var ν0: [Angle] = Array<Angle>(repeating: 0, count: count)
    // (JD - 2451545.0)
    var addValue = -2451545.0
    vDSP_vsaddD(JD, 1, &addValue, &tempArray, 1, length)
    // 360.98564736629*(JD - 2451545.0)
    var multiplyValue = 360.98564736629
    vDSP_vsmulD(tempArray, 1, &multiplyValue, &tempArray, 1, length)
    // 280.46061837 + 360.98564736629*(JD - 2451545.0)
    addValue = 280.46061837
    vDSP_vsaddD(tempArray, 1, &addValue, &ν0, 1, length)
    // JC*JC
    vDSP_vmulD(JC, 1, JC, 1, &tempArray, 1, length)
    // JC/38710000.0
    divider = -38710000.0
    vDSP_vsdivD(JC, 1, &divider, &secondTempArray, 1, length)
    // (0.000387933 - JC/38710000.0)
    addValue = 0.000387933
    vDSP_vsaddD(secondTempArray, 1, &addValue, &secondTempArray, 1, length)
    // JC*JC*(0.000387933 - JC/38710000.0)
    vDSP_vmulD(tempArray, 1, &secondTempArray, 1, &tempArray, 1, length)
    // 280.46061837 + 360.98564736629*(JD - 2451545.0) + JC*JC*(0.000387933 - JC/38710000.0)
    vDSP_vaddD(ν0, 1, &tempArray, 1, &ν0, 1, length)
    
    // free memory
    JD = []
    JC = []
    
    // 3.8.2. Limit v_zero to the range from 0 to 360
    ν0 = clampAnglesToThreeSixty(ν0)
    
    
    // 3.8.3. Calculate the apparent sidereal time at Greenwich
    var ν: [Angle] = Array<Angle>(repeating: 0, count: count)
    vDSP_vaddD(ν, 1, ν0, 1, &ν, 1, length)
    // cos(ε_rad)
    var ε_cos: [Rad] = Array<Rad>(repeating: 0, count: count)
    vvcos(&ε_cos, ε_rad, &int32Count)
    // ΔΨ*cos(ε_rad)
    vDSP_vmulD(&ε_cos, 1, ΔΨ, 1, &secondTempArray, 1, length)
    // ν0 + ΔΨ*cos(ε_rad)
    vDSP_vaddD(ν0, 1, secondTempArray, 1, &ν, 1, length)
    
    
    // free memory
    ΔΨ = []
    ν0 = []
    
    
    // 3.9.1. Calculate the sun right ascension
    var atan_nominator: [Rad] = Array<Rad>(repeating: 0, count: count)
    // sin(λ_rad)
    var λ_sin: [Rad] = Array<Rad>(repeating: 0, count: count)
    vvsin(&λ_sin, &λ_rad, &int32Count)
    // sin(λ_rad)*cos(ε_rad), tempArray still constains cos(ε_rad)
    vDSP_vmulD(ε_cos, 1, λ_sin, 1, &atan_nominator, 1, length)
    // tan(β_rad)
    vvtan(&tempArray, β_rad, &int32Count)
    // sin(ε_rad)
    var ε_sin: [Rad] = Array<Rad>(repeating: 0, count: count)
    vvsin(&ε_sin, ε_rad, &int32Count)
    // tan(β_rad)*sin(ε_rad)
    vDSP_vmulD(tempArray, 1, ε_sin, 1, &tempArray, 1, length)
    // sin(λ_rad)*cos(ε_rad) - tan(β_rad)*sin(ε_rad)
    vDSP_vsubD(tempArray, 1, atan_nominator, 1, &atan_nominator, 1, length)
    // cos(λ_rad)
    vvcos(&tempArray, λ_rad, &int32Count)
    var α: [Rad] = Array<Rad>(repeating: 0, count: count)
    // atan2(atan_nominator, atan_denominator)
    vvatan2(&α, atan_nominator, tempArray, &int32Count)
    
    // free memory
    atan_nominator = []
    
    
    // 3.9.2. Calculate alhpa in degrees using Equation 12, then limit it to the range from 0 to 360
    var α_degrees = radsToAngles(α)
    α_degrees = clampAnglesToThreeSixty(α_degrees) //
    
    // free memory
    α = []
    
    
    // 3.10. Calculate the geocentric sun declination
    // sin(β_rad)
    vvsin(&tempArray, β_rad, &int32Count)
    // cos(β_rad)
    vvcos(&secondTempArray, β_rad, &int32Count)
    var δ: [Rad] = Array<Rad>(repeating: 0, count: count)
    // sin(β_rad)*cos(ε_rad)
    vDSP_vmulD(tempArray, 1, ε_cos, 1, &tempArray, 1, length)
    // cos(β_rad)*sin(ε_rad)
    vDSP_vmulD(secondTempArray, 1, ε_sin, 1, &secondTempArray, 1, length)
    // cos(β_rad)*sin(ε_rad)*sin(λ_rad)
    vDSP_vmulD(secondTempArray, 1, λ_sin, 1, &secondTempArray, 1, length)
    // sin(β_rad)*cos(ε_rad) + cos(β_rad)*sin(ε_rad)*sin(λ_rad)
    vDSP_vaddD(tempArray, 1, secondTempArray, 1, &tempArray, 1, length)
    // asin(sin(β_rad)*cos(ε_rad) + cos(β_rad)*sin(ε_rad)*sin(λ_rad))
    vvasin(&δ, tempArray, &int32Count)
    
    // free memory
    β_rad = []
    ε_rad = []
    λ_rad = []
    ε_cos = []
    λ_sin = []
    ε_sin = []
    
    
    // 3.11. Calculate the observer local hour angle
    var H: [Angle] = Array<Angle>(repeating: coordinate.longitude, count: count)
    // ν + coordinate.longitude
    vDSP_vaddD(ν, 1, H, 1, &H, 1, length)
    // ν + coordinate.longitude - α_degrees
    vDSP_vsubD(α_degrees, 1, H, 1, &H, 1, length)
    H = clampAnglesToThreeSixty(H) // 11.105902
    var H_rad = anglesToRads(H) // 0.193835
    
    // free memory
    ν = []
    
    
    // 3.12.1. Calculate the equatorial horizontal parallax of the sun
    var ξ: [Angle] = Array<Angle>(repeating: 8.794, count: count)
    // (3600.0*R)
    multiplier = 3600.0
    vDSP_vsmulD(R, 1, &multiplier, &tempArray, 1, length)
    // 8.794/(3600.0*R)
    vDSP_vdivD(tempArray, 1, ξ, 1, &ξ, 1, length)
    var ξ_rad = anglesToRads(ξ) // 0.000043
    
    
    // free memory
    ξ = []
    R = []
    
    
    // 3.12.2. Calculate the term u
    let latitude_rad = angleToRad(coordinate.latitude) // 0.693637
    var u: [Rad] = Array<Rad>(repeating: latitude_rad, count: count)
    // tan(latitude_rad)
    vvtan(&u, u, &int32Count)
    // 0.99664719*tan(latitude_rad)
    multiplier = 0.99664719
    tempArray = u
    vDSP_vsmulD(&tempArray, 1, &multiplier, &u, 1, length)
    // atan(0.99664719*tan(latitude_rad))
    vvatan(&u, u, &int32Count)
    
    
    // 3.12.3. Calculate the term x
    var latitude_cos: [Rad] = Array<Rad>(repeating: latitude_rad, count: count)
    // cos(latitude_rad)
    vvcos(&latitude_cos, latitude_cos, &int32Count)
    // cos(u)
    vvcos(&tempArray, u, &int32Count)
    // elevation/6378140.0
    multiplier = elevation/6378140.0
    // elevation/6378140.0*cos(latitude_rad)
    var x: [Rad] = Array<Rad>(repeating: 0, count: count)
    vDSP_vsmulD(latitude_cos, 1, &multiplier, &x, 1, length)
    // cos(u) + elevation/6378140.0*cos(latitude_rad)
    vDSP_vaddD(tempArray, 1, x, 1, &x, 1, length)
    
    
    // 3.12.4. Calculate the term y
    var latitude_sin: [Rad] = Array<Rad>(repeating: latitude_rad, count: count)
    // sin(latitude_rad)
    vvsin(&latitude_sin, latitude_sin, &int32Count)
    // sin(u)
    vvsin(&tempArray, u, &int32Count)
    // 0.99664719*sin(u)
    multiplier = 0.99664719
    secondTempArray = tempArray
    vDSP_vsmulD(&secondTempArray, 1, &multiplier, &tempArray, 1, length)
    // elevation/6378140.0*sin(latitude_rad)
    var y: [Rad] = Array<Rad>(repeating: 0, count: count)
    multiplier = elevation/6378140.0
    vDSP_vsmulD(latitude_sin, 1, &multiplier, &y, 1, length)
    // 0.99664719*sin(u) + elevation/6378140.0*sin(latitude_rad)
    vDSP_vaddD(&tempArray, 1, y, 1, &y, 1, length)
    
    
    // 3.12.5. Calculate the parallax in the sun right ascension
    var ξ_sin = Array<Rad>(repeating: 0, count: count)
    // sin(ξ_rad)
    vvsin(&ξ_sin, ξ_rad, &int32Count)
    // sin(H_rad)
    vvsin(&tempArray, H_rad, &int32Count)
    // cos(δ)
    vvcos(&secondTempArray, δ, &int32Count)
    var thirdTempArray: [Rad] = Array<Rad>(repeating: 0, count: count)
    // cos(H_rad)
    vvcos(&thirdTempArray, H_rad, &int32Count)
    var fourthTempArray: [Rad] = Array<Rad>(repeating: -1, count: count)
    // -x
    vDSP_vmulD(fourthTempArray, 1, x, 1, &fourthTempArray, 1, length)
    // -x*sin(H_rad)
    vDSP_vmulD(fourthTempArray, 1, tempArray, 1, &tempArray, 1, length)
    // -x*sin(H_rad)*sin(ξ_rad)
    vDSP_vmulD(tempArray, 1, ξ_sin, 1, &tempArray, 1, length)
    // -x*sin(ξ_rad)
    vDSP_vmulD(fourthTempArray, 1, ξ_sin, 1, &fourthTempArray, 1, length)
    // - x*sin(ξ_rad)*cos(H_rad)
    vDSP_vmulD(fourthTempArray, 1, thirdTempArray, 1, &fourthTempArray, 1, length)
    // cos(δ) - x*sin(ξ_rad)*cos(H_rad)
    vDSP_vaddD(secondTempArray, 1, fourthTempArray, 1, &fourthTempArray, 1, length)
    // atan2(-x*sin(ξ_rad)*sin(H_rad), cos(δ) - x*sin(ξ_rad)*cos(H_rad))
    var Δα: [Rad] = Array<Rad>(repeating: 0, count: count)
    vvatan2(&Δα, tempArray, fourthTempArray, &int32Count)
    var Δα_degrees: [Angle] = radsToAngles(Δα)
    
    
    // 3.12.6. Calculate the topocentric sun right ascension
    var α_new: [Angle]?
    if calculation_tupel.doCalculateAscension {
        var _α_new: [Angle] = Array<Angle>(repeating: 0, count: count)
        // α_degrees + Δα_degrees // 202.227039
        vDSP_vaddD(α_degrees, 1, Δα_degrees, 1, &_α_new, 1, length)
        α_new = _α_new
    }
    // free memory
    α_degrees = []
    
    
    // 3.12.7. Calculate the topocentric sun declination
    // sin(δ)
    vvsin(&tempArray, δ, &int32Count)
    // y*sin(ξ_rad)
    vDSP_vmulD(y, 1, ξ_sin, 1, &secondTempArray, 1, length)
    // sin(δ) - y*sin(ξ_rad)
    vDSP_vsubD(secondTempArray, 1, tempArray, 1, &tempArray, 1, length)
    // cos(Δα)
    vvcos(&secondTempArray, Δα, &int32Count)
    // (sin(δ) - y*sin(ξ_rad))*cos(Δα)
    vDSP_vmulD(tempArray, 1, secondTempArray, 1, &tempArray, 1, length)
    var δ_new: [Rad] = Array<Rad>(repeating: 0, count: count)
    // atan2((sin(δ) - y*sin(ξ_rad))*cos(Δα), cos(δ) - x*sin(ξ_rad)*cos(H_rad)) // -9.316179
    vvatan2(&δ_new, tempArray, fourthTempArray, &int32Count)
    
    // free memory
    ξ_sin = []
    δ = []
    ξ_rad = []
    Δα = []
    
    
    // 3.13. Calculate the topocentric local hour angle
    // H - Δα_degrees // 11.106271
    vDSP_vsubD(Δα_degrees, 1, H, 1, &tempArray, 1, length)
    var H_new_rad: [Rad] = anglesToRads(tempArray)
    
    // free memory
    Δα_degrees = []
    
    
    // 3.14.1. Calculate the topocentric elevation angle without atmospheric refraction correction
    var cos_H_new: [Rad] = Array<Rad>(repeating: 0, count: count)
    // cos(H_new_rad)
    vvcos(&cos_H_new, H_new_rad, &int32Count)
    var e: [Angle]?
    if calculation_tupel.doCalculateHeight || calculation_tupel.doCalculateIncidence || calculation_tupel.doCalculateZenith || calculation_tupel.doCalculateShadowLength {
        // sin(δ_new)
        vvsin(&secondTempArray, δ_new, &int32Count)
        // cos(δ_new)
        vvcos(&thirdTempArray, δ_new, &int32Count)
        // sin(latitude_rad)*sin(δ_new)
        vDSP_vmulD(latitude_sin, 1, secondTempArray, 1, &secondTempArray, 1, length)
        // cos(latitude_rad)*cos(δ_new)
        vDSP_vmulD(latitude_cos, 1, thirdTempArray, 1, &thirdTempArray, 1, length)
        // cos(latitude_rad)*cos(δ_new)*cos(H_new_rad))
        vDSP_vmulD(thirdTempArray, 1, cos_H_new, 1, &thirdTempArray, 1, length)
        // sin(latitude_rad)*sin(δ_new) + cos(latitude_rad)*cos(δ_new)*cos(H_new_rad)
        vDSP_vaddD(secondTempArray, 1, thirdTempArray, 1, &thirdTempArray, 1, length)
        var e0: [Rad] = Array<Rad>(repeating: 0, count: count)
        // asin(sin(latitude_rad)*sin(δ_new) + cos(latitude_rad)*cos(δ_new)*cos(H_new_rad))
        vvasin(&e0, thirdTempArray, &int32Count)
        var e0_degrees: [Angle] = radsToAngles(e0)
        
        
        // 3.14.2. Calculate the atmospheric refraction correction
        var Δe: [Rad] = Array<Rad>(repeating: 0, count: count)
        var pressure_temp = (pressure/1010.0)*(283.0/(273.0 + temperature))
        // (e0_degrees + 5.11)
        addValue = 5.11
        vDSP_vsaddD(e0_degrees, 1, &addValue, &tempArray, 1, length)
        // 10.3/(e0_degrees + 5.11)
        secondTempArray = Array<Double>(repeating: 10.3, count: count)
        vDSP_vdivD(tempArray, 1, secondTempArray, 1, &tempArray, 1, length)
        // e0_degrees + 10.3/(e0_degrees + 5.11))
        vDSP_vaddD(e0_degrees, 1, tempArray, 1, &tempArray, 1, length)
        tempArray = anglesToRads(tempArray)
        // tan(angleToRad(e0_degrees + 10.3/(e0_degrees + 5.11))))
        vvtan(&tempArray, tempArray, &int32Count)
        // 60.0*tan(angleToRad(e0_degrees + 10.3/(e0_degrees + 5.11))))
        multiplier = 60.0
        vDSP_vsmulD(tempArray, 1, &multiplier, &tempArray, 1, length)
        tempArray = radsToAngles(tempArray)
        // 1.02/(radToAngle(60.0*tan(angleToRad(e0_degrees + 10.3/(e0_degrees + 5.11)))))
        secondTempArray = Array<Double>(repeating: 1.02, count: count)
        vDSP_vdivD(tempArray, 1, secondTempArray, 1, &tempArray, 1, length)
        // (pressure/1010.0)*(283.0/(273.0 + temperature))*1.02/(radToAngle(60.0*tan(angleToRad(e0_degrees + 10.3/(e0_degrees + 5.11))))) // 0.016332
        vDSP_vsmulD(tempArray, 1, &pressure_temp, &Δe, 1, length)
        // FIXME: find vectorized solution
        // not in paper
        for index in 0..<e0.count {
            let e0 = e0[index]
            if e0 < -1*(SUN_RADIUS + 0.5667) {
                Δe[index] = 0
            }
        }
        var Δe_degrees: [Angle] = radsToAngles(Δe)
        
        // free memory
        Δe = []
        
        
        // 3.14.3. Calculate the topocentric elevation angle
        var _e: [Angle] = Array<Angle>(repeating: 0, count: count)
        // e0_degrees + Δe_degrees // 39.888378
        vDSP_vaddD(e0_degrees, 1, Δe_degrees, 1, &_e, 1, length)
        e = _e
        
        // free memory
        e0_degrees = []
        Δe_degrees = []
    }
 
    
    // 3.14.4. Calculate the topocentric zenith angle
    var zenith: [Angle]?
    var zenith_rad: [Rad]?
    if let e = e , calculation_tupel.doCalculateZenith || calculation_tupel.doCalculateIncidence {
        var _zenith: [Angle] = Array<Angle>(repeating: 90, count: count)
        // 90.0 - e // 50.111622
        vDSP_vsubD(e, 1, _zenith, 1, &_zenith, 1, length)
        zenith_rad = anglesToRads(_zenith)
        zenith = _zenith
    }
 
    
    // 3.15.1. Calculate the topocentric astronomers azimuth angle
    var Γ_degrees: [Angle]?
    var Φ: [Angle]?
    if calculation_tupel.doCalculateAzimuth || calculation_tupel.doCalculateIncidence || calculation_tupel.doCalculateShadowDirection {
        // sin(H_new_rad)
        vvsin(&tempArray, H_new_rad, &int32Count)
        // tan(δ_new)
        vvtan(&secondTempArray, δ_new, &int32Count)
        // cos(H_new_rad)*sin(latitude_rad)
        vDSP_vmulD(cos_H_new, 1, latitude_sin, 1, &thirdTempArray, 1, length)
        // tan(δ_new)*cos(latitude_rad)
        vDSP_vmulD(secondTempArray, 1, latitude_cos, 1, &secondTempArray, 1, length)
        // cos(H_new_rad)*sin(latitude_rad) - tan(δ_new)*cos(latitude_rad)
        vDSP_vsubD(secondTempArray, 1, thirdTempArray, 1, &secondTempArray, 1, length)
        var Γ: [Rad] = Array<Rad>(repeating: 0, count: count)
        // atan2(sin(H_new_rad), cos(H_new_rad)*sin(latitude_rad) - tan(δ_new)*cos(latitude_rad))
        vvatan2(&Γ, tempArray, secondTempArray, &int32Count)
        var Γ_deg: [Angle] = radsToAngles(Γ)
        Γ_deg = clampAnglesToThreeSixty(Γ_deg)
        Γ_degrees = Γ_deg
        
        // free memory
        latitude_cos = []
        latitude_sin = []
        H_rad = []
        δ_new = []
        H_new_rad = []
        Γ = []
        cos_H_new = []
        
        
        // 3.15.2. Calculate the topocentric azimuth angle, M for navigators and solar radiation users
        var _Φ: [Angle] = Array<Angle>(repeating: 0, count: count)
        // Γ_degrees + 180.0
        addValue = 180.0
        vDSP_vsaddD(Γ_deg, 1, &addValue, &_Φ, 1, length)
        Φ = clampAnglesToThreeSixty(_Φ) // 194.340241
    }
    
    // 3.16. Calculate the incidence angle for a surface oriented in any direction
    var I_degrees: [Angle]?
    if let zenith_rad = zenith_rad, let Γ_degrees = Γ_degrees , calculation_tupel.doCalculateIncidence {
        let slope_rad: Rad = angleToRad(slope)
        var cos_slope = cos(slope_rad)
        var sin_slope = sin(slope_rad)
        // cos(zenith_rad)
        vvcos(&tempArray, zenith_rad, &int32Count)
        // sin(zenith_rad)
        vvsin(&secondTempArray, zenith_rad, &int32Count)
        // Γ_degrees - surfaceAzimuth
        addValue = -surfaceAzimuth
        vDSP_vsaddD(Γ_degrees, 1, &addValue, &thirdTempArray, 1, length)
        // angleToRad(Γ_degrees - surfaceAzimuth)
        fourthTempArray = anglesToRads(thirdTempArray)
        // cos(angleToRad(Γ_degrees - surfaceAzimuth))
        vvcos(&thirdTempArray, fourthTempArray, &int32Count)
        // sin(zenith_rad)*cos(angleToRad(Γ_degrees - surfaceAzimuth))
        vDSP_vmulD(secondTempArray, 1, thirdTempArray, 1, &fourthTempArray, 1, length)
        // sin(slope_rad)*sin(zenith_rad)*cos(angleToRad(Γ_degrees - surfaceAzimuth))
        vDSP_vsmulD(fourthTempArray, 1, &sin_slope, &fourthTempArray, 1, length)
        // cos(zenith_rad)*cos(slope_rad)
        vDSP_vsmulD(tempArray, 1, &cos_slope, &tempArray, 1, length)
        // cos(zenith_rad)*cos(slope_rad) + sin(slope_rad)*sin(zenith_rad)*cos(angleToRad(Γ_degrees - surfaceAzimuth))
        vDSP_vaddD(tempArray, 1, fourthTempArray, 1, &tempArray, 1, length)
        var I: [Rad] = Array<Rad>(repeating: 0, count: count)
        // acos(cos(zenith_rad)*cos(slope_rad) + sin(slope_rad)*sin(zenith_rad)*cos(angleToRad(Γ_degrees - surfaceAzimuth)))
        vvacos(&I, tempArray, &int32Count)
        I_degrees = radsToAngles(I) // 25.187000
    }
    
    
    var shadowDirections: [Angle]?
    if let Φ = Φ , calculation_tupel.doCalculateShadowDirection {
        var _shadowDirections = Array<Angle>(repeating: 0, count: count)
        var minus_one_eighty = -180.0
        vDSP_vsaddD(Φ, 1, &minus_one_eighty, &_shadowDirections, 1, length)
        shadowDirections = _shadowDirections
    }
    
    
    var shadowLengths: [Double]?
    if let e = e , calculation_tupel.doCalculateShadowLength {
        // shadowLength = buildingHeight*(sin(angleToRad(90) - e_rad)/sin(e_rad))
        // e_rad
        tempArray = anglesToRads(e)
        // angleToRad(90)
        secondTempArray = Array<Double>(repeating: 90, count: count)
        secondTempArray = anglesToRads(secondTempArray)
        // angleToRad(90) - e_rad)
        vDSP_vsubD(tempArray, 1, secondTempArray, 1, &thirdTempArray, 1, length)
        // sin(angleToRad(90) - e_rad)
        vvsin(&thirdTempArray, thirdTempArray, &int32Count)
        // sin(e_rad)
        vvsin(&tempArray, tempArray, &int32Count)
        // sin(angleToRad(90) - e_rad)/sin(e_rad)
        vDSP_vdivD(tempArray, 1, thirdTempArray, 1, &tempArray, 1, length)
        // buildingHeight*(sin(angleToRad(90) - e_rad)/sin(e_rad))
        var buildingHeight = 10.0 // m
        vDSP_vsmulD(tempArray, 1, &buildingHeight, &tempArray, 1, length)
        shadowLengths = tempArray
    }
    
    let dates = date.allDatesForDateWith(resolution: resolution, for: hour)
    var sunPositions = [SunPosition]()
    
    for index in 0..<dates.count {
        let date = dates[index]
        
        var ascension: Angle?
        if let α_new = α_new {
            ascension = α_new[index]
        }
        
        var a: Angle?
        if let Φ = Φ {
            a = Φ[index]
        }
        
        var h: Angle?
        if let e = e {
            h = e[index]
        }
        
        var z: Angle?
        if let zenith = zenith {
            z = zenith[index]
        }
        
        var i: Angle?
        if let I_degrees = I_degrees {
            i = I_degrees[index]
        }
        
        var shadowDirection: Angle?
        if let shadowDirections = shadowDirections {
            shadowDirection = shadowDirections[index]
        }
        
        var shadowLength: Double?
        if let shadowLengths = shadowLengths {
            shadowLength = shadowLengths[index]
        }
        
        let sunPosition = SunPosition(date: date, ascension: ascension, azimuth: a, height: h, zenith: z, incidence: i, shadowDirection: shadowDirection, shadowLength: shadowLength)
        sunPositions.append(sunPosition)
    }
    
    return sunPositions
}


/**
 Calculates the SunPosition for a point in time.
 
 Source is the NREL [Article](http://rredc.nrel.gov/solar/codesandalgorithms/spa/)
 
 - parameter date: The point in time to calculate the sun position for
 - parameter timeZoneOffset: Offset from UTC in hours
 - parameter coordinate: The point on earth to calculate the sun position for
 - parameter elevation: The height above Zero for the given location
 - parameter fragments: The selected SunPosition properties you need to calculate (fewer means faster processing)
 - parameter pressure: In Millibar, defaults to 1010
 - parameter temperature: In Celcius, defaults to 10
 - parameter slope: In Meter, defaults to 30
 - parameter surfaceAzimuth: In Meter, defaults to -10
 - parameter buildingHeight: In Meter, defaults to 10 (for shadow calculation)
 
 - returns: SunPosition object for the date with the selected properties (Fragments)
 */
func NRELSunPosition(for date: Date, timeZoneOffset: Int, coordinate: CLLocationCoordinate2D, elevation: Double, fragments: [SunPositionFragment], pressure: Double = SunshineKitDefaultPressure, temperature: Double = SunshineKitDefaultTemperature, slope: Double = SunshineKitDefaultSlope, surfaceAzimuth: Double = SunshineKitDefaultSurfaceAzimuth, buildingHeight: Double = SunshineKitDefaultBuildingHeight) -> SunPosition {
    let calculation_tupel = bool(for: fragments)
    
    let JD = julianDay(for: date, timeZoneOffset: timeZoneOffset) // 2452930.3128472222
    
    // 3.1.2. Calculate the Julian Ephemeris Day (JDE)
    let JDE = julianEphemerisDay(for: JD) // 2452930.3136226851
    
    // 3.1.3. Calculate the Julian century (JC) and the Julian Ephemeris Century (JCE) for the 2000 standard epoch
    let JC = julianCentury(for: JD) // 0.03792779869191517
    let JCE = julianCentury(for: JDE) // 0.037927819922933585
    
    // 3.1.4. Calculate the Julian Ephemeris Millennium (JME) for the 2000 standard epoch
    let JME = julianEphemerisMillenium(for: JCE) // 0.0037927819922933584
    
    // 3.2.8. Calculate the Earth radius vector, R
    let R0 = calculateTerm(with: R_TERMS, index: 0, ephemerisMillenium: JME)
    let R1 = calculateTerm(with: R_TERMS, index: 1, ephemerisMillenium: JME)
    let R2 = calculateTerm(with: R_TERMS, index: 2, ephemerisMillenium: JME)
    let R3 = calculateTerm(with: R_TERMS, index: 3, ephemerisMillenium: JME)
    let R4 = calculateTerm(with: R_TERMS, index: 4, ephemerisMillenium: JME)
    let R_nominator = R0 + R1*JME + R2*pow(JME, 2) + R3*pow(JME, 3) + R4*pow(JME, 4)
    let R = R_nominator/100000000.0 // 0.996542
    
    // 3.3.1. Calculate the geocentric longitude, 1 (in degrees)
    let Θ: Angle = geocentricLongitude(for: JME)
    
    // 3.3.3. Calculate the geocentric latitude, beta (in degrees),
    let β_rad = geocentricLatitude(for: JME)
    
    let tupel = trueObliquityEcliptic(for: JCE, JME: JME)
    let ΔΨ: Angle = tupel.ΔΨ.angle
    let ε_rad: Rad = tupel.ε_rad
    
    // 3.7 Calculate the apparent sun longitude
    let λ_rad = apparentSunLongitude(for: JME, Θ: Θ, ΔΨ: ΔΨ)
    
    // 3.8.1. Calculate the mean sidereal time at Greenwich
    let left = 280.46061837 + 360.98564736629*(JD - 2451545.0)
    let right = JC*JC*(0.000387933 - JC/38710000.0)
    var ν0: Angle = left + right // 318.515578
    
    // 3.8.2. Limit v_zero to the range from 0 to 360
    ν0 = clampAngleToThreeSixty(ν0)
    
    // 3.8.3. Calculate the apparent sidereal time at Greenwich
    let ν: Angle = apparentSiderealTimeAtGreenwich(for: JD, JC: JC, ε_rad: ε_rad, ΔΨ: ΔΨ)
    
    // 3.9.1. Calculate the sun right ascension
    let α = sunRightAscension(for: β_rad, ε_rad: ε_rad, λ_rad: λ_rad)
    
    // 3.9.2. Calculate alhpa in degrees using Equation 12, then limit it to the range from 0 to 360
    let α_degrees = clampAngleToThreeSixty(α.angle) //
    
    // 3.10. Calculate the geocentric sun declination
    let δ: Rad = geocentricSunDeclination(for: β_rad, ε_rad: ε_rad, λ_rad: λ_rad).rad
    
    // 3.11. Calculate the observer local hour angle
    var H: Angle = ν + coordinate.longitude - α_degrees
    H = clampAngleToThreeSixty(H) // 11.105902
    let H_rad = angleToRad(H) // 0.193835
    
    // 3.12.1. Calculate the equatorial horizontal parallax of the sun
    let ξ: Angle = 8.794/(3600.0*R)
    let ξ_rad = angleToRad(ξ) // 0.000043
    
    // 3.12.2. Calculate the term u
    let latitude_rad = angleToRad(coordinate.latitude) // 0.693637
    let u: Rad = atan(0.99664719*tan(latitude_rad))
    
    // 3.12.3. Calculate the term x
    let x: Rad = cos(u) + elevation/6378140.0*cos(latitude_rad)
    
    // 3.12.4. Calculate the term y
    let y: Rad = 0.99664719*sin(u) + elevation/6378140.0*sin(latitude_rad)
    
    // 3.12.5. Calculate the parallax in the sun right ascension
    let Δα: Rad = atan2(-x*sin(ξ_rad)*sin(H_rad), cos(δ) - x*sin(ξ_rad)*cos(H_rad))
    let Δα_degrees: Angle = radToAngle(Δα) // -0.000369
    
    // 3.12.6. Calculate the topocentric sun right ascension
    var α_new: Angle?
    if calculation_tupel.doCalculateAscension {
        α_new = α_degrees + Δα_degrees // 202.227039
    }
    
    // 3.12.7. Calculate the topocentric sun declination
    let δ_new: Rad = atan2((sin(δ) - y*sin(ξ_rad))*cos(Δα), cos(δ) - x*sin(ξ_rad)*cos(H_rad)) // -9.316179
    
    // 3.13. Calculate the topocentric local hour angle
    let H_new: Angle = H - Δα_degrees // 11.106271
    let H_new_rad: Rad = angleToRad(H_new) //
    
    var e: Angle?
    if calculation_tupel.doCalculateHeight || calculation_tupel.doCalculateZenith || calculation_tupel.doCalculateIncidence || calculation_tupel.doCalculateShadowLength {
        // 3.14.1. Calculate the topocentric elevation angle without atmospheric refraction correction
        let e0: Rad = asin(sin(latitude_rad)*sin(δ_new) + cos(latitude_rad)*cos(δ_new)*cos(H_new_rad))
        let e0_degrees: Angle = radToAngle(e0) // 39.872046
        
        // 3.14.2. Calculate the atmospheric refraction correction
        var Δe: Rad = 0
        if e0 >= -1*(SUN_RADIUS + 0.5667) { // not in paper
            Δe = (pressure/1010.0)*(283.0/(273.0 + temperature))*1.02/(radToAngle(60.0*tan(angleToRad(e0_degrees + 10.3/(e0_degrees + 5.11))))) // 0.016332
        }
        let Δe_degrees: Angle = radToAngle(Δe)
        
        // 3.14.3. Calculate the topocentric elevation angle
        e = e0_degrees + Δe_degrees // 39.888378
    }
    
    // 3.14.4. Calculate the topocentric zenith angle
    var z: Angle?
    var zenith_rad: Angle?
    if let e = e , calculation_tupel.doCalculateZenith || calculation_tupel.doCalculateIncidence {
        let zenith: Angle = 90.0 - e // 50.111622
        zenith_rad = angleToRad(zenith)
        z = zenith
    }
    
    var Γ_degrees: Angle?
    var Φ: Angle?
    if calculation_tupel.doCalculateAzimuth || calculation_tupel.doCalculateIncidence || calculation_tupel.doCalculateShadowDirection {
        // 3.15.1. Calculate the topocentric astronomers azimuth angle
        let Γ: Rad = atan2(sin(H_new_rad), cos(H_new_rad)*sin(latitude_rad) - tan(δ_new)*cos(latitude_rad))
        var Γ_deg = radToAngle(Γ)
        Γ_deg = clampAngleToThreeSixty(Γ_deg)
        Γ_degrees = Γ_deg
        
        // 3.15.2. Calculate the topocentric azimuth angle, M for navigators and solar radiation users
        let _Φ = Γ_deg + 180.0
        Φ = clampAngleToThreeSixty(_Φ) // 194.340241
    }
    
    // 3.16. Calculate the incidence angle for a surface oriented in any direction
    var i: Angle?
    if let zenith_rad = zenith_rad, let Γ_degrees = Γ_degrees , calculation_tupel.doCalculateIncidence {
        let slope_rad: Rad = angleToRad(slope)
        let I: Rad = acos(cos(zenith_rad)*cos(slope_rad) + sin(slope_rad)*sin(zenith_rad)*cos(angleToRad(Γ_degrees - surfaceAzimuth)))
        i = radToAngle(I) // 25.187000
    }
    
    var shadowLength: Double?
    if let e = e , calculation_tupel.doCalculateShadowLength {
        let e_rad = angleToRad(e)
        shadowLength = buildingHeight*(sin(angleToRad(90) - e_rad)/sin(e_rad))
    }
    
    var shadowDirection: Angle?
    if let Φ = Φ , calculation_tupel.doCalculateShadowDirection {
        shadowDirection = Φ - 180
    }
    
    return SunPosition(date: date, ascension: α_new, azimuth: Φ, height: e, zenith: z, incidence: i, shadowDirection: shadowDirection, shadowLength: shadowLength)
}


// MARK: - Sunrise, Sunset


/**
 Calculates SunRiseSet for a given day.
 
 Source is the NREL [Article](http://rredc.nrel.gov/solar/codesandalgorithms/spa/)
 
 - parameter date: The point in time to calculate the SunRiseSet for
 - parameter timeZoneOffset: Offset from UTC in hours
 - parameter coordinate: The point on earth to calculate the SunRiseSet for
 - parameter fragments: The selected SunRiseSet properties you need to calculate (fewer means faster processing)
 
 - returns: SunRiseSet object for the date with the selected properties (Fragments)
 */
public func NRELSunrise(for date: Date, timeZoneOffset: Int, coordinate: CLLocationCoordinate2D, fragments: [SunRiseSetFragment]) -> SunRiseSet {
    let start = Date()
    
    func fractionOfDayToLocalHour(_ fractionOfDay: FractionOfDay, timeZoneOffset: Int) -> FractionOfDay {
        return 24.0*clampBetweenOneAndZero(fractionOfDay + Double(timeZoneOffset)/24.0)
    }
    
    var doCalculateSunriseDate = false
    var doCalculateSunriseSunHeight = false
    
    var doCalculateSunsetDate = false
    var doCalculateSunsetSunHeight = false
    
    var doCalculateTransitDate = false
    var doCalculateTransitSunHeight = false
    
    for fragment in fragments {
        switch fragment {
        case .sunrise(let array):
            for subFragment in array {
                switch subFragment {
                case .date:
                    doCalculateSunriseDate = true
                case .height:
                    doCalculateSunriseSunHeight = true
                }
            }
        case .sunset(let array):
            for subFragment in array {
                switch subFragment {
                case .date:
                    doCalculateSunsetDate = true
                case .height:
                    doCalculateSunsetSunHeight = true
                }
            }
        case .transit(let array):
            for subFragment in array {
                switch subFragment {
                case .date:
                    doCalculateTransitDate = true
                case .height:
                    doCalculateTransitSunHeight = true
                }
            }
        }
    }
    
    
    var transitDate: Date?
    var sunriseDate: Date?
    var sunsetDate: Date?
    
    
    var h_0: Angle?
    var h_1: Angle?
    var h_2: Angle?
    
    
    let components = Set<Calendar.Component>([.year, .month, .day])
    let dateComponents = Calendar.current.dateComponents(components, from: date)
    guard let zeroDate = Calendar.current.date(from: dateComponents) else { return SunRiseSet.empty }
    
    let JD_today = julianDay(for: zeroDate, timeZoneOffset: 0)
    let JDE_today = julianEphemerisDay(for: JD_today)
    let JC_today = julianCentury(for: JD_today)
    let JCE_today = julianCentury(for: JDE_today)
    let JME_today = julianEphemerisMillenium(for: JCE_today)
    
    let JD_yesterday = JD_today - 1.0
    let JDE_yesterday = julianEphemerisDay(for: JD_yesterday)
    let JCE_yesterday = julianCentury(for: JDE_yesterday)
    let JME_yesterday = julianEphemerisMillenium(for: JCE_yesterday)
    
    let JD_tomorrow = JD_today + 1.0
    let JDE_tomorrow = julianEphemerisDay(for: JD_tomorrow)
    let JCE_tomorrow = julianCentury(for: JDE_tomorrow)
    let JME_tomorrow = julianEphemerisMillenium(for: JCE_tomorrow)
    
    
    // A.2.1.
    let tupel_today = trueObliquityEcliptic(for: JCE_today, JME: JME_today)
    let ν: Angle = apparentSiderealTimeAtGreenwich(for: JD_today, JC: JC_today, ε_rad: tupel_today.ε_rad, ΔΨ: tupel_today.ΔΨ.angle)
    
    
    // A.2.2.
    // today
    let Θ_0 = geocentricLongitude(for: JME_today)
    let β_rad_0 = geocentricLatitude(for: JME_today)
    let λ_rad_0 = apparentSunLongitude(for: JME_today, Θ: Θ_0, ΔΨ: tupel_today.ΔΨ.angle)
    let α_0 = sunRightAscension(for: β_rad_0, ε_rad: tupel_today.ε_rad, λ_rad: λ_rad_0)
    let δ_0 = geocentricSunDeclination(for: β_rad_0, ε_rad: tupel_today.ε_rad, λ_rad: λ_rad_0)
    // yesterday
    let tupel_yesterday = trueObliquityEcliptic(for: JCE_yesterday, JME: JME_yesterday)
    let Θ_yesterday = geocentricLongitude(for: JME_yesterday)
    let β_rad_yesterday = geocentricLatitude(for: JME_yesterday)
    let λ_rad_yesterday = apparentSunLongitude(for: JME_yesterday, Θ: Θ_yesterday, ΔΨ: tupel_yesterday.ΔΨ.angle)
    let α_yesterday = sunRightAscension(for: β_rad_yesterday, ε_rad: tupel_yesterday.ε_rad, λ_rad: λ_rad_yesterday)
    let δ_yesterday = geocentricSunDeclination(for: β_rad_yesterday, ε_rad: tupel_yesterday.ε_rad, λ_rad: λ_rad_yesterday)
    // tomorrow
    let tupel_tomorrow = trueObliquityEcliptic(for: JCE_tomorrow, JME: JME_tomorrow)
    let Θ_tomorrow = geocentricLongitude(for: JME_tomorrow)
    let β_rad_tomorrow = geocentricLatitude(for: JME_tomorrow)
    let λ_rad_tomorrow = apparentSunLongitude(for: JME_tomorrow, Θ: Θ_tomorrow, ΔΨ: tupel_tomorrow.ΔΨ.angle)
    let α_tomorrow = sunRightAscension(for: β_rad_tomorrow, ε_rad: tupel_tomorrow.ε_rad, λ_rad: λ_rad_tomorrow)
    let δ_tomorrow = geocentricSunDeclination(for: β_rad_tomorrow, ε_rad: tupel_tomorrow.ε_rad, λ_rad: λ_rad_tomorrow)
    
    
    // A.2.3.
    var m_0: Angle = (α_0.angle - coordinate.longitude - ν)/360.0
    
    
    // A.2.4.
    let latitude_rad: Rad = angleToRad(coordinate.latitude)
    let h_0_angle = -0.83337
    let h_0_prime_rad: Rad = angleToRad(h_0_angle)
    let argmument = (sin(h_0_prime_rad) - sin(latitude_rad)*sin(δ_0.rad))/(cos(latitude_rad)*cos(δ_0.rad))
    
    if argmument < -1 || argmument > 1 {
        return SunRiseSet.empty
    }
    
    let H_0 = acos(argmument)
    
    var H_0_degree: Angle = radToAngle(H_0)
    H_0_degree = clampAngleToOneEighty(H_0_degree)
    
    
    // A.2.7.
    m_0 = clampBetweenOneAndZero(m_0)
    
    
    // A.2.10.
    var a: Angle = α_0.angle - α_yesterday.angle
    if fabs(a) > 2 {
        a = clampBetweenOneAndZero(a)
    }
    var b: Angle = α_tomorrow.angle - α_0.angle
    if fabs(b) > 2 {
        b = clampBetweenOneAndZero(b)
    }
    let c: Angle = b - a
    var a_: Angle = δ_0.angle - δ_yesterday.angle
    if fabs(a_) > 2 {
        a_ = clampBetweenOneAndZero(a_)
    }
    var b_: Angle = δ_tomorrow.angle - δ_0.angle
    if fabs(b_) > 2 {
        b_ = clampBetweenOneAndZero(b_)
    }
    let c_: Angle = b_ - a_
    
    
    var H_transit: Angle = 0
    if doCalculateTransitSunHeight || doCalculateTransitDate {
        // A.2.8.
        let ν_0: Angle = ν + 360.985647*m_0
        
        
        // A.2.9.
        let n_0: Angle = m_0 + ΔT/86400.0
        
        
        // A.2.10.
        let δ_0_new: Rad = angleToRad(δ_0.angle + (n_0*(a_ + b_ + c_*n_0))/2.0)
        let α_0_new: Angle = α_0.angle + (n_0*(a + b + c*n_0))/2.0
        
        
        
        // A.2.11.
        H_transit = clampAngleToOneEightyPM(ν_0 + coordinate.longitude - α_0_new)
        let H_transit_rad: Rad = angleToRad(H_transit)
        
        
        // A.2.12.
        h_0 = radToAngle(asin(sin(latitude_rad)*sin(δ_0_new) + cos(latitude_rad)*cos(δ_0_new)*cos(H_transit_rad)))
    }
    
    var m_1: Angle = 0
    var δ_1: Rad = 0
    var H_sunrise_rad: Rad = 0
    if doCalculateSunriseSunHeight || doCalculateSunriseDate {
        // A.2.5.
        m_1 = m_0 - H_0_degree/360.0
     
        // A.2.7.
        m_1 = clampBetweenOneAndZero(m_1)
     
     
        // A.2.8.
        let ν_1: Angle = ν + 360.985647*m_1
     
     
        // A.2.9.
        let n_1: Angle = m_1 + ΔT/86400.0
     
     
        // A.2.10.
        let α_1: Angle = α_0.angle + (n_1*(a + b + c*n_1))/2.0
        δ_1 = angleToRad(δ_0.angle + (n_1*(a_ + b_ + c_*n_1))/2.0)
     
     
        // A.2.11.
        let H_sunrise: Angle = clampAngleToOneEightyPM(ν_1 + coordinate.longitude - α_1)
     
     
        // A.2.12.
        H_sunrise_rad = angleToRad(H_sunrise)
        h_1 = radToAngle(asin(sin(latitude_rad)*sin(δ_1) + cos(latitude_rad)*cos(δ_1)*cos(H_sunrise_rad)))
    }
    
    var m_2: Angle = 0
    var δ_2: Rad = 0
    var H_sunset_rad: Rad = 0
    if doCalculateSunsetSunHeight || doCalculateSunsetDate {
        // A.2.6.
        m_2 = m_0 + H_0_degree/360.0
     
     
        // A.2.7.
        m_2 = clampBetweenOneAndZero(m_2)
     
     
        // A.2.8.
        let ν_2: Angle = ν + 360.985647*m_2
     
     
        // A.2.9.
        let n_2: Angle = m_2 + ΔT/86400.0
     
     
        // A.2.10.
        let α_2: Angle = α_0.angle + (n_2*(a + b + c*n_2))/2.0
        δ_2 = angleToRad(δ_0.angle + (n_2*(a_ + b_ + c_*n_2))/2.0)
     
        // A.2.11.
        let H_sunset: Angle = clampAngleToOneEightyPM(ν_2 + coordinate.longitude - α_2)
        H_sunset_rad = angleToRad(H_sunset)
     
     
        // A.2.12.
        h_2 = radToAngle(asin(sin(latitude_rad)*sin(δ_2) + cos(latitude_rad)*cos(δ_2)*cos(H_sunset_rad)))
    }
    
    
    // A.2.13.
    if doCalculateTransitDate {
        var T: FractionOfDay = m_0 - H_transit/360.0
        T = fractionOfDayToLocalHour(T, timeZoneOffset: timeZoneOffset)
        transitDate = T.dateByAdding(date)
    }
    
    
    // A.2.14.
    if let h_1 = h_1 , doCalculateSunriseDate {
        var R: FractionOfDay = m_1 + (h_1 - h_0_angle)/(360.0*cos(δ_1)*cos(latitude_rad)*sin(H_sunrise_rad))
        R = fractionOfDayToLocalHour(R, timeZoneOffset: timeZoneOffset)
        sunriseDate = R.dateByAdding(date)
    }
    
    
    // A.2.15.
    if let h_2 = h_2 , doCalculateSunsetDate {
        var S: FractionOfDay = m_2 + (h_2 - h_0_angle)/(360.0*cos(δ_2)*cos(latitude_rad)*sin(H_sunset_rad))
        S = fractionOfDayToLocalHour(S, timeZoneOffset: timeZoneOffset)
        sunsetDate = S.dateByAdding(date)
    }
    
    
    return SunRiseSet(sunriseDate: sunriseDate, sunriseHeight: h_1, sunsetDate: sunsetDate, sunsetHeight: h_2, transitDate: transitDate, transitHeight: h_0)
}


// MARK: - Helper


func calculateTerm(with array: [[[Double]]], index: Int, ephemerisMillenium: JulianEphemerisMillenium) -> Rad {
    var sum = 0.0
    let row_array = array[index]
    for values in row_array {
        let A = values[0]
        let B = values[1]
        let C = values[2]
        let result = A*cos(B + C*ephemerisMillenium)
        sum += result
    }
    
    return sum
}


func calculateTerms(with array: [[[Double]]], index: Int, ephemerisMillenia: [JulianEphemerisMillenium]) -> [Rad] {
    let row_array = array[index]
    
    let length = vDSP_Length(ephemerisMillenia.count)
    var sums = Array<Double>(repeating: 0, count: ephemerisMillenia.count)
    var valuesArray = Array<Double>(repeating: 0, count: ephemerisMillenia.count)
    
    for index in 0..<row_array.count {
        let values = row_array[index]
        var A = values[0]
        var B = values[1]
        var C = values[2]
        
        // C multiply ephemerisMillenium
        vDSP_vsmulD(ephemerisMillenia, 1, &C, &valuesArray, 1, length)
        
        // add B
        vDSP_vsaddD(valuesArray, 1, &B, &valuesArray, 1, length)
        
        // take cos
        var cosLength = Int32(length)
        vvcos(&valuesArray, valuesArray, &cosLength)
        
        // multiply with A
        vDSP_vsmulD(valuesArray, 1, &A, &valuesArray, 1, length)
        
        // add valuesArray to sums
        vDSP_vaddD(sums, 1, valuesArray, 1, &sums, 1, length)
        
        if index < row_array.count - 1 {
            // clear valuesArray
            vDSP_vclrD(&valuesArray, 1, length)
        }
    }
    
    return sums
}


func clampAngleToThreeSixty(_ angle: Double) -> Double {
    var limited = 0.0
    
    let degrees = angle/360.0
    limited = 360.0*(degrees - Double(Int(degrees)))
    
    if limited < 0 {
        limited += 360.0
    }
    
    return limited
}


func clampAnglesToThreeSixty(_ angles: [Double]) -> [Double] {
    var clampedAngles = Array<Double>(repeating: 0, count: angles.count)
    
    let length = vDSP_Length(angles.count)
    
    // divide through 360
    var threeSixty = 360.0
    vDSP_vsdivD(angles, 1, &threeSixty, &clampedAngles, 1, length)
    
    // get int part from clampedAngles
    var degrees_double = Array<Double>(repeating: 0, count: angles.count)
    var count = Int32(angles.count)
    vvfloor(&degrees_double, &clampedAngles, &count)
    
    // remove double_degrees from clampedAngles
    vDSP_vsubD(degrees_double, 1, clampedAngles, 1, &clampedAngles, 1, length)
    
    // multiply clampedAngles with 360
    vDSP_vsmulD(clampedAngles, 1, &threeSixty, &clampedAngles, 1, length)
    
    // add 360 if smaller 0
    // FIXME: find vectorized solution
    for index in 0..<clampedAngles.count {
        let degree = clampedAngles[index]
        
        if degree < 0 {
            clampedAngles[index] = degree + threeSixty
        }
    }
    
    return clampedAngles
}


func clampAngleToOneEighty(_ angle: Double) -> Double {
    var limited = 0.0
    
    let degrees = angle/180.0
    limited = 180.0*(degrees - Double(Int(degrees)))
    
    if limited < 0 {
        limited += 180.0
    }
    
    return limited
}


func clampAngleToOneEightyPM(_ angle: Double) -> Double {
    let degrees = angle/360.0
    var limited = 360.0*(degrees - floor(degrees))
    if limited < -180.0 {
        limited += 360.0;
    } else if limited >  180.0 {
        limited -= 360.0;
    }
    
    return limited;
}


func clampBetweenOneAndZero(_ value: Double) -> Double {
    var limited = value - floor(value)
    
    if limited < 0 {
        limited += 1.0
    }
    
    return limited
}


// MARK: - private


private let SUN_RADIUS = 0.26667
private let L_TERMS: [[[Double]]] = [
    [
        [175347046.0,0,0],
        [3341656.0,4.6692568,6283.07585],
        [34894.0,4.6261,12566.1517],
        [3497.0,2.7441,5753.3849],
        [3418.0,2.8289,3.5231],
        [3136.0,3.6277,77713.7715],
        [2676.0,4.4181,7860.4194],
        [2343.0,6.1352,3930.2097],
        [1324.0,0.7425,11506.7698],
        [1273.0,2.0371,529.691],
        [1199.0,1.1096,1577.3435],
        [990,5.233,5884.927],
        [902,2.045,26.298],
        [857,3.508,398.149],
        [780,1.179,5223.694],
        [753,2.533,5507.553],
        [505,4.583,18849.228],
        [492,4.205,775.523],
        [357,2.92,0.067],
        [317,5.849,11790.629],
        [284,1.899,796.298],
        [271,0.315,10977.079],
        [243,0.345,5486.778],
        [206,4.806,2544.314],
        [205,1.869,5573.143],
        [202,2.458,6069.777],
        [156,0.833,213.299],
        [132,3.411,2942.463],
        [126,1.083,20.775],
        [115,0.645,0.98],
        [103,0.636,4694.003],
        [102,0.976,15720.839],
        [102,4.267,7.114],
        [99,6.21,2146.17],
        [98,0.68,155.42],
        [86,5.98,161000.69],
        [85,1.3,6275.96],
        [85,3.67,71430.7],
        [80,1.81,17260.15],
        [79,3.04,12036.46],
        [75,1.76,5088.63],
        [74,3.5,3154.69],
        [74,4.68,801.82],
        [70,0.83,9437.76],
        [62,3.98,8827.39],
        [61,1.82,7084.9],
        [57,2.78,6286.6],
        [56,4.39,14143.5],
        [56,3.47,6279.55],
        [52,0.19,12139.55],
        [52,1.33,1748.02],
        [51,0.28,5856.48],
        [49,0.49,1194.45],
        [41,5.37,8429.24],
        [41,2.4,19651.05],
        [39,6.17,10447.39],
        [37,6.04,10213.29],
        [37,2.57,1059.38],
        [36,1.71,2352.87],
        [36,1.78,6812.77],
        [33,0.59,17789.85],
        [30,0.44,83996.85],
        [30,2.74,1349.87],
        [25,3.16,4690.48]
    ],
    [
        [628331966747.0,0,0],
        [206059.0,2.678235,6283.07585],
        [4303.0,2.6351,12566.1517],
        [425.0,1.59,3.523],
        [119.0,5.796,26.298],
        [109.0,2.966,1577.344],
        [93,2.59,18849.23],
        [72,1.14,529.69],
        [68,1.87,398.15],
        [67,4.41,5507.55],
        [59,2.89,5223.69],
        [56,2.17,155.42],
        [45,0.4,796.3],
        [36,0.47,775.52],
        [29,2.65,7.11],
        [21,5.34,0.98],
        [19,1.85,5486.78],
        [19,4.97,213.3],
        [17,2.99,6275.96],
        [16,0.03,2544.31],
        [16,1.43,2146.17],
        [15,1.21,10977.08],
        [12,2.83,1748.02],
        [12,3.26,5088.63],
        [12,5.27,1194.45],
        [12,2.08,4694],
        [11,0.77,553.57],
        [10,1.3,6286.6],
        [10,4.24,1349.87],
        [9,2.7,242.73],
        [9,5.64,951.72],
        [8,5.3,2352.87],
        [6,2.65,9437.76],
        [6,4.67,4690.48]
    ],
    [
        [52919.0,0,0],
        [8720.0,1.0721,6283.0758],
        [309.0,0.867,12566.152],
        [27,0.05,3.52],
        [16,5.19,26.3],
        [16,3.68,155.42],
        [10,0.76,18849.23],
        [9,2.06,77713.77],
        [7,0.83,775.52],
        [5,4.66,1577.34],
        [4,1.03,7.11],
        [4,3.44,5573.14],
        [3,5.14,796.3],
        [3,6.05,5507.55],
        [3,1.19,242.73],
        [3,6.12,529.69],
        [3,0.31,398.15],
        [3,2.28,553.57],
        [2,4.38,5223.69],
        [2,3.75,0.98]
    ],
    [
        [289.0,5.844,6283.076],
        [35,0,0],
        [17,5.49,12566.15],
        [3,5.2,155.42],
        [1,4.72,3.52],
        [1,5.3,18849.23],
        [1,5.97,242.73]
    ],
    [
        [114.0,3.142,0],
        [8,4.13,6283.08],
        [1,3.84,12566.15]
    ],
    [
        [1,3.14,0]
    ]
]
private let B_TERMS: [[[Double]]] = [
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
private let R_TERMS: [[[Double]]] = [
    [
        [100013989.0,0,0],
        [1670700.0,3.0984635,6283.07585],
        [13956.0,3.05525,12566.1517],
        [3084.0,5.1985,77713.7715],
        [1628.0,1.1739,5753.3849],
        [1576.0,2.8469,7860.4194],
        [925.0,5.453,11506.77],
        [542.0,4.564,3930.21],
        [472.0,3.661,5884.927],
        [346.0,0.964,5507.553],
        [329.0,5.9,5223.694],
        [307.0,0.299,5573.143],
        [243.0,4.273,11790.629],
        [212.0,5.847,1577.344],
        [186.0,5.022,10977.079],
        [175.0,3.012,18849.228],
        [110.0,5.055,5486.778],
        [98,0.89,6069.78],
        [86,5.69,15720.84],
        [86,1.27,161000.69],
        [65,0.27,17260.15],
        [63,0.92,529.69],
        [57,2.01,83996.85],
        [56,5.24,71430.7],
        [49,3.25,2544.31],
        [47,2.58,775.52],
        [45,5.54,9437.76],
        [43,6.01,6275.96],
        [39,5.36,4694],
        [38,2.39,8827.39],
        [37,0.83,19651.05],
        [37,4.9,12139.55],
        [36,1.67,12036.46],
        [35,1.84,2942.46],
        [33,0.24,7084.9],
        [32,0.18,5088.63],
        [32,1.78,398.15],
        [28,1.21,6286.6],
        [28,1.9,6279.55],
        [26,4.59,10447.39]
    ],
    [
        [103019.0,1.10749,6283.07585],
        [1721.0,1.0644,12566.1517],
        [702.0,3.142,0],
        [32,1.02,18849.23],
        [31,2.84,5507.55],
        [25,1.32,5223.69],
        [18,1.42,1577.34],
        [10,5.91,10977.08],
        [9,1.42,6275.96],
        [9,0.27,5486.78]
    ],
    [
        [4359.0,5.7846,6283.0758],
        [124.0,5.579,12566.152],
        [12,3.14,0],
        [9,3.63,77713.77],
        [6,1.87,5573.14],
        [3,5.47,18849.23]
    ],
    [
        [145.0,4.273,6283.076],
        [7,3.92,12566.15]
    ],
    [
        [4,2.56,6283.08]
    ]
]
private let Y_TERMS: [[Double]] = [
    [0,0,0,0,1],
    [-2,0,0,2,2],
    [0,0,0,2,2],
    [0,0,0,0,2],
    [0,1,0,0,0],
    [0,0,1,0,0],
    [-2,1,0,2,2],
    [0,0,0,2,1],
    [0,0,1,2,2],
    [-2,-1,0,2,2],
    [-2,0,1,0,0],
    [-2,0,0,2,1],
    [0,0,-1,2,2],
    [2,0,0,0,0],
    [0,0,1,0,1],
    [2,0,-1,2,2],
    [0,0,-1,0,1],
    [0,0,1,2,1],
    [-2,0,2,0,0],
    [0,0,-2,2,1],
    [2,0,0,2,2],
    [0,0,2,2,2],
    [0,0,2,0,0],
    [-2,0,1,2,2],
    [0,0,0,2,0],
    [-2,0,0,2,0],
    [0,0,-1,2,1],
    [0,2,0,0,0],
    [2,0,-1,0,1],
    [-2,2,0,2,2],
    [0,1,0,0,1],
    [-2,0,1,0,1],
    [0,-1,0,0,1],
    [0,0,2,-2,0],
    [2,0,-1,2,1],
    [2,0,1,2,2],
    [0,1,0,2,2],
    [-2,1,1,0,0],
    [0,-1,0,2,2],
    [2,0,0,2,1],
    [2,0,1,0,0],
    [-2,0,2,2,2],
    [-2,0,1,2,1],
    [2,0,-2,0,1],
    [2,0,0,0,1],
    [0,-1,1,0,0],
    [-2,-1,0,2,1],
    [-2,0,0,0,1],
    [0,0,2,2,1],
    [-2,0,2,0,1],
    [-2,1,0,2,1],
    [0,0,1,-2,0],
    [-1,0,1,0,0],
    [-2,1,0,0,0],
    [1,0,0,0,0],
    [0,0,1,2,0],
    [0,0,-2,2,2],
    [-1,-1,1,0,0],
    [0,1,1,0,0],
    [0,-1,1,2,2],
    [2,-1,-1,2,2],
    [0,0,3,2,2],
    [2,-1,0,2,2],
]
private let PE_TERMS: [[Double]] = [
    [-171996,-174.2,92025,8.9],
    [-13187,-1.6,5736,-3.1],
    [-2274,-0.2,977,-0.5],
    [2062,0.2,-895,0.5],
    [1426,-3.4,54,-0.1],
    [712,0.1,-7,0],
    [-517,1.2,224,-0.6],
    [-386,-0.4,200,0],
    [-301,0,129,-0.1],
    [217,-0.5,-95,0.3],
    [-158,0,0,0],
    [129,0.1,-70,0],
    [123,0,-53,0],
    [63,0,0,0],
    [63,0.1,-33,0],
    [-59,0,26,0],
    [-58,-0.1,32,0],
    [-51,0,27,0],
    [48,0,0,0],
    [46,0,-24,0],
    [-38,0,16,0],
    [-31,0,13,0],
    [29,0,0,0],
    [29,0,-12,0],
    [26,0,0,0],
    [-22,0,0,0],
    [21,0,-10,0],
    [17,-0.1,0,0],
    [16,0,-8,0],
    [-16,0.1,7,0],
    [-15,0,9,0],
    [-13,0,7,0],
    [-12,0,6,0],
    [11,0,0,0],
    [-10,0,5,0],
    [-8,0,3,0],
    [7,0,-3,0],
    [-7,0,0,0],
    [-7,0,3,0],
    [-7,0,3,0],
    [6,0,0,0],
    [6,0,-3,0],
    [6,0,-3,0],
    [-6,0,3,0],
    [-6,0,3,0],
    [5,0,0,0],
    [-5,0,3,0],
    [-5,0,3,0],
    [-5,0,3,0],
    [4,0,0,0],
    [4,0,0,0],
    [4,0,0,0],
    [-4,0,0,0],
    [-4,0,0,0],
    [-4,0,0,0],
    [3,0,0,0],
    [-3,0,0,0],
    [-3,0,0,0],
    [-3,0,0,0],
    [-3,0,0,0],
    [-3,0,0,0],
    [-3,0,0,0],
    [-3,0,0,0],
]


private func thirdOrderPolynom(for a: Double, b: Double, c: Double, d: Double, x: Double) -> Double {
    return ((a*x + b)*x + c)*x + d
}


private func apparentSunLongitude(for JME: JulianEphemerisMillenium, Θ: Angle, ΔΨ: Angle) -> Rad {
    // 3.2.8. Calculate the Earth radius vector, R
    let R0 = calculateTerm(with: R_TERMS, index: 0, ephemerisMillenium: JME)
    let R1 = calculateTerm(with: R_TERMS, index: 1, ephemerisMillenium: JME)
    let R2 = calculateTerm(with: R_TERMS, index: 2, ephemerisMillenium: JME)
    let R3 = calculateTerm(with: R_TERMS, index: 3, ephemerisMillenium: JME)
    let R4 = calculateTerm(with: R_TERMS, index: 4, ephemerisMillenium: JME)
    let R_nominator = R0 + R1*JME + R2*pow(JME, 2) + R3*pow(JME, 3) + R4*pow(JME, 4)
    let R = R_nominator/100000000.0 // 0.996542
    
    // 3.6. Calculate the aberration correction
    let Δτ: Angle = -20.4898/(3600.0*R)
    
    // 3.7 Calculate the apparent sun longitude
    let λ: Angle = Θ + ΔΨ + Δτ // 204.008552
    let λ_rad = angleToRad(λ) // 3.560621
    
    return λ_rad
}


private func geocentricLongitude(for JME: JulianEphemerisMillenium) -> Angle {
    // 3.2.1. and 3.2.2. Calculate the term L0 (in radians)
    let L0: Rad = calculateTerm(with: L_TERMS, index: 0, ephemerisMillenium: JME) //
    
    // 3.2.3. Calculate the terms L1, L2, L3, L4, and L5
    let L1: Rad = calculateTerm(with: L_TERMS, index: 1, ephemerisMillenium: JME) //
    let L2: Rad = calculateTerm(with: L_TERMS, index: 2, ephemerisMillenium: JME) //
    let L3: Rad = calculateTerm(with: L_TERMS, index: 3, ephemerisMillenium: JME) //
    let L4: Rad = calculateTerm(with: L_TERMS, index: 4, ephemerisMillenium: JME) //
    let L5: Rad = calculateTerm(with: L_TERMS, index: 5, ephemerisMillenium: JME) //
    
    // 3.2.4. Calculate the Earth heliocentric longitude, L (in radians)
    let L_nominator: Rad = L0 + L1*JME + L2*pow(JME, 2) + L3*pow(JME, 3) + L4*pow(JME, 4) + L5*pow(JME, 5)
    let L: Rad = L_nominator/100000000.0
    
    // 3.2.5. Calculate L in degrees,
    let L_degrees = radToAngle(L) // 24.01826
    
    // 3.3.1. Calculate the geocentric longitude, 1 (in degrees)
    var Θ: Angle = L_degrees + 180.0
    
    // 3.3.2. Limit 1 to the range from 0 to 360
    Θ = clampAngleToThreeSixty(Θ) //
    
    return Θ
}


private func geocentricLatitude(for JME: JulianEphemerisMillenium) -> Rad {
    // 3.2.7. Calculate the Earth heliocentric latitude,
    let B0: Angle = radToAngle(calculateTerm(with: B_TERMS, index: 0, ephemerisMillenium: JME)) //
    let B1: Angle = radToAngle(calculateTerm(with: B_TERMS, index: 1, ephemerisMillenium: JME)) //
    let B_nominator: Angle = B0 + B1*JME
    let B: Angle = B_nominator/100000000.0 // -0.0001011219
    
    // 3.3.3. Calculate the geocentric latitude, beta (in degrees),
    let β: Angle = -B //
    let β_rad: Rad = angleToRad(β) // 0.000002
    
    return β_rad
}


private func geocentricSunDeclination(for β_rad: Rad, ε_rad: Rad, λ_rad: Rad) -> (rad: Rad, angle: Angle) {
    // 3.10. Calculate the geocentric sun declination
    let δ: Rad = asin(sin(β_rad)*cos(ε_rad) + cos(β_rad)*sin(ε_rad)*sin(λ_rad)) //
    
    return (δ, radToAngle(δ))
}


private func sunRightAscension(for β_rad: Rad, ε_rad: Rad, λ_rad: Rad) -> (rad: Rad, angle: Angle) {
    // 3.9.1. Calculate the sun right ascension
    let atan_nominator = sin(λ_rad)*cos(ε_rad) - tan(β_rad)*sin(ε_rad)
    let atan_denominator = cos(λ_rad)
    let α: Rad = atan2(atan_nominator, atan_denominator)
    
    // 3.9.2. Calculate alhpa in degrees using Equation 12, then limit it to the range from 0 to 360
    var α_degrees = radToAngle(α)
    α_degrees = clampAngleToThreeSixty(α_degrees) //
    
    return (α, α_degrees)
}


private func apparentSiderealTimeAtGreenwich(for JD: JulianDay, JC: JulianCentury, ε_rad: Rad, ΔΨ: Angle) -> Angle {
    // 3.8.1. Calculate the mean sidereal time at Greenwich
    let left = 280.46061837 + 360.98564736629*(JD - 2451545.0)
    let right = JC*JC*(0.000387933 - JC/38710000.0)
    var ν0: Angle = left + right // 318.515578
    
    // 3.8.2. Limit v_zero to the range from 0 to 360
    ν0 = clampAngleToThreeSixty(ν0)
    
    // 3.8.3. Calculate the apparent sidereal time at Greenwich
    let ν: Angle = ν0 + ΔΨ*cos(ε_rad)
    
    return ν
}


private func trueObliquityEcliptic(for JCE: JulianCentury, JME: JulianEphemerisMillenium) -> (ΔΨ: (angle: Angle, rad: Rad), Δε: Rad, ε_rad: Rad) {
    // 3.4.1. Calculate the mean elongation of the moon from the sun, X0 (in degrees) // ((a*x + b)*x + c)*x + d;
    let X0: Angle = thirdOrderPolynom(for: 1.0/189474.0, b: -0.0019142, c: 445267.111480, d: 297.85036, x: JCE)
    
    // 3.4.2. Calculate the mean anomaly of the sun (Earth), X1 (in degrees)
    let X1: Angle = thirdOrderPolynom(for: -1.0/300000.0, b: -0.0001603, c: 35999.050340, d: 357.52772, x: JCE)
    
    // 3.4.3. Calculate the mean anomaly of the moon, X2 (in degrees)
    let X2: Angle = thirdOrderPolynom(for: 1.0/56250.0, b: 0.0086972, c: 477198.867398, d: 134.96298, x: JCE)
    
    // 3.4.4. Calculate the moon’s argument of latitude, X3 (in degrees)
    let X3: Angle = thirdOrderPolynom(for: 1.0/327270.0, b: -0.0036825, c: 483202.017538, d: 93.27191, x: JCE)
    
    // 3.4.5. Calculate the longitude of the ascending node of the moon’s mean orbit on the ecliptic, measured from the mean equinox of the date, X4 (in degrees)
    let X4: Angle = thirdOrderPolynom(for: 1.0/450000.0, b: 0.0020708, c: -1934.136261, d: 125.04452, x: JCE)
    
    // 3.4.6. to 3.4.8
    var ΔΨ: Angle = 0.0
    var Δε: Angle = 0.0
    for i in 0..<Y_TERMS.count {
        let y_array = Y_TERMS[i]
        let y0 = y_array[0]
        let y1 = y_array[1]
        let y2 = y_array[2]
        let y3 = y_array[3]
        let y4 = y_array[4]
        
        let pe_array = PE_TERMS[i]
        let a = pe_array[0]
        let b = pe_array[1]
        let c = pe_array[2]
        let d = pe_array[3]
        
        let sum: Angle = X0*y0 + X1*y1 + X2*y2 + X3*y3 + X4*y4
        let sum_rad: Rad = angleToRad(sum)
        
        let Ψ = (a + b*JCE)*sin(sum_rad)
        ΔΨ += Ψ
        
        let ε = (c + d*JCE)*cos(sum_rad)
        Δε += ε
    }
    
    ΔΨ = ΔΨ/36000000.0 // -0.003998404
    Δε = Δε/36000000.0 // 0.001666568
    
    // 3.5.1. Calculate the mean obliquity of the ecliptic
    let U = JME/10.0
    let ε0: Angle = 84381.448 + U*(-4680.93 + U*(-1.55 + U*(1999.25 + U*(-51.38 + U*(-249.67 + U*(-39.05 + U*( 7.12 + U*(27.87 + U*(5.79 + U*2.45)))))))))
    
    // 3.5.2. Calculate the true obliquity of the ecliptic,
    let ε: Angle = ε0/3600.0 + Δε // 23.440465
    let ε_rad: Rad = angleToRad(ε) // 0.409113
    
    let ΔΨ_rad = angleToRad(ΔΨ)
    
    return ((ΔΨ, ΔΨ_rad), angleToRad(Δε), ε_rad)
}


private func bool(for fragments: [SunPositionFragment]) -> (doCalculateAscension: Bool, doCalculateAzimuth: Bool, doCalculateHeight: Bool, doCalculateIncidence: Bool, doCalculateZenith: Bool, doCalculateShadowLength: Bool, doCalculateShadowDirection: Bool) {
    var doCalculateAscension = false
    var doCalculateAzimuth = false
    var doCalculateHeight = false
    var doCalculateIncidence = false
    var doCalculateZenith = false
    var doCalculateShadowDirection = false
    var doCalculateShadowLength = false
    
    for fragment in fragments {
        switch fragment {
        case .ascension:
            doCalculateAscension = true
        case .azimuth:
            doCalculateAzimuth = true
        case .height:
            doCalculateHeight = true
        case .incidence:
            doCalculateIncidence = true
        case .zenith:
            doCalculateZenith = true
        case .shadow(let array):
            for subFragment in array {
                switch subFragment {
                case .direction:
                    doCalculateShadowDirection = true
                case .length:
                    doCalculateShadowLength = true
                }
            }
        }
    }
    
    return (doCalculateAscension, doCalculateAzimuth, doCalculateHeight, doCalculateIncidence, doCalculateZenith, doCalculateShadowLength, doCalculateShadowDirection)
}
