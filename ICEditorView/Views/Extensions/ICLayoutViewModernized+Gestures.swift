//
//  ICLayoutViewModernized+Gestures.swift
//  ICEditorView
//
//  Created by TimChi on 2025/4/8.
//

import SwiftUI
import Combine

// MARK: - 主要手勢擴展
extension ICLayoutViewModernized {
    // MARK: - 組合手勢
    func configureGestures() -> some Gesture {
        SimultaneousGesture(
            dragGesture(),
            SimultaneousGesture(
                magnificationGesture(),
                rotationGesture()
            )
        )
    }
    
    // MARK: - 拖曳手勢
    func dragGesture() -> some Gesture {
        DragGesture(minimumDistance: 2)
            .onChanged { value in
                // 保存滑鼠/觸控位置
                gestureState.lastCursorX = value.location.x
                gestureState.lastCursorY = value.location.y
                
                // 處理元件拖曳邏輯...
                if viewState.isEditMode && !gestureState.isDragging && !gestureState.isPanning {
                    // 檢查起始點是否在元件上...
                    if let componentID = hitTest(value.startLocation) {
                        handleDragStart(componentID: componentID, startLocation: value.startLocation, currentLocation: value.location)
                    }
                }
                
                // 如果已經在拖曳元件...
                if gestureState.isDragging {
                    handleComponentDragging(currentLocation: value.location)
                    return // 避免同時執行平移
                }
                
                // 執行畫面平移...
                if !gestureState.isPanning {
                    startPanning(startLocation: value.startLocation)
                }
                
                // 執行平移...
                updatePanOffset(translation: value.translation)
            }
            .onEnded { value in
                // 處理拖曳結束
                handleDragEnd(translation: value.translation)
            }
    }
    
    // MARK: - 縮放手勢
    func magnificationGesture() -> some Gesture {
        MagnificationGesture(minimumScaleDelta: 0.01)
            .onChanged { value in
                // 啟用縮放狀態
                gestureState.isZooming = true
                
                // 計算新的縮放值
                let newScale = gestureState.lastScale * value
                
                // 應用縮放，保持在合理範圍內
                withAnimation(.interactiveSpring(response: 0.2, dampingFraction: 0.8)) {
                    gestureState.scale = min(max(0.2, newScale), 5.0)
                }
                
                // 平滑切換到縮放模式
                switchToZoomMode()
                
                showFeedback("縮放模式", false)
            }
            .onEnded { _ in
                // 縮放結束，保存最終縮放值
                gestureState.lastScale = gestureState.scale
                gestureState.isZooming = false
                showFeedback("縮放: \(Int(gestureState.scale * 100))%", true)
                
                // 自動切換回原工具模式
                restorePreviousToolMode()
            }
    }
    
    // MARK: - 旋轉手勢
    func rotationGesture() -> some Gesture {
        RotationGesture()
            .onChanged { angle in
                // 僅在編輯模式且有元件被選中時啟用
                guard viewState.isEditMode && !layoutManager.selectedComponents.isEmpty else {
                    return
                }
                
                // 如果沒有開始旋轉，記錄起始狀態
                if !gestureState.isRotating {
                    startRotation(initialAngle: angle)
                }
                
                // 計算旋轉差值
                let rotationDelta = angle - gestureState.rotationStartAngle
                
                // 應用旋轉到所有選中的PAD
                for padID in layoutManager.selectedComponents.filter({ layoutManager.pads[$0] != nil }) {
                    applyRotation(to: padID, delta: rotationDelta)
                }
            }
            .onEnded { _ in
                // 旋轉結束
                if gestureState.isRotating {
                    gestureState.isRotating = false
                    gestureState.rotationStartAngle = .zero
                    gestureState.componentsStartRotations.removeAll()
                    
                    showFeedback("旋轉完成", true)
                    
                    // 記錄操作歷史
                    layoutManager.recordHistory()
                }
            }
    }
    
    // MARK: - 拖曳處理函數
    private func handleDragStart(componentID: UUID, startLocation: CGPoint, currentLocation: CGPoint) {
        gestureState.isDragging = true
        gestureState.draggedComponentID = componentID
        gestureState.dragStartLocation = startLocation
        gestureState.dragCurrentLocation = currentLocation
        
        // 使用拖曳預覽
        if dragPreviewManager.previewEnabled {
            startDragPreview(componentID: componentID, startLocation: startLocation, currentLocation: currentLocation)
        } else {
            // 保存元件初始位置邏輯...
            if let pad = layoutManager.pads[componentID] {
                gestureState.dragStartComponentPosition = CGPoint(
                    x: CGFloat(pad.centerLocateX),
                    y: CGFloat(pad.centerLocateY)
                )
            }
            
            // 處理批量拖曳邏輯...
            if (gestureState.gestureModifiers.contains(.shift) ||
                isMultiSelectMode ||
                layoutManager.selectedComponents.count > 1) &&
                layoutManager.selectedComponents.contains(componentID) {
                
                saveBatchDragStartPositions()
            } else {
                // 單個元件拖曳，先選中
                if !layoutManager.selectedComponents.contains(componentID) {
                    layoutManager.clearSelection()
                    layoutManager.selectComponent(id: componentID)
                }
            }
        }
        
        // 平滑切換到選擇模式
        switchToSelectionMode()
        
        showFeedback("拖曳元件", false)
    }
    
    private func saveBatchDragStartPositions() {
        // 保存所有選中元件的初始位置
        for id in layoutManager.selectedComponents {
            if let pad = layoutManager.pads[id] {
                gestureState.componentsStartPositions[id] = CGPoint(
                    x: CGFloat(pad.centerLocateX),
                    y: CGFloat(pad.centerLocateY)
                )
            }
        }
    }
    
