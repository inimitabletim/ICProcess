//
//  DFPGType.swift
//  AIPESD
//
//  Created by 陳東暘 on 2023/12/5.
//

import SwiftUI

enum PGType: Int, CaseIterable {
    case ground = 0
    case realPower = 1
    case chargePumpPower = 2
    case ldoPower = 3
    case bootstrapPower = 4

    init(type: Int) {
        switch type {
        case 0:
            self = .ground
        case 1:
            self = .realPower
        case 2:
            self = .chargePumpPower
        case 3:
            self = .ldoPower
        case 4:
            self = .bootstrapPower
        default:
            self = .ground
        }
    }
    var typeName: String {
        switch self {
        case .ground:
            return "GND"
        case .realPower:
            return "PWR"
        case .chargePumpPower:
            return "CPP"
        case .ldoPower:
            return "LDO"
        case .bootstrapPower:
            return "BSP"
        }
    }
    var fullName: String {
        switch self {
        case .ground:
            return "Ground"
        case .realPower:
            return "RealPower"
        case .chargePumpPower:
            return "ChargePump"
        case .ldoPower:
            return "LDO"
        case .bootstrapPower:
            return "BootStrap"
        }
    }
}

class DFPGType: NSObject {
    var typeIndex: Int = -1
    var typeName: String = ""
    var fullName: String = ""
    
    init(typeId: Int)  {
        super.init()
        typeIndex = typeId
        if typeIndex > -1 {
            typeName = PGType(type: typeIndex).typeName
            fullName = PGType(type: typeIndex).fullName
        }
    }
    init(name: String) {
        super.init()
        typeIndex = getTypeIndex(typeName: name)
        if typeIndex > -1 {
            typeName = PGType(type: typeIndex).typeName
            fullName = PGType(type: typeIndex).fullName
        }
    }
    private func getTypeIndex(typeName: String) -> Int {
        for i in 0..<5 {
            if PGType.init(type: i).typeName.uppercased() == typeName.uppercased() {
                return i
            }
        }
        return -1
    }
}
