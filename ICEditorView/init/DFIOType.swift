//
//  DFIOType.swift
//  AIPESD
//
//  Created by 陳東暘 on 2023/12/8.
//

import SwiftUI

enum IOType: Int, CaseIterable {
    case digitalInput = 0
    case digitalOutput = 1
    case digitalIO = 2
    case analogInput = 3
    case analogOutput = 4
    case analogIO = 5
    case openDrain = 6

    init(type: Int) {
        switch type {
        case 0:
            self = .digitalInput
        case 1:
            self = .digitalOutput
        case 2:
            self = .digitalIO
        case 3:
            self = .analogInput
        case 4:
            self = .analogOutput
        case 5:
            self = .analogIO
        case 6:
            self = .openDrain
        default:
            self = .digitalIO
        }
    }
    var typeName: String {
        switch self {
        case .digitalInput:
            return "DIn"
        case .digitalOutput:
            return "DOut"
        case .digitalIO:
            return "DIO"
        case .analogInput:
            return "AIn"
        case .analogOutput:
            return "AOut"
        case .analogIO:
            return "AIO"
        case .openDrain:
            return "OPD"
        }
    }
    
    var fullName: String {
        switch self {
        case .digitalInput:
            return "Input"
        case .digitalOutput:
            return "Digital Output"
        case .digitalIO:
            return "Digital Input/Output"
        case .analogInput:
            return "Analog Input"
        case .analogOutput:
            return "Analog Output"
        case .analogIO:
            return "Analog Input/Output"
        case .openDrain:
            return "Open Drain"
        }
    }
}

class DFIOType: NSObject {
    var typeIndex: Int = -1
    var typeName: String = ""
    var fullName: String = ""
    
    init(typeId: Int)  {
        super.init()
        typeIndex = typeId
        if typeIndex > -1 {
            typeName = IOType(type: typeIndex).typeName
            fullName = IOType(type: typeIndex).fullName
        }
    }
    init(name: String) {
        super.init()
        typeIndex = getTypeIndex(typeName: name)
        if typeIndex > -1 {
            typeName = IOType(type: typeIndex).typeName
            fullName = IOType(type: typeIndex).fullName
        }
    }
    private func getTypeIndex(typeName: String) -> Int {
        for i in 0..<7 {
            if IOType.init(type: i).typeName.uppercased() == typeName.uppercased() {
                return i
            }
        }
        return -1
    }
}
