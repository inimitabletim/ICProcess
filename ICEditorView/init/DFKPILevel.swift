//
//  DFKPILevel.swift
//  AIPESD
//
//  Created by 陳東暘 on 2021/5/5.
//

import SwiftUI

enum KPILevel: Int, CaseIterable {
    case poorBad = 0
    case poor = 1
    case fairBad = 2
    case fair = 3
    case fairGood = 4
    case average = 5
    case averageGood = 6
    case good = 7
    case veryGood = 8
    case excellent = 9
    case veryExcellent = 10

    init(type: Int) {
        switch type {
        case 0:
            self = .poorBad
        case 1:
            self = .poor
        case 2:
            self = .fairBad
        case 3:
            self = .fair
        case 4:
            self = .fairGood
        case 5:
            self = .average
        case 6:
            self = .averageGood
        case 7:
            self = .good
        case 8:
            self = .veryGood
        case 9:
            self = .excellent
        case 10:
            self = .veryExcellent
        default:
            self = .average
        }
    }
    var typeName: String {
        switch self {
        case .poorBad:
            return "Poor(Bad)"
        case .poor:
            return "Poor"
        case .fairBad:
            return "Fair(Bad)"
        case .fair:
            return "Fair"
        case .fairGood:
            return "Fair(Good)"
        case .average:
            return "Average"
        case .averageGood:
            return "Average(Good)"
        case .good:
            return "Good"
        case .veryGood:
            return "Very Good"
        case .excellent:
            return "Excellent"
        case .veryExcellent:
            return "Very Excellent"
        }
    }
    var gradeValue: Double {
        switch self {
        case .poorBad:
            return 0
        case .poor:
            return 10
        case .fairBad:
            return 20
        case .fair:
            return 30
        case .fairGood:
            return 40
        case .average:
            return 50
        case .averageGood:
            return 60
        case .good:
            return 70
        case .veryGood:
            return 80
        case .excellent:
            return 90
        case .veryExcellent:
            return 100
        }
    }
    var minRevenue: Double {
        switch self {
        case .poorBad:
            return -1e6
        case .poor:
            return 0
        case .fairBad:
            return 1000
        case .fair:
            return 2000
        case .fairGood:
            return 4000
        case .average:
            return 7000
        case .averageGood:
            return 12000
        case .good:
            return 18000
        case .veryGood:
            return 25000
        case .excellent:
            return 50000
        case .veryExcellent:
            return 100000
        }
    }
    var maxRevenue: Double {
        switch self {
        case .poorBad:
            return 0
        case .poor:
            return 1000
        case .fairBad:
            return 2000
        case .fair:
            return 4000
        case .fairGood:
            return 7000
        case .average:
            return 12000
        case .averageGood:
            return 18000
        case .good:
            return 25000
        case .veryGood:
            return 50000
        case .excellent:
            return 100000
        case .veryExcellent:
            return 1e6
        }
    }
}

class DFKPILevel: NSObject {
    var typeIndex: Int = -1
    var typeName: String = ""
    var gradeValue: Double = 5
    
    init(typeId: Int)  {
        super.init()
        typeIndex = typeId
        typeName = KPILevel(type: typeIndex).typeName
        gradeValue = KPILevel(type: typeIndex).gradeValue
    }
    init(name: String) {
        super.init()
        typeIndex = getTypeIndex(typeName: name)
        typeName = KPILevel(type: typeIndex).typeName
        gradeValue = KPILevel(type: typeIndex).gradeValue
    }
    init(revenue: Double) {
        super.init()
        typeIndex = getTypeIndex(revenue: revenue)
        typeName = KPILevel(type: typeIndex).typeName
        gradeValue = KPILevel(type: typeIndex).gradeValue
    }
    private func getTypeIndex(typeName: String) -> Int {
        for i in 0..<KPILevel.allCases.count {
            if KPILevel.init(type: i).typeName.uppercased() == typeName.uppercased() {
                return i
            }
        }
        return -1
    }
    private func getTypeIndex(revenue: Double) -> Int {
        for i in 0..<KPILevel.allCases.count {
            if revenue >= KPILevel.init(type: i).minRevenue && revenue < KPILevel.init(type: i).maxRevenue {
                return i
            }
        }
        return -1
    }
}
