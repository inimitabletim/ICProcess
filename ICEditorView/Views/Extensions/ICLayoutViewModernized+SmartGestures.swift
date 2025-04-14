//
//  ICLayoutViewModernized+SmartGestures.swift
//  ICEditorView
//
//  Created by TimChi on 2025/4/11.
//

import SwiftUI
import Combine

// MARK: - 智能手勢處理擴展
extension ICLayoutViewModernized {
    
    /// 情境手勢系統的主入口
    /// 建立智能化的混合手勢處理方式
    func configureContextAwareGestures() -> some Gesture {
        // 追蹤當前意圖，確保操作的連貫性
        let intentHolder = IntentHolder()

        // 1. 拖曳手勢 - 處理選擇、拖曳元件和平移視圖
        let dragGesture = DragGesture(minimumDistance: 2)
            .onChanged { value in
                // 建立或更新手勢情境
                var context: GestureContext
                if intentHolder.gestureActive {
                    // 更新現有情境
                    context = intentHolder.context
                    updateGestureContext(context: &context, with: value, in: gestureState)
                } else {
                    // 新建情境
                    context = createGestureContext(from: value, in: gestureState)
                    intentHolder.gestureActive = true
                }
                
                // 推斷用戶意圖
                let newIntent = inferUserIntent(context: context)
                
                // 處理意圖轉換 - 確保操作連貫性
                let finalIntent = handleIntentTransition(
                    previousIntent: intentHolder.currentIntent,
                    newIntent: newIntent
                )
                
                // 更新持有的意圖和情境
                intentHolder.currentIntent = finalIntent
                intentHolder.context = context
                
                // 根據意圖執行相應操作
                handleGestureIntent(intent: finalIntent, context: context, value: value)
            }
            .onEnded { value in
                // 確保有活動的手勢
                guard intentHolder.gestureActive, let intent = intentHolder.currentIntent else {
                    // 重置狀態
                    intentHolder.reset()
                    return
                }
                
                // 更新情境以供結束處理
                var context = intentHolder.context
                updateGestureContext(context: &context, with: value, in: gestureState)
                context.phase = .ended
                
                // 處理手勢結束操作
                finalizeGestureIntent(intent: intent, context: context, value: value)
                
                // 重置狀態
                intentHolder.reset()
            }
        
        // 2. 縮放手勢 - 處理畫面縮放
        let magnificationGesture = MagnificationGesture(minimumScaleDelta: 0.01)
            .onChanged { value in
                // 設置縮放狀態
                gestureState.isZooming = true
                
                // 計算新的縮放值
                let newScale = gestureState.lastScale * value
                
                // 應用縮放，無條件地允許縮放
                withAnimation(.interactiveSpring(response: 0.15, dampingFraction: 0.85)) {
                    gestureState.scale = min(max(gestureState.minScale, newScale), gestureState.maxScale)
                }
                
                // 縮放超過閾值時提供輕微觸覺反饋
                if abs(gestureState.scale - gestureState.lastScale) > 0.05 {
                    performHapticFeedback(intensity: 0.15)
                }
            }
            .onEnded { _ in
                // 保存最終縮放值
                gestureState.lastScale = gestureState.scale
                gestureState.isZooming = false
                
                // 提供反饋
                showFeedback("縮放: \(Int(gestureState.scale * 100))%", true)
            }
        
        // 3. 旋轉手勢 - 未在階段一實現，但保留接口
        let rotationGesture = RotationGesture()
            .onChanged { angle in
                // 僅在編輯模式且有選中元件時啟用
                guard viewState.isEditMode && !layoutManager.selectedComponents.isEmpty else {
                    return
                }
                
                // 旋轉相關邏輯會在後續階段實現
            }
            .onEnded { _ in
                // 旋轉結束邏輯
            }
        
        // 優先處理拖曳，同時支援縮放和旋轉
        return dragGesture
            .simultaneously(with:
                magnificationGesture.simultaneously(with: rotationGesture)
            )
    }
    
