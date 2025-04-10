//
//  DFPinOutType.swift
//  AIPESD
//
//  Created by 陳東暘 on 2018/11/20.
//  Copyright © 2018 陳 東暘. All rights reserved.
//
import SwiftUI

enum PinOutType: Int, CaseIterable {
    case input = 0
    case output = 1
    case io = 2
    case power = 3
    case ground = 4
    case negativePower = 5

    init(type: Int) {
        switch type {
        case 0:
            self = .input
        case 1:
            self = .output
        case 2:
            self = .io
        case 3:
            self = .power
        case 4:
            self = .ground
        case 5:
            self = .negativePower
        default:
            self = .io
        }
    }
    var typeName: String {
        switch self {
        case .input:
            return "I"
        case .output:
            return "O"
        case .io:
            return "IO"
        case .power:
            return "P"
        case .ground:
            return "G"
        case .negativePower:
            return "N"
        }
    }
    var fullName: String {
        switch self {
        case .input:
            return "Input"
        case .output:
            return "Output"
        case .io:
            return "Input/Output"
        case .power:
            return "Power"
        case .ground:
            return "Ground"
        case .negativePower:
            return "Negative-Power"
        }
    }
}

class DFPinOutType: NSObject {
    var typeIndex: Int = -1
    var typeName: String = ""
    var fullName: String = ""
    
    init(typeId: Int)  {
        super.init()
        typeIndex = typeId
        if typeIndex > -1 {
            typeName = PinOutType(type: typeIndex).typeName
            fullName = PinOutType(type: typeIndex).fullName
        }
    }
    init(name: String) {
        super.init()
        typeIndex = getTypeIndex(typeName: name)
        if typeIndex > -1 {
            typeName = PinOutType(type: typeIndex).typeName
            fullName = PinOutType(type: typeIndex).fullName
        }
    }
    private func getTypeIndex(typeName: String) -> Int {
        for i in 0..<6 {
            if PinOutType.init(type: i).typeName.uppercased() == typeName.uppercased() {
                return i
            }
        }
        return -1
    }
}
