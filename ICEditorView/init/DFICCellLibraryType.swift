//
//  DFBackEndLayerType.swift
//  AIPESD
//
//  Created by 陳東暘 on 2020/7/24.
//  Copyright © 2020 陳東暘. All rights reserved.
//
import SwiftUI

enum ICCellLibraryType: Int, CaseIterable {
    case topCell = 0
    case ioBlock = 1
    case ioSubBlock = 2
    case pgIPCell = 3
    case ioIPCell = 4
    case testLineBlock = 5
    case coreBlock = 6
    case digitalBlock = 7
    case memoryBlock = 8
    case apRoutingBlock = 9
    case sealRingBlock = 10

    init(type: Int) {
        switch type {
        case 0:
            self = .topCell
        case 1:
            self = .ioBlock
        case 2:
            self = .ioSubBlock
        case 3:
            self = .pgIPCell
        case 4:
            self = .ioIPCell
        case 5:
            self = .testLineBlock
        case 6:
            self = .coreBlock
        case 7:
            self = .digitalBlock
        case 8:
            self = .memoryBlock
        case 9:
            self = .apRoutingBlock
        case 10:
            self = .sealRingBlock
        default:
            self = .topCell
        }
    }
    var typeName: String {
        switch self {
        case .topCell:
            return "Top Cell"
        case .ioBlock:
            return "I/O Block"
        case .ioSubBlock:
            return "I/O SubBlock"
        case .pgIPCell:
            return "P/G Cell"
        case .ioIPCell:
            return "I/O Cell"
        case .testLineBlock:
            return "Test Line Block"
        case .coreBlock:
            return "Core Bolck"
        case .digitalBlock:
            return "Digital Block"
        case .memoryBlock:
            return "Memory Block"
        case .apRoutingBlock:
            return "AP Layer Routing Block"
        case .sealRingBlock:
            return "Seal Ring Block"
        }
    }
    var shortName: String {
        switch self {
        case .topCell:
            return "TC"
        case .ioBlock:
            return "IB"
        case .ioSubBlock:
            return "SB"
        case .pgIPCell:
            return "PG"
        case .ioIPCell:
            return "IO"
        case .testLineBlock:
            return "TL"
        case .coreBlock:
            return "CB"
        case .digitalBlock:
            return "DB"
        case .memoryBlock:
            return "MB"
        case .apRoutingBlock:
            return "AP"
        case .sealRingBlock:
            return "SR"
        }
    }
}

class DFICCellLibraryType: NSObject {
    var typeIndex: Int = -1
    var typeName: String = ""
    var shortName: String = ""
    
    init(typeId: Int)  {
        super.init()
        typeIndex = typeId
        typeName = ICCellLibraryType(type: typeIndex).typeName
        shortName = ICCellLibraryType(type: typeIndex).shortName
    }
    init(name: String) {
        super.init()
        typeIndex = getTypeIndex(typeName: name)
        typeName = ICCellLibraryType(type: typeIndex).typeName
        shortName = ICCellLibraryType(type: typeIndex).shortName
    }
    init(prefix: String) {
        super.init()
        typeIndex = getTypeIndex(preName: prefix)
        typeName = ICCellLibraryType(type: typeIndex).typeName
        shortName = ICCellLibraryType(type: typeIndex).shortName
    }
    private func getTypeIndex(typeName: String) -> Int {
        for i in 0..<11 {
            if ICCellLibraryType.init(type: i).typeName.uppercased() == typeName.uppercased() {
                return i
            }
        }
        return -1
    }
    private func getTypeIndex(preName: String) -> Int {
        for i in 0..<11 {
            if ICCellLibraryType.init(type: i).shortName.uppercased() == preName.uppercased() {
                return i
            }
        }
        return -1
    }
}
