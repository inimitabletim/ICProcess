//
//  ModelICIOPinSetup.swift
//  ICPinAssignmentViewer
//
//  Created by TimChi on 2025/3/26.
//

import Foundation

struct ModelICIOPinSetup: ICComponent, Hashable {
    var id: UUID
    var name: String
    var memo: String?
    var functionName: String
    var setupStatus: String
    
    var componentType: ComponentType { .iopin } // 實際上這是一個關聯實體
    
    // 關聯
    var ioPinID: UUID?
    
    init(id: UUID = UUID(), name: String, memo: String? = nil, functionName: String, setupStatus: String) {
        self.id = id
        self.name = name
        self.memo = memo
        self.functionName = functionName
        self.setupStatus = setupStatus
    }
}
