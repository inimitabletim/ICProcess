//
//  ICLayoutViewModernized+Gestures.swift
//  ICEditorView
//
//  Created by TimChi on 2025/4/8.
//  Optimized with new gesture handling system

import SwiftUI
import Combine

// MARK: - 主要手勢擴展
extension ICLayoutViewModernized {
    // MARK: - 手勢配置策略
    /// 依據當前工具模式和狀態，配置適當的手勢組合
    func configureGestures() -> some Gesture {
        // 使用統一手勢方案解決編譯問題
        return makeUnifiedGesture()
    }
    
    /// 建立統一型別的手勢組合
    private func makeUnifiedGesture() -> some Gesture {
        // 組合所有需要的手勢，但根據當前模式決定哪些手勢生效
        
        // 1. 拖曳手勢 - 處理選擇、拖曳元件和平移視圖
        let dragGesture = DragGesture(minimumDistance: 2)
            .onChanged { value in
                // 獲取當前滑鼠/觸控位置
                updateCursorPosition(value.location)
                
                // 根據當前工具模式決定處理邏輯
                switch self.viewState.selectedTool {
                case .select:
                    self.handleSelectionDrag(value)
                case .pan:
                    self.handlePanDrag(value)
                case .zoom:
                    // 在縮放模式下，拖曳也可以用於平移視圖
                    if !self.gestureState.isDragging {
                        self.startViewPan(startLocation: value.startLocation)
                    }
                    self.updateViewPan(translation: value.translation)
                case .browse:
                    self.handlePanDrag(value)
                default:
                    self.handleEditModeDrag(value)
                }
            }
            .onEnded { value in
                // 根據當前工具模式決定結束處理邏輯
                switch self.viewState.selectedTool {
                case .select:
                    self.handleSelectionDragEnd(value)
                case .pan:
                    self.finalizePanDrag(value)
                case .zoom:
                    self.finalizePanDrag(value)
                case .browse:
                    self.finalizePanDrag(value)
                default:
                    self.handleEditModeDragEnd(value)
                }
            }
        
        // 2. 縮放手勢 - 處理畫面縮放
        let magnificationGesture = MagnificationGesture(minimumScaleDelta: 0.01)
            .onChanged { value in
                // 根據當前工具模式決定縮放處理邏輯
                switch self.viewState.selectedTool {
                case .zoom:
                    // 在縮放模式下，縮放是主要功能
                    self.handleScaleChange(value, restrictRange: true)
                case .select:
                    // 在選擇模式下，只有未拖曳元件時才處理縮放
                    if !self.gestureState.isDragging && !self.gestureState.isPanning {
                        self.handleScaleChange(value, restrictRange: true)
                    }
                case .browse:
                    // 在瀏覽模式下總是啟用縮放
                    self.handleScaleChange(value, restrictRange: true)
                default:
                    // 在其他模式下，只有未拖曳元件時才處理縮放
                    if !self.gestureState.isDragging {
                        self.handleScaleChange(value, restrictRange: true)
                    }
                }
            }
            .onEnded { _ in
                if self.gestureState.isZooming {
                    self.gestureState.lastScale = self.gestureState.scale
                    self.gestureState.isZooming = false
                    self.showFeedback("縮放: \(Int(self.gestureState.scale * 100))%", true)
                }
            }
        
        // 3. 旋轉手勢 - 處理元件旋轉
        let rotationGesture = RotationGesture()
            .onChanged { angle in
                // 只有在編輯模式且有選中元件時才處理旋轉
                if (self.viewState.isEditMode || self.viewState.selectedTool == .select) &&
                   !self.layoutManager.selectedComponents.isEmpty {
                    self.handleRotation(angle)
                }
            }
            .onEnded { _ in
                self.finalizeRotation()
            }
        
        // 組合所有手勢
        return dragGesture
            .simultaneously(with:
                magnificationGesture.simultaneously(with: rotationGesture)
            )
    }
    
    // MARK: - 簡化手勢處理函數
    
    /// 處理選擇模式下的拖曳
    private func handleSelectionDrag(_ value: DragGesture.Value) {
        // 檢查是否應該拖曳元件
        if !gestureState.isDragging && !gestureState.isPanning {
            // 先檢查是否點擊到元件
            if let componentID = hitTest(value.startLocation) {
                // 開始拖曳元件
                startComponentDrag(
                    componentID: componentID,
                    startLocation: value.startLocation,
                    currentLocation: value.location
                )
                return
            }
        }
        
        // 如果已經在拖曳元件
        if gestureState.isDragging {
            updateComponentDrag(currentLocation: value.location)
            // 提供即時反饋
            performHapticFeedback(intensity: 0.2)
            return
        }
        
        // 如果不是拖曳元件，則平移視圖
        if !gestureState.isPanning {
            startViewPan(startLocation: value.startLocation)
        }
        
        updateViewPan(translation: value.translation)
    }
    
