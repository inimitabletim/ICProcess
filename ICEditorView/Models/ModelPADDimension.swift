//
//  ModelPADDimension.swift
//  ICPinAssignmentViewer
//
//  Created by TimChi on 2025/3/26.
//

import Foundation
import SwiftUI

struct ModelPADDimension: ICComponent, Hashable {
    var id: UUID
    var name: String
    var memo: String?
    var height: Int32
    var width: Int32
    
    var componentType: ComponentType { .padDimension }
    
    // 轉換為CGSize (用於UI顯示)
    var size: CGSize {
        return CGSize(width: CGFloat(width), height: CGFloat(height))
    }
    
    // 關聯
    var padIDs: [UUID] = []
    var integratedCircuitIDs: [UUID] = []
    
    init(id: UUID = UUID(), name: String, memo: String? = nil, height: Int32, width: Int32) {
        self.id = id
        self.name = name
        self.memo = memo
        self.height = height
        self.width = width
    }
}
