//
//  ModelPAD.swift
//  ICPinAssignmentViewer
//
//  Created by TimChi on 2025/3/26.
//

import Foundation
import SwiftUI

struct ModelPAD: ICComponent, Hashable {
    var id: UUID
    var name: String
    var memo: String?
    var centerLocateX: Int32
    var centerLocateY: Int32
    var padPinName: String
    var isInnerConnectPad: Bool
    var isStagger: Bool
    var rotatedAngle: Double
    var staggerIndex: Int16
    
    var componentType: ComponentType { .pad }
    
    // 計算屬性：位置點
    var position: Point {
        return Point(x: Double(centerLocateX), y: Double(centerLocateY))
    }
    
    // 關聯
    var pinIDs: [UUID] = []
    var integratedCircuitID: UUID?
    var padDimensionID: UUID?
    var bondingPinConnectIDs: [UUID] = []
    
    init(id: UUID = UUID(), name: String, memo: String? = nil,
         centerLocateX: Int32, centerLocateY: Int32,
         padPinName: String, isInnerConnectPad: Bool = false,
         isStagger: Bool = false, rotatedAngle: Double = 0,
         staggerIndex: Int16 = 0) {
        
        self.id = id
        self.name = name
        self.memo = memo
        self.centerLocateX = centerLocateX
        self.centerLocateY = centerLocateY
        self.padPinName = padPinName
        self.isInnerConnectPad = isInnerConnectPad
        self.isStagger = isStagger
        self.rotatedAngle = rotatedAngle
        self.staggerIndex = staggerIndex
    }
    
    // 計算旋轉後點的位置
    func rotatedPoint(_ point: Point) -> Point {
        return point.rotated(around: position, by: rotatedAngle)
    }
}
