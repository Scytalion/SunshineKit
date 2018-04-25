//
//  RadAndAngle.swift
//  SunBalcony
//
//  Created by Oleg Mueller on 06.07.16.
//  Copyright © 2016 Oleg Mueller. All rights reserved.
//

import Foundation
import Accelerate


public func radToAngle(_ rad: Rad) -> Angle {
    return (180.0/Double.pi)*rad
}


func radsToAngles(_ rads: [Rad]) -> [Angle] {
    var angles = Array<Angle>(repeating: 180.0, count: rads.count)
    
    let length = vDSP_Length(rads.count)
    var divider = Double.pi
    
    // divide through pi
    vDSP_vsdivD(angles, 1, &divider, &angles, 1, length)
    
    // multiply with rads
    vDSP_vmulD(angles, 1, rads, 1, &angles, 1, length)
    
    return angles
}


public func angleToRad(_ angle: Angle) -> Rad {
    return (Double.pi/180.0)*angle
}


func anglesToRads(_ angles: [Angle]) -> [Rad] {
    var rads = Array<Rad>(repeating: Double.pi, count: angles.count)
    
    let length = vDSP_Length(angles.count)
    var divider = 180.0
    
    // divide pi through 180
    vDSP_vsdivD(rads, 1, &divider, &rads, 1, length)
    
    // multiply with angles
    vDSP_vmulD(rads, 1, angles, 1, &rads, 1, length)
    
    return rads
}
