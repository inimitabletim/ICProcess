//
//  ModelPAD.swift
//  ICPinAssignmentViewer
//
//  Created by TimChi on 2025/3/26.
//

import Foundation
import SwiftUI

// 修改 ModelPAD
struct ModelPAD: ICComponent, Hashable {
    var id: UUID
    var name: String
    var memo: String?
    // ✅ 使用 ICPoint 替代分離的 x, y
    var position: CoordinateSystem.ICPoint
    var padPinName: String
    var isInnerConnectPad: Bool
    var isStagger: Bool
    var rotatedAngle: Double
    var staggerIndex: Int16
    
    var componentType: ComponentType { .pad }
    
    // 關聯
    var pinIDs: [UUID] = []
    var integratedCircuitID: UUID?
    var padDimensionID: UUID?
    var bondingPinConnectIDs: [UUID] = []
    
    // ✅ 新增：向後兼容的 centerLocateX/Y 屬性
    var centerLocateX: Int32 {
        get { Int32(position.x) }
        set { position.x = Double(newValue) }
    }
    
    var centerLocateY: Int32 {
        get { Int32(position.y) }
        set { position.y = Double(newValue) }
    }
    
    // 初始化方法 - 新版，使用 ICPoint
    init(id: UUID = UUID(), name: String, memo: String? = nil,
         position: CoordinateSystem.ICPoint,
         padPinName: String, isInnerConnectPad: Bool = false,
         isStagger: Bool = false, rotatedAngle: Double = 0,
         staggerIndex: Int16 = 0) {
        
        self.id = id
        self.name = name
        self.memo = memo
        self.position = position
        self.padPinName = padPinName
        self.isInnerConnectPad = isInnerConnectPad
        self.isStagger = isStagger
        self.rotatedAngle = rotatedAngle
        self.staggerIndex = staggerIndex
    }
    
    // 初始化方法 - 向後兼容舊版
    init(id: UUID = UUID(), name: String, memo: String? = nil,
         centerLocateX: Int32, centerLocateY: Int32,
         padPinName: String, isInnerConnectPad: Bool = false,
         isStagger: Bool = false, rotatedAngle: Double = 0,
         staggerIndex: Int16 = 0) {
        
        self.id = id
        self.name = name
        self.memo = memo
        self.position = CoordinateSystem.ICPoint(x: centerLocateX, y: centerLocateY)
        self.padPinName = padPinName
        self.isInnerConnectPad = isInnerConnectPad
        self.isStagger = isStagger
        self.rotatedAngle = rotatedAngle
        self.staggerIndex = staggerIndex
    }
}

// 修改 Point 結構體，整合到新系統
extension CoordinateSystem.ICPoint {
    // 從舊的 Point 結構轉換
    init(_ point: Point) {
        self.x = point.x
        self.y = point.y
    }
}
