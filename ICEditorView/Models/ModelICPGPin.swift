//
//  ModelICPGPin.swift
//  ICPinAssignmentViewer
//
//  Created by TimChi on 2025/3/26.
//

import Foundation

struct ModelICPGPin: ICComponent, Hashable {
    var id: UUID
    var name: String
    var memo: String?
    var requirePowerW: Double?
    
    var componentType: ComponentType { .pgpin }
    
    // 關聯
    var pgCellID: UUID?
    var pgVoltageID: UUID?
    
    init(id: UUID = UUID(), name: String, memo: String? = nil, requirePowerW: Double? = nil) {
        self.id = id
        self.name = name
        self.memo = memo
        self.requirePowerW = requirePowerW
    }
}
