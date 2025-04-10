//
//  ModelICIOPin.swift
//  ICPinAssignmentViewer
//
//  Created by TimChi on 2025/3/26.
//

import Foundation

struct ModelICIOPin: ICComponent, Hashable {
    var id: UUID
    var name: String
    var memo: String?
    
    var componentType: ComponentType { .iopin }
    
    // 關聯
    var circuitIOPinID: UUID?
    var ioCellID: UUID?
    var ioPinSetupIDs: [UUID] = []
    var ioOperateSPECID: UUID?
    
    init(id: UUID = UUID(), name: String, memo: String? = nil) {
        self.id = id
        self.name = name
        self.memo = memo
    }
}
