//
//  ToolType.swift
//  ICEditorView
//
//  Created by TimChi on 2025/4/9.
//

import SwiftUI

/// 工具類型枚舉 - 用於表示UI層級的工具選擇
public enum ToolType: Int, Equatable {
    case select = 0
    case pan = 1
    case zoom = 2
    case edit = 3 // 編輯模式
    
    // 附加屬性
    var icon: String {
        switch self {
        case .select: return "arrow.up.left.and.down.right.magnifyingglass"
        case .pan: return "hand.draw.fill"
        case .zoom: return "magnifyingglass"
        case .edit: return "pencil"
        }
    }
    
    var name: String {
        switch self {
        case .select: return "選擇工具"
        case .pan: return "平移工具"
        case .zoom: return "縮放工具"
        case .edit: return "編輯工具"
        }
    }
    
    var color: Color {
        switch self {
        case .select: return .blue
        case .pan: return .green
        case .zoom: return .purple
        case .edit: return .orange
        }
    }
}