    /// 處理選擇模式下的拖曳結束
    private func handleSelectionDragEnd(_ value: DragGesture.Value) {
        if gestureState.isPanning {
            finalizeViewPan()
            
            // 如果平移距離很小，可能是點擊事件
            let distance = sqrt(pow(value.translation.width, 2) + pow(value.translation.height, 2))
            if distance < 5 {
                // 處理點擊事件
                handleTapAtLocation(value.location)
            }
        }
        
        if gestureState.isDragging {
            finalizeComponentDrag()
        }
    }
    
    /// 處理平移模式下的拖曳
    private func handlePanDrag(_ value: DragGesture.Value) {
        // 在平移模式下，總是平移視圖，不考慮元件拖曳
        if !gestureState.isPanning {
            startViewPan(startLocation: value.startLocation)
        }
        
        updateViewPan(translation: value.translation)
    }
    
    /// 完成平移操作
    private func finalizePanDrag(_ value: DragGesture.Value) {
        if gestureState.isPanning {
            finalizeViewPan()
            
            // 提供觸覺反饋
            let distance = sqrt(pow(value.translation.width, 2) + pow(value.translation.height, 2))
            if distance > 5 {
                performHapticFeedback(intensity: 0.3)
                showFeedback("平移完成", true)
            }
        }
    }
    
    /// 處理編輯模式下的拖曳
    private func handleEditModeDrag(_ value: DragGesture.Value) {
        // 在編輯模式下，優先考慮元件拖曳
        if viewState.isEditMode && !gestureState.isDragging && !gestureState.isPanning {
            if let componentID = hitTest(value.startLocation) {
                startComponentDrag(
                    componentID: componentID,
                    startLocation: value.startLocation,
                    currentLocation: value.location
                )
                return
            }
        }
        
        // 如果已經在拖曳元件
        if gestureState.isDragging {
            updateComponentDrag(currentLocation: value.location)
            return
        }
        
        // 如果不是拖曳元件，則平移視圖
        if !gestureState.isPanning {
            startViewPan(startLocation: value.startLocation)
        }
        
        updateViewPan(translation: value.translation)
    }
    
    /// 處理編輯模式下的拖曳結束
    private func handleEditModeDragEnd(_ value: DragGesture.Value) {
        if gestureState.isPanning {
            finalizeViewPan()
        }
        
        if gestureState.isDragging {
            finalizeComponentDrag()
        }
    }
    
    /// 處理縮放變化
    private func handleScaleChange(_ value: MagnificationGesture.Value, restrictRange: Bool = true) {
        // 啟用縮放狀態
        gestureState.isZooming = true
        
        // 計算新的縮放值
        let newScale = gestureState.lastScale * value
        
        // 應用縮放，保持在合理範圍內
        withAnimation(.interactiveSpring(response: 0.15, dampingFraction: 0.85)) {
            if restrictRange {
                gestureState.scale = min(max(gestureState.minScale, newScale), gestureState.maxScale)
            } else {
                gestureState.scale = newScale
            }
        }
        
        // 縮放超過閾值時提供輕微觸覺反饋
        if abs(gestureState.scale - gestureState.lastScale) > 0.05 {
            performHapticFeedback(intensity: 0.15)
        }
    }
    
    /// 處理旋轉操作
    private func handleRotation(_ angle: Angle) {
        // 僅在編輯模式且有元件被選中時啟用
        guard viewState.isEditMode && !layoutManager.selectedComponents.isEmpty else {
            return
        }
        
        // 如果沒有開始旋轉，記錄起始狀態
        if !gestureState.isRotating {
            startComponentRotation(initialAngle: angle)
        }
        
        // 計算旋轉差值
        let rotationDelta = angle - gestureState.rotationStartAngle
        
        // 應用旋轉到所有選中的PAD
        for padID in layoutManager.selectedComponents.filter({ layoutManager.pads[$0] != nil }) {
            applyComponentRotation(to: padID, delta: rotationDelta)
        }
        
        // 提供輕微觸覺反饋
        if abs(rotationDelta.degrees) > 1.0 {
            performHapticFeedback(intensity: 0.15)
        }
    }
    