    // MARK: - 意圖持有者類
    
    /// 意圖持有者 - 用於跨越多個手勢事件追蹤和保持用戶意圖
    class IntentHolder {
        var currentIntent: UserIntent? = nil
        var gestureActive: Bool = false
        var context: GestureContext = GestureContext()
        
        func reset() {
            currentIntent = nil
            gestureActive = false
            context.reset()
        }
    }
    
    // MARK: - 情境感知手勢處理實現
    
    /// 根據用戶意圖處理手勢變化
    private func handleGestureIntent(
        intent: UserIntent,
        context: GestureContext,
        value: DragGesture.Value
    ) {
        // 更新錯誤位置
        gestureState.lastCursorX = value.location.x
        gestureState.lastCursorY = value.location.y
        
        // 根據意圖分派不同的處理邏輯
        switch intent {
        case .selectComponent:
            handleSelectComponentIntent(context: context)
            
        case .dragComponent:
            handleDragComponentIntent(context: context, value: value)
            
        case .panCanvas:
            handlePanCanvasIntent(context: context, value: value)
            
        case .zoomCanvas:
            // 縮放由 MagnificationGesture 處理
            break
            
        case .rotateComponent:
            // 旋轉功能在階段一不實現
            break
            
        case .multiSelect:
            handleMultiSelectIntent(context: context)
            
        case .specialToolOperation:
            // 特殊工具操作，通常由工具列控制
            break
            
        case .undefined:
            // 未定義的意圖，默認為平移
            handlePanCanvasIntent(context: context, value: value)
        }
    }
    
    /// 根據用戶意圖處理手勢結束
    private func finalizeGestureIntent(
        intent: UserIntent,
        context: GestureContext,
        value: DragGesture.Value
    ) {
        switch intent {
        case .selectComponent:
            finalizeSelectComponentIntent(context: context)
            
        case .dragComponent:
            finalizeDragComponentIntent(context: context)
            
        case .panCanvas:
            finalizePanCanvasIntent(context: context, value: value)
            
        case .zoomCanvas:
            // 縮放由 MagnificationGesture 處理
            break
            
        case .rotateComponent:
            // 旋轉功能在階段一不實現
            break
            
        case .multiSelect:
            finalizeMultiSelectIntent(context: context)
            
        case .specialToolOperation:
            // 特殊工具操作，通常由工具列控制
            break
            
        case .undefined:
            // 未定義的意圖，默認為平移
            finalizePanCanvasIntent(context: context, value: value)
        }
    }
    
    // MARK: - 選擇元件意圖處理
    
    /// 處理選擇元件意圖
    private func handleSelectComponentIntent(context: GestureContext) {
        // 如果沒有目標元件，不做任何操作
        guard let componentID = context.targetComponentID else { return }
        
        // 更新選擇視覺狀態
        if !gestureState.isDragging {
            gestureState.isDragging = true
            gestureState.draggedComponentID = componentID
            
            // 如果元件未被選中，選中它
            if !layoutManager.selectedComponents.contains(componentID) {
                selectSingleComponent(componentID)
            }
        }
    }
    
    /// 完成選擇元件意圖
    private func finalizeSelectComponentIntent(context: GestureContext) {
        // 如果存在目標元件，確認選擇
        if let componentID = context.targetComponentID {
            // 處理點擊事件
            if context.modifiers.contains(.shift) || isMultiSelectMode {
                toggleComponentSelection(componentID)
            } else {
                // 一般情況下選擇單一元件
                selectSingleComponent(componentID)
            }
            
            // 觸覺反饋
            performHapticFeedback(intensity: 0.3)
        }
        
        // 重置拖曳狀態
        gestureState.isDragging = false
        gestureState.draggedComponentID = nil
    }
    
    // MARK: - 拖曳元件意圖處理
    
