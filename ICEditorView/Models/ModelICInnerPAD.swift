//
//  ModelICInnerPAD.swift
//  ICPinAssignmentViewer
//
//  Created by TimChi on 2025/3/26.
//

import Foundation

struct ModelICInnerPAD: ICComponent, Hashable {
    var id: UUID
    var name: String
    var memo: String?
    
    var componentType: ComponentType { .innerPad }
    
    // 關聯
    var innerPinConnectIDs: [UUID] = []
    
    init(id: UUID = UUID(), name: String, memo: String? = nil) {
        self.id = id
        self.name = name
        self.memo = memo
    }
}