    /// 處理點擊事件
    private func handleTapAtLocation(_ location: CGPoint) {
        // 檢查是否點擊到元件
        if let componentID = hitTest(location) {
            handleComponentTap(componentID)
        } else {
            // 點擊空白區域，可能是清除選擇
            if !gestureState.gestureModifiers.contains(.shift) {
                layoutManager.clearSelection()
            }
        }
    }
    
    // MARK: - 基本手勢處理輔助函數
    
    /// 更新游標位置
    private func updateCursorPosition(_ location: CGPoint) {
        gestureState.lastCursorX = location.x
        gestureState.lastCursorY = location.y
    }
    
    /// 啟動元件拖曳
    private func startComponentDrag(componentID: UUID, startLocation: CGPoint, currentLocation: CGPoint) {
        gestureState.isDragging = true
        gestureState.draggedComponentID = componentID
        gestureState.dragStartLocation = startLocation
        gestureState.dragCurrentLocation = currentLocation
        
        // 使用拖曳預覽
        if dragPreviewManager.previewEnabled {
            startDragPreview(componentID: componentID, startLocation: startLocation, currentLocation: currentLocation)
        } else {
            // 保存元件初始位置
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
                
                // 保存所有選中元件的初始位置
                for id in layoutManager.selectedComponents {
                    if let pad = layoutManager.pads[id] {
                        gestureState.componentsStartPositions[id] = CGPoint(
                            x: CGFloat(pad.centerLocateX),
                            y: CGFloat(pad.centerLocateY)
                        )
                    }
                }
            } else {
                // 單個元件拖曳，先選中
                if !layoutManager.selectedComponents.contains(componentID) {
                    layoutManager.clearSelection()
                    layoutManager.selectComponent(id: componentID)
                }
            }
        }
        
        // 提供觸覺反饋
        performHapticFeedback(intensity: 0.3)
        showFeedback("拖曳元件", false)
    }
    
    /// 更新元件拖曳位置
    private func updateComponentDrag(currentLocation: CGPoint) {
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
    
    /// 完成元件拖曳
    private func finalizeComponentDrag() {
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
    
    /// 啟動視圖平移
    private func startViewPan(startLocation: CGPoint) {
        gestureState.isPanning = true
        gestureState.panStartLocation = startLocation
        
        // 提供輕微觸覺反饋
        performHapticFeedback(intensity: 0.2)
    }
    
    /// 更新視圖平移
    private func updateViewPan(translation: CGSize) {
        withAnimation(.interactiveSpring(response: 0.2, dampingFraction: 0.8)) {
            gestureState.offset = CGSize(
                width: gestureState.lastOffset.width + translation.width,
                height: gestureState.lastOffset.height + translation.height
            )
        }
    }
    
    /// 完成視圖平移
    private func finalizeViewPan() {
        gestureState.lastOffset = gestureState.offset
        gestureState.isPanning = false
        gestureState.panStartLocation = nil
    }
    
    /// 啟動元件旋轉
    private func startComponentRotation(initialAngle: Angle) {
        gestureState.isRotating = true
        gestureState.rotationStartAngle = initialAngle
        gestureState.componentsStartRotations.removeAll()
        
        // 記錄所有選中元件的初始旋轉角度
        for padID in layoutManager.selectedComponents.filter({ layoutManager.pads[$0] != nil }) {
            if let pad = layoutManager.pads[padID] {
                gestureState.componentsStartRotations[padID] = pad.rotatedAngle
            }
        }
        
        // 提供觸覺反饋
        performHapticFeedback(intensity: 0.3)
        showFeedback("旋轉元件", false)
    }
    
    /// 應用元件旋轉
    private func applyComponentRotation(to padID: UUID, delta: Angle) {
        if let startRotation = gestureState.componentsStartRotations[padID],
           var pad = layoutManager.pads[padID] {
            // 計算新的旋轉角度 (轉換為度數)
            let newAngle = startRotation + Double(delta.degrees)
            
            // 更新PAD旋轉角度
            pad.rotatedAngle = newAngle
            layoutManager.updatePAD(pad)
        }
    }
    
    /// 完成旋轉操作
    private func finalizeRotation() {
        if gestureState.isRotating {
            gestureState.isRotating = false
            gestureState.rotationStartAngle = .zero
            gestureState.componentsStartRotations.removeAll()
            
            // 提供觸覺反饋
            performHapticFeedback(intensity: 0.4)
            showFeedback("旋轉完成", true)
            
            // 記錄操作歷史
            layoutManager.recordHistory()
        }
    }
    
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
    
    /// 提供觸覺反饋
    private func performHapticFeedback(intensity: CGFloat) {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred(intensity: intensity)
    }
}
