//
//  ICLayoutViewModernized+ClickHandling.swift
//  ICEditorView
//
//  Created by TimChi on 2025/4/14.
//

import SwiftUI
import Combine

extension ICLayoutViewModernized {
    
    /// 處理元件點擊 - 加強穩定性
    func stableComponentTap(_ componentID: UUID) {
        // 顯示調試信息
        if showDebugInfo {
            if let pin = layoutManager.pins[componentID] {
                print("👆 處理Pin點擊：\(pin.name)")
            } else if let pad = layoutManager.pads[componentID] {
                print("👆 處理PAD點擊：\(pad.name)")
            }
        }
        
        // 檢查元件是否已經被選中
        let isAlreadySelected = layoutManager.selectedComponents.contains(componentID)
        
        // 檢查多選模式
        if gestureState.gestureModifiers.contains(.shift) || isMultiSelectMode {
            // 多選模式 - 切換選擇狀態
            if isAlreadySelected {
                layoutManager.deselectComponent(id: componentID)
                
                // 如果取消選擇的是當前顯示詳情的元件，關閉詳情面板
                if selectedComponentID == componentID {
                    selectedComponentID = nil
                    showingComponentDetails = false
                }
            } else {
                layoutManager.selectComponent(id: componentID)
            }
            
            // 提供反饋
            performHapticFeedback(intensity: 0.3)
            provideFeedback(
                message: "批量選擇: \(layoutManager.selectedComponents.count)個元件",
                type: .info,
                intensity: .medium
            )
        } else {
            // 單選模式
            if isAlreadySelected {
                // 已選中的元件再次點擊時，取消選擇
                layoutManager.deselectComponent(id: componentID)
                selectedComponentID = nil
                showingComponentDetails = false
                
                performHapticFeedback(intensity: 0.3)
                provideFeedback(
                    message: "取消選擇元件",
                    type: .info,
                    intensity: .medium
                )
            } else {
                // 選擇新元件，清除其他選擇
                layoutManager.clearSelection()
                layoutManager.selectComponent(id: componentID)
                
                // 選擇元件後也顯示詳情
                selectedComponentID = componentID
                showingComponentDetails = true
                
                // 提供反饋
                performHapticFeedback(intensity: 0.3)
                
                // 顯示不同類型的反饋
                if let pin = layoutManager.pins[componentID] {
                    provideFeedback(
                        message: "已選擇Pin: \(pin.name)",
                        type: .success,
                        intensity: .medium
                    )
                } else if let pad = layoutManager.pads[componentID] {
                    provideFeedback(
                        message: "已選擇PAD: \(pad.name)",
                        type: .success,
                        intensity: .medium
                    )
                }
            }
        }
    }
    
    /// 處理內容區域點擊 - 加強穩定性
    func stableContentTap(at location: CGPoint) {
        // 記錄點擊位置
        gestureState.lastCursorX = location.x
        gestureState.lastCursorY = location.y
        
        // 顯示點擊檢測反饋（僅調試模式）
        showHitTestFeedback(at: location)
        
        // 使用增強的碰撞檢測
        if let componentID = enhancedHitTest(location) {
            // 點擊到元件，處理元件點擊
            stableComponentTap(componentID)
        } else {
            // 點擊空白處，不取消選擇
            // 僅在需要時提供反饋
            if showDebugInfo {
                print("❌ 點擊空白處 - 預備平移畫面")
            }
        }
    }
    
    /// 在 DragGesture 結束時處理點擊行為
    func handleTapFromDragGesture(_ value: DragGesture.Value) {
        // 計算拖曳距離
        let dragDistance = sqrt(
            pow(value.translation.width, 2) +
            pow(value.translation.height, 2)
        )
        
        // 如果移動距離很小，視為點擊
        if dragDistance < 3 {
            // 使用增強的碰撞檢測
            if let componentID = enhancedHitTest(value.location) {
                // 點擊到元件
                stableComponentTap(componentID)
            } else {
                // 點擊空白處
                if !gestureState.gestureModifiers.contains(.shift) {
                    layoutManager.clearSelection()
                    showingComponentDetails = false
                    selectedComponentID = nil
                    
                    provideFeedback(
                        message: "清除選擇",
                        type: .info,
                        intensity: .light
                    )
                }
            }
        }
    }
}