    /// 處理拖曳元件意圖
    private func handleDragComponentIntent(context: GestureContext, value: DragGesture.Value) {
        // 確保有元件被選擇
        guard let componentID = context.targetComponentID else { return }
        
        // 設置拖曳狀態
        if !gestureState.isDragging {
            gestureState.isDragging = true
            gestureState.draggedComponentID = componentID
            gestureState.dragStartLocation = value.startLocation
            
            // 如果使用拖曳預覽功能
            if dragPreviewManager.previewEnabled {
                startDragPreview(
                    componentID: componentID,
                    startLocation: value.startLocation,
                    currentLocation: value.location
                )
            } else {
                // 儲存元件初始位置
                if let pad = layoutManager.pads[componentID] {
                    gestureState.dragStartComponentPosition = CGPoint(
                        x: CGFloat(pad.centerLocateX),
                        y: CGFloat(pad.centerLocateY)
                    )
                }
                
                // 處理批量拖曳邏輯
                if (gestureState.gestureModifiers.contains(.shift) ||
                    isMultiSelectMode ||
                    layoutManager.selectedComponents.count > 1) &&
                    layoutManager.selectedComponents.contains(componentID) {
                    
                    // 儲存所有選中元件的初始位置
                    for id in layoutManager.selectedComponents {
                        if let pad = layoutManager.pads[id] {
                            gestureState.componentsStartPositions[id] = CGPoint(
                                x: CGFloat(pad.centerLocateX),
                                y: CGFloat(pad.centerLocateY)
                            )
                        }
                    }
                } else {
                    // 單個元件拖曳，確保已選中
                    if !layoutManager.selectedComponents.contains(componentID) {
                        layoutManager.clearSelection()
                        layoutManager.selectComponent(id: componentID)
                    }
                }
            }
            
            // 提供觸覺反饋
            performHapticFeedback(intensity: 0.2)
            showFeedback("拖曳元件", false)
        }
        
        // 更新拖曳位置
        if dragPreviewManager.previewEnabled {
            updateDragPreview(currentLocation: value.location)
        } else {
            // 批量拖曳所有選中的元件
            if layoutManager.selectedComponents.count > 1 &&
               layoutManager.selectedComponents.contains(componentID) {
                updateBatchComponentPositions()
            } else {
                // 或者移動單個元件
                updateSingleComponentPosition(componentID: componentID)
            }
        }
    }
    
    /// 完成拖曳元件意圖
    private func finalizeDragComponentIntent(context: GestureContext) {
        if dragPreviewManager.previewEnabled {
            // 使用預覽模式
            finalizeDragPreview()
        } else {
            // 使用直接移動模式
            gestureState.isDragging = false
            gestureState.draggedComponentID = nil
            gestureState.dragStartLocation = nil
            gestureState.dragCurrentLocation = nil
            gestureState.dragStartComponentPosition = nil
            gestureState.componentsStartPositions.removeAll()
            
            // 提供反饋
            performHapticFeedback(intensity: 0.4)
            showFeedback("移動元件完成", true)
            
            // 記錄操作歷史
            layoutManager.recordHistory()
        }
    }
    
    // MARK: - 平移畫布意圖處理
    
    /// 處理平移畫布意圖
    private func handlePanCanvasIntent(context: GestureContext, value: DragGesture.Value) {
        // 啟動平移狀態
        if !gestureState.isPanning {
            gestureState.isPanning = true
            gestureState.panStartLocation = value.startLocation
            
            // 提供輕微觸覺反饋
            performHapticFeedback(intensity: 0.1)
            
            // 自動切換到平移工具
            if viewState.selectedTool != .pan {
                viewState.previousTool = viewState.selectedTool
                viewState.selectedTool = .pan
            }
        }
        
        // 更新畫布位置
        withAnimation(.interactiveSpring(response: 0.2, dampingFraction: 0.8)) {
            gestureState.offset = CGSize(
                width: gestureState.lastOffset.width + value.translation.width,
                height: gestureState.lastOffset.height + value.translation.height
            )
        }
    }
    
