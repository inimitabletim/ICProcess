//
//  ModelIntegratedCircuit.swift
//  ICPinAssignmentViewer
//
//  Created by TimChi on 2025/3/26.
//

import Foundation

struct ModelIntegratedCircuit: ICComponent, Hashable {
    var id: UUID
    var name: String
    var memo: String?
    var designDate: Date
    var version: String
    
    var componentType: ComponentType { .integratedCircuit }
    
    // 各種關聯ID集合
    var icPinIDs: [UUID] = []
    var icPadIDs: [UUID] = []
    var icFrameIDs: [UUID] = []
    var operatingConditionIDs: [UUID] = []
    var pgVoltageIDs: [UUID] = []
    var projectLibraryID: UUID?
    var tapeOutFloorPlanIDs: [UUID] = []
    var modelLibraryIDs: [UUID] = []
    var padDimensionIDs: [UUID] = []
    var topCellID: UUID?
    
    init(id: UUID = UUID(), name: String, memo: String? = nil, designDate: Date = Date(), version: String = "1.0") {
        self.id = id
        self.name = name
        self.memo = memo
        self.designDate = designDate
        self.version = version
    }
}


