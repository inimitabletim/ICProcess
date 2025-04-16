//
//  ICLayoutViewModernized+GestureContext.swift
//  ICEditorView
//
//  Created by TimChi on 2025/4/11.
//

import SwiftUI
import Combine

// MARK: - 情境感知引擎擴展
extension ICLayoutViewModernized {
    
    /// 用戶意圖枚舉 - 表示可能的操作意圖
    enum UserIntent {
        case selectComponent       // 選擇元件
        case dragComponent         // 拖曳元件
        case panCanvas             // 平移畫布
        case zoomCanvas            // 縮放畫布
        case rotateComponent       // 旋轉元件
        case multiSelect           // 多選操作
        case specialToolOperation  // 特殊工具操作
        case undefined             // 未定義/未知意圖
    }
    
    /// 手勢情境資訊結構 - 封裝手勢的上下文信息
    struct GestureContext {
        // 位置信息
        var startLocation: CGPoint = .zero
        var currentLocation: CGPoint = .zero
        var startContentLocation: CGPoint = .zero  // 轉換到內容座標系的起始位置
        var currentContentLocation: CGPoint = .zero  // 轉換到內容座標系的當前位置
        
        // 觸發對象
        var targetComponentID: UUID? = nil
        var isTargetPin: Bool = false
        var isTargetPad: Bool = false
        var isTargetSelected: Bool = false
        
        // 手勢資訊
        var translation: CGSize = .zero
        var contentTranslation: CGSize = .zero  // 轉換到內容座標系的偏移量
        var scale: CGFloat = 1.0
        var rotation: Angle = .zero
        var velocity: CGSize = .zero
        var pressure: CGFloat = 0.0  // 壓力值 (僅適用於支援3D Touch/Haptic Touch的設備)
        
        // 手勢狀態
        var phase: GesturePhase = .undefined
        var duration: TimeInterval = 0.0  // 手勢持續時間
        
        // 修飾符狀態
        var modifiers: GestureModifiers = []
        
        // 系統狀態
        var viewMode: ICLayoutViewState.LayoutTool = .browse
        var isEditMode: Bool = false
        var isMultiSelectMode: Bool = false
        
        // 👆 手勢階段枚舉
        enum GesturePhase {
            case undefined   // 未定義
            case began       // 開始
            case changed     // 變化中
            case ended       // 結束
            case cancelled   // 取消
        }
        
        /// 更新情境資訊 - 根據當前值更新派生屬性
        mutating func update(with gestureState: GestureState, viewState: ICLayoutViewState) {
            // 更新視圖模式
            self.viewMode = viewState.selectedTool
            self.isEditMode = viewState.isEditMode
            
            // 更新內容座標
            if startLocation != .zero {
                startContentLocation = screenToContentCoordinate(
                    screenPoint: startLocation,
                    scale: gestureState.scale,
                    offset: gestureState.offset
                )
            }
            
            if currentLocation != .zero {
                currentContentLocation = screenToContentCoordinate(
                    screenPoint: currentLocation,
                    scale: gestureState.scale,
                    offset: gestureState.offset
                )
            }
            
            // 計算內容座標系中的偏移量
            if startContentLocation != .zero && currentContentLocation != .zero {
                contentTranslation = CGSize(
                    width: currentContentLocation.x - startContentLocation.x,
                    height: currentContentLocation.y - startContentLocation.y
                )
            }
        }
        
        /// 座標轉換 - 螢幕座標到內容座標
        private func screenToContentCoordinate(screenPoint: CGPoint, scale: CGFloat, offset: CGSize) -> CGPoint {
            return CGPoint(
                x: (screenPoint.x - offset.width) / scale,
                y: (screenPoint.y - offset.height) / scale
            )
        }
        
        /// 重置情境
        mutating func reset() {
            startLocation = .zero
            currentLocation = .zero
            startContentLocation = .zero
            currentContentLocation = .zero
            targetComponentID = nil
            isTargetPin = false
            isTargetPad = false
            isTargetSelected = false
            translation = .zero
            contentTranslation = .zero
            scale = 1.0
            rotation = .zero
            velocity = .zero
            pressure = 0.0
            phase = .undefined
            duration = 0.0
        }
    }
    
    // MARK: - 情境感知引擎主方法
    