    /// 完成平移畫布意圖
    private func finalizePanCanvasIntent(context: GestureContext, value: DragGesture.Value) {
        // 更新最終位置
        gestureState.lastOffset = gestureState.offset
        gestureState.isPanning = false
        gestureState.panStartLocation = nil
        
        // 計算總移動距離
        let distance = sqrt(pow(value.translation.width, 2) + pow(value.translation.height, 2))
        
        // 如果移動距離很小，可能是點擊空白區域
        if distance < 5 && context.targetComponentID == nil {
            // 清除選擇
            layoutManager.clearSelection()
            showingComponentDetails = false
            selectedComponentID = nil
            showFeedback("清除選擇", false)
        } else if distance > 5 {
            // 正常的平移反饋
            performHapticFeedback(intensity: 0.2)
            showFeedback("平移完成", true)
        }
        
        // 恢復之前的工具模式
        if let previousTool = viewState.previousTool {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                withAnimation {
                    viewState.selectedTool = previousTool
                    viewState.previousTool = nil
                }
            }
        }
    }
    
    // MARK: - 多選意圖處理
    
    /// 處理多選意圖
    private func handleMultiSelectIntent(context: GestureContext) {
        // 如果沒有目標元件，不做任何操作
        guard let componentID = context.targetComponentID else { return }
        
        // 不需要具體更新視圖，僅在結束時處理
    }
    
    /// 完成多選意圖
    private func finalizeMultiSelectIntent(context: GestureContext) {
        // 如果存在目標元件，切換其選擇狀態
        if let componentID = context.targetComponentID {
            // 切換選擇狀態
            toggleComponentSelection(componentID)
            
            // 觸覺反饋
            performHapticFeedback(intensity: 0.3)
            showFeedback("批量選擇: \(layoutManager.selectedComponents.count)個元件", true)
        }
    }
    
    // MARK: - 批量操作輔助方法
    
    /// 更新批量元件位置
    private func updateBatchComponentPositions() {
        if let startLocation = gestureState.dragStartLocation {
            let currentLocation = gestureState.dragCurrentLocation ?? startLocation
            
            // 轉換座標系並計算移動差值
            let startContentPoint = screenToContentCoordinate(screenPoint: startLocation)
            let currentContentPoint = screenToContentCoordinate(screenPoint: currentLocation)
            
            let contentDelta = CGSize(
                width: currentContentPoint.x - startContentPoint.x,
                height: currentContentPoint.y - startContentPoint.y
            )
            
            // 移動所有選中的元件
            for componentID in layoutManager.selectedComponents {
                if let startPosition = gestureState.componentsStartPositions[componentID] {
                    movePADToPosition(
                        padID: componentID,
                        newPosition: CGPoint(
                            x: startPosition.x + contentDelta.width,
                            y: startPosition.y + contentDelta.height
                        )
                    )
                }
            }
        }
    }
    
    /// 更新單個元件位置
    private func updateSingleComponentPosition(componentID: UUID) {
        if let startLocation = gestureState.dragStartLocation {
            let currentLocation = gestureState.dragCurrentLocation ?? startLocation
            
            // 轉換座標系並計算移動差值
            let startContentPoint = screenToContentCoordinate(screenPoint: startLocation)
            let currentContentPoint = screenToContentCoordinate(screenPoint: currentLocation)
            
            let contentDelta = CGSize(
                width: currentContentPoint.x - startContentPoint.x,
                height: currentContentPoint.y - startContentPoint.y
            )
            
            // 使用初始位置加上移動距離
            if let startPosition = gestureState.dragStartComponentPosition {
                movePADToPosition(
                    padID: componentID,
                    newPosition: CGPoint(
                        x: startPosition.x + contentDelta.width,
                        y: startPosition.y + contentDelta.height
                    )
                )
            }
        }
    }
}
