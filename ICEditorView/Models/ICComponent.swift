//
//  ICComponent.swift
//  ICPinAssignmentViewer
//
//  Created by TimChi on 2025/3/26.
//

import Foundation

// MARK: - 基礎元件協議
protocol ICComponent: Identifiable, Codable {
    var id: UUID { get }
    var name: String { get set }
    var memo: String? { get set }
    
    // 元件類型識別
    var componentType: ComponentType { get }
}

// 元件類型列舉
enum ComponentType: String, Codable {
    case integratedCircuit
    case pin
    case pad
    case cell
    case pgpin
    case iopin
    case pgcell
    case iocell
    case innerPad
    case padDimension
}
