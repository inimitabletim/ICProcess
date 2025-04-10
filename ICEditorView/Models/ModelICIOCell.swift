//
//  ModelICIOCell.swift
//  ICPinAssignmentViewer
//
//  Created by TimChi on 2025/3/26.
//

import Foundation

struct ModelICIOCell: ICComponent, Hashable {
    var id: UUID
    var name: String
    var memo: String?
    var ioType: Int16
    
    var componentType: ComponentType { .iocell }
    
    // 關聯
    var ioPinIDs: [UUID] = []
    
    init(id: UUID = UUID(), name: String, memo: String? = nil, ioType: Int16 = 0) {
        self.id = id
        self.name = name
        self.memo = memo
        self.ioType = ioType
    }
}
