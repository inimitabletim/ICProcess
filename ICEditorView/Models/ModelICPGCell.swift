//
//  ModelICPGCell.swift
//  ICPinAssignmentViewer
//
//  Created by TimChi on 2025/3/26.
//

import Foundation

struct ModelICPGCell: ICComponent, Hashable {
    var id: UUID
    var name: String
    var memo: String?
    var pgType: Int16
    
    var componentType: ComponentType { .pgcell }
    
    // 關聯
    var pgPinIDs: [UUID] = []
    
    init(id: UUID = UUID(), name: String, memo: String? = nil, pgType: Int16 = 0) {
        self.id = id
        self.name = name
        self.memo = memo
        self.pgType = pgType
    }
}
