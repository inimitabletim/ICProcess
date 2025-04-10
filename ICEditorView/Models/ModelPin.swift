//
//  ModelPin.swift
//  ICPinAssignmentViewer
//
//  Created by TimChi on 2025/3/26.
//

import Foundation

struct ModelPin: ICComponent, Hashable {
    var id: UUID
    var name: String
    var memo: String?
    var pinIndex: Int32
    var pinName: String
    var pinType: Int16
    
    var componentType: ComponentType { .pin }
    
    // 關聯
    var padIDs: [UUID] = []
    var integratedCircuitID: UUID?
    var cellLibPinNodeID: UUID?
    var ioSubBlockID: UUID?
    
    init(id: UUID = UUID(), name: String, memo: String? = nil, pinIndex: Int32, pinName: String, pinType: Int16 = 0) {
        self.id = id
        self.name = name
        self.memo = memo
        self.pinIndex = pinIndex
        self.pinName = pinName
        self.pinType = pinType
    }
    
    // 獲取Pin位置 (如果有關聯的PAD)
    func getPosition(pads: [UUID: ModelPAD]) -> Point? {
        // 如果Pin關聯了PAD，位置就是PAD的中心點
        if let padID = padIDs.first, let pad = pads[padID] {
            return pad.position
        }
        return nil
    }
}
