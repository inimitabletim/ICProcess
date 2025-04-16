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
    // 獲取 Pin 位置，統一返回 ICPoint
    func getPosition(pads: [UUID: ModelPAD]) -> CoordinateSystem.ICPoint? {
        // 如果 Pin 關聯了 PAD，位置就是 PAD 的中心點
        if let padID = padIDs.first, let pad = pads[padID] {
            return pad.position
        }
        return nil
    }
}