    private func handleComponentDragging(currentLocation: CGPoint) {
        gestureState.dragCurrentLocation = currentLocation
        
        // 根據是否啟用預覽模式決定行為
        if dragPreviewManager.previewEnabled {
            // 更新拖曳預覽
            updateDragPreview(currentLocation: currentLocation)
        } else {
            // 批量拖曳所有選中的元件
            if layoutManager.selectedComponents.count > 1 {
                updateBatchComponentPositions()
            }
            // 或者移動單個元件
            else if let componentID = gestureState.draggedComponentID {
                updateSingleComponentPosition(componentID: componentID)
            }
        }
    }
    
    private func updateBatchComponentPositions() {
        if let startLocation = gestureState.dragStartLocation {
            let currentLocation = gestureState.dragCurrentLocation ?? startLocation
            
            // 轉換座標系並計算移動差值...
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
    
    private func updateSingleComponentPosition(componentID: UUID) {
        if let startLocation = gestureState.dragStartLocation {
            let currentLocation = gestureState.dragCurrentLocation ?? startLocation
            
            // 轉換座標系並計算移動差值...
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
    
    private func startPanning(startLocation: CGPoint) {
        gestureState.isPanning = true
        gestureState.panStartLocation = startLocation
        
        // 平滑切換到平移模式
        switchToPanMode()
        
        showFeedback("平移模式", false)
    }
    
    private func updatePanOffset(translation: CGSize) {
        withAnimation(.interactiveSpring(response: 0.3, dampingFraction: 0.7)) {
            gestureState.offset = CGSize(
                width: gestureState.lastOffset.width + translation.width,
                height: gestureState.lastOffset.height + translation.height
            )
        }
    }
    
    private func handleDragEnd(translation: CGSize) {
        // 處理拖曳結束
        if gestureState.isPanning {
            // 平移結束，保存最終位置
            gestureState.lastOffset = gestureState.offset
            gestureState.isPanning = false
            gestureState.panStartLocation = nil
            
            // 提供反饋
            let distance = sqrt(pow(translation.width, 2) + pow(translation.height, 2))
            if distance > 5 {
                showFeedback("平移完成", true)
            }
        }
        
        if gestureState.isDragging {
            if dragPreviewManager.previewEnabled {
                // 使用預覽模式
                finalizeDragPreview()
            } else {
                // 使用直接移動模式
                finalizeDragging()
            }
        }
        
        // 自動切換回原工具模式
        restorePreviousToolMode()
    }
    
    private func finalizeDragging() {
        gestureState.isDragging = false
        gestureState.draggedComponentID = nil
        gestureState.dragStartLocation = nil
        gestureState.dragCurrentLocation = nil
        gestureState.dragStartComponentPosition = nil
        gestureState.componentsStartPositions.removeAll()
        
        showFeedback("移動元件完成", true)
        
        // 記錄操作歷史
        layoutManager.recordHistory()
    }
      
    // MARK: - 旋轉處理函數
    private func startRotation(initialAngle: Angle) {
        gestureState.isRotating = true
        gestureState.rotationStartAngle = initialAngle
        gestureState.componentsStartRotations.removeAll()
        
        // 記錄所有選中元件的初始旋轉角度
        for padID in layoutManager.selectedComponents.filter({ layoutManager.pads[$0] != nil }) {
            if let pad = layoutManager.pads[padID] {
                gestureState.componentsStartRotations[padID] = pad.rotatedAngle
            }
        }
        
        showFeedback("旋轉元件", false)
    }
    
    private func applyRotation(to padID: UUID, delta: Angle) {
        if let startRotation = gestureState.componentsStartRotations[padID],
           var pad = layoutManager.pads[padID] {
            // 計算新的旋轉角度 (轉換為度數)
            let newAngle = startRotation + Double(delta.degrees)
            
            // 更新PAD旋轉角度
            pad.rotatedAngle = newAngle
            layoutManager.updatePAD(pad)
        }
    }
    
    // MARK: - 工具模式切換函數
    
    /// 切換到選擇模式
    fileprivate func switchToSelectionMode() {
        withAnimation(.easeInOut(duration: 0.2)) {
            if viewState.selectedTool != ICLayoutViewState.LayoutTool.select {
                viewState.previousTool = viewState.selectedTool
                viewState.selectedTool = ICLayoutViewState.LayoutTool.select
            }
        }
    }
    
    /// 切換到平移模式
    fileprivate func switchToPanMode() {
        withAnimation(.easeInOut(duration: 0.2)) {
            if viewState.selectedTool != ICLayoutViewState.LayoutTool.pan {
                viewState.previousTool = viewState.selectedTool
                viewState.selectedTool = ICLayoutViewState.LayoutTool.pan
            }
        }
    }
    
    /// 切換到縮放模式
    fileprivate func switchToZoomMode() {
        withAnimation(.easeInOut(duration: 0.2)) {
            if viewState.selectedTool != ICLayoutViewState.LayoutTool.zoom {
                viewState.previousTool = viewState.selectedTool
                viewState.selectedTool = ICLayoutViewState.LayoutTool.zoom
            }
        }
    }
    
    /// 恢復之前的工具模式
    fileprivate func restorePreviousToolMode(delay: Double = 0.3) {
        guard let previousTool = viewState.previousTool else { return }
        
        // 根據 iOS 版本使用不同的異步方式
        if #available(iOS 15.0, *) {
            Task {
                try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                await MainActor.run {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        viewState.selectedTool = previousTool
                        viewState.previousTool = nil
                    }
                }
            }
        } else {
            // 舊版 iOS 的兼容方案
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                withAnimation(.easeInOut(duration: 0.3)) {
                    viewState.selectedTool = previousTool
                    viewState.previousTool = nil
                }
            }
        }
    }
}
