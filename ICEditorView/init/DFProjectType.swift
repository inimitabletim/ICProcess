//
//  DFProjectType.swift
//  AIPESD
//
//  Created by 陳東暘 on 2021/4/28.
//

import SwiftUI

enum ProjectType: Int, CaseIterable {
    case design = 0
    case ipLib = 1
    case fabIP = 2
    case fabTD = 3
    case software = 4

    init(type: Int) {
        switch type {
        case 0:
            self = .design
        case 1:
            self = .ipLib
        case 2:
            self = .fabIP
        case 3:
            self = .fabTD
        case 4:
            self = .software
        default:
            self = .design
        }
    }
    var typeName: String {
        switch self {
        case .design:
            return "Design"
        case .ipLib:
            return "IP-Lib"
        case .fabIP:
            return "Fab-IP"
        case .fabTD:
            return "Fab-TD"
        case .software:
            return "Software"
        }
    }
    var fullName: String {
        switch self {
        case .design:
            return "Design Service"
        case .ipLib:
            return "IP Library"
        case .fabIP:
            return "Fab IP Library"
        case .fabTD:
            return "Fab TechDevice"
        case .software:
            return "Software Library"
        }
    }
}

class DFProjectType: NSObject {
    var typeIndex: Int = -1
    var typeName: String = ""
    var fullName: String = ""
    
    init(typeId: Int)  {
        super.init()
        typeIndex = typeId
        if typeIndex > -1 {
            typeName = ProjectType(type: typeIndex).typeName
            fullName = ProjectType(type: typeIndex).fullName
        }
    }
    init(name: String) {
        super.init()
        typeIndex = getTypeIndex(typeName: name)
        if typeIndex > -1 {
            typeName = ProjectType(type: typeIndex).typeName
            fullName = ProjectType(type: typeIndex).fullName
        }
    }
    private func getTypeIndex(typeName: String) -> Int {
        for i in 0..<ProjectType.allCases.count {
            if ProjectType.init(type: i).typeName.uppercased() == typeName.uppercased() {
                return i
            }
        }
        return -1
    }
}