    /// 推斷用戶意圖 - 核心情境感知方法
    func inferUserIntent(context: GestureContext) -> UserIntent {
        // 📝 首先處理特殊修飾符情況
        
        // 1. 如果按下空格鍵，強制平移畫布
        if context.modifiers.contains(.space) {
            return .panCanvas
        }
        
        // 2. 如果處於多選模式且有元件被點擊，則為多選操作
        if (context.modifiers.contains(.shift) || isMultiSelectMode) && context.targetComponentID != nil {
            return .multiSelect
        }
        
        // 判斷是否有目標元件
        if let componentID = context.targetComponentID {
            // 目標元件存在
            
            // 在編輯模式下，點擊元件通常意味著要拖動它
            if context.isEditMode {
                // 如果有明顯的移動，視為拖動
                let moveDistance = sqrt(
                    pow(context.translation.width, 2) +
                    pow(context.translation.height, 2)
                )
                
                if moveDistance > 5 {  // 5pt的閾值，避免微小抖動
                    return .dragComponent
                } else {
                    // 很小的移動視為選擇
                    return .selectComponent
                }
            } else {
                // 非編輯模式下，點擊元件通常只是選擇它
                return .selectComponent
            }
        } else {
            // 沒有目標元件，在空白區域 - 默認平移畫布
            return .panCanvas
        }
    }
    
    /// 處理意圖轉換策略 - 處理用戶意圖變化
    func handleIntentTransition(previousIntent: UserIntent?, newIntent: UserIntent) -> UserIntent {
        
        // 確保旋轉意圖不會被觸發
        if newIntent == .rotateComponent {
            return .panCanvas  // 轉為平移或其他適當的操作
        }
        
        // 如果沒有先前意圖，直接使用新意圖
        guard let previousIntent = previousIntent else {
            return newIntent
        }
        
        // 意圖一致性檢查 - 防止意圖在操作過程中突然變化
        
        // 當從選擇變為拖動時，允許變化
        if previousIntent == .selectComponent && newIntent == .dragComponent {
            return .dragComponent
        }
        
        // 若當前正在拖動元件，保持拖動狀態直到結束
        if previousIntent == .dragComponent &&
           (newIntent == .panCanvas || newIntent == .selectComponent) {
            return .dragComponent
        }
        
        // 若當前正在平移畫布，保持平移狀態直到結束
        if previousIntent == .panCanvas && newIntent == .selectComponent {
            return .panCanvas
        }
        
        // 其他情況下使用新意圖
        return newIntent
    }
    
    /// 創建手勢情境 - 從手勢值建立情境
    func createGestureContext(
        from value: DragGesture.Value,
        in gestureState: GestureState
    ) -> GestureContext {
        var context = GestureContext()
        
        // 設置基本位置信息
        context.startLocation = value.startLocation
        context.currentLocation = value.location
        context.translation = value.translation
        
        // 設置手勢階段
        context.phase = .changed
        
        // 設置修飾符
        context.modifiers = gestureState.gestureModifiers
        
        // 設置系統狀態
        context.viewMode = viewState.selectedTool
        context.isEditMode = viewState.isEditMode
        context.isMultiSelectMode = isMultiSelectMode
        
        // 檢測目標元件 - 在手勢起始位置
        context.targetComponentID = hitTest(value.startLocation)
        
        // 如果有目標元件，判斷類型和選擇狀態
        if let componentID = context.targetComponentID {
            context.isTargetPin = layoutManager.pins[componentID] != nil
            context.isTargetPad = layoutManager.pads[componentID] != nil
            context.isTargetSelected = layoutManager.selectedComponents.contains(componentID)
        }
        
        // 更新派生屬性
        context.update(with: gestureState, viewState: viewState)
        
        return context
    }
    
    /// 更新情境 - 使用新手勢值更新現有情境
    func updateGestureContext(
        context: inout GestureContext,
        with value: DragGesture.Value,
        in gestureState: GestureState
    ) {
        // 更新位置信息
        context.currentLocation = value.location
        context.translation = value.translation
        
        // 更新系統狀態
        context.viewMode = viewState.selectedTool
        context.isEditMode = viewState.isEditMode
        context.isMultiSelectMode = isMultiSelectMode
        
        // 更新修飾符
        context.modifiers = gestureState.gestureModifiers
        
        // 更新派生屬性
        context.update(with: gestureState, viewState: viewState)
    }
}
