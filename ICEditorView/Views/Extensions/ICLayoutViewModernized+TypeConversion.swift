//
//  ICLayoutViewModernized+TypeConversion.swift
//  ICEditorView
//
//  Created by TimChi on 2025/4/9.
//

import SwiftUI

// MARK: - 型別轉換擴展
extension ICLayoutViewState.LayoutTool {
    /// 從 ToolType 創建 LayoutTool
    static func from(_ toolType: ToolType) -> Self {
        switch toolType {
        case .select: return .select
        case .pan: return .pan
        case .zoom: return .zoom
        case .edit: return .select // 假設這裡 edit 對應到 select，需按實際情況調整
        }
    }
    
    /// 轉換為 ToolType
    func toToolType() -> ToolType {
        switch self {
        case .select: return .select
        case .pan: return .pan
        case .zoom: return .zoom
        case .addPin, .addPad, .connect, .browse: return .select // 預設對應到 select
        }
    }
    
    /// 檢查是否等於指定的 ToolType
    func equals(_ toolType: ToolType) -> Bool {
        switch (self, toolType) {
        case (.select, .select), (.pan, .pan), (.zoom, .zoom):
            return true
        case (.select, .edit):
            return true  // 特殊情況：edit 對應到 select
        default:
            return false
        }
    }
}

// 反向轉換擴展
extension ToolType {
    /// 轉換為 LayoutTool
    func toLayoutTool() -> ICLayoutViewState.LayoutTool {
        return ICLayoutViewState.LayoutTool.from(self)
    }
    
    /// 檢查是否等於指定的 LayoutTool
    func equals(_ layoutTool: ICLayoutViewState.LayoutTool) -> Bool {
        return layoutTool.equals(self)
    }
}

// MARK: - ICLayoutViewModernized 擴展 - 型別處理
extension ICLayoutViewModernized {
    // 用於簡化型別操作的工具函數
    
    /// 將 ToolType 轉換為 LayoutTool
    func convertToLayoutTool(_ toolType: ToolType) -> ICLayoutViewState.LayoutTool {
        return ICLayoutViewState.LayoutTool.from(toolType)
    }
    
    /// 將 LayoutTool 轉換為 ToolType
    func convertToToolType(_ layoutTool: ICLayoutViewState.LayoutTool) -> ToolType {
        return layoutTool.toToolType()
    }
    
    /// 檢查視圖狀態工具是否為指定工具類型
    func isViewStateTool(_ toolType: ToolType) -> Bool {
        return viewState.selectedTool.equals(toolType)
    }
}
