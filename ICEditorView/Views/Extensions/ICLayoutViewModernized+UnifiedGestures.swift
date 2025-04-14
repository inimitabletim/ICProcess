//
//  ICLayoutViewModernized+UnifiedGestures.swift
//  ICEditorView
//
//  Created by TimChi on 2025/4/14.
//

import SwiftUI
import Combine

extension ICLayoutViewModernized {
    
    /// 統一手勢系統 - 整合所有手勢處理邏輯
    func configureUnifiedGestures() -> some Gesture {
        // 1. 拖曳手勢 (專注於拖曳而非點擊)
        let dragGesture = DragGesture(minimumDistance: 5)
            .onChanged { value in
                // 更新游標位置
                gestureState.lastCursorX = value.location.x
                gestureState.lastCursorY = value.location.y
                
                // 如果已經在拖曳元件，繼續處理拖曳
                if gestureState.isDragging {
                    handleOngoingDrag(value)
                    return
                }
                
                // 如果已經在平移，繼續處理平移
                if gestureState.isPanning {
                    handleOngoingPan(value)
                    return
                }
                
                // 首次處理 - 檢查是否點擊到元件
                let componentID = hitTest(value.startLocation)
                
                if let componentID = componentID, viewState.isEditMode {
                    // 在編輯模式下點擊到元件，準備拖曳元件
                    startComponentDrag(
                        componentID: componentID,
                        startLocation: value.startLocation,
                        currentLocation: value.location
                    )
                } else {
                    // 點擊空白區域或非編輯模式下點擊元件，均準備平移視圖
                    startViewPan(startLocation: value.startLocation)
                }
            }
            .onEnded { value in
                // 完成拖曳或平移
                if gestureState.isDragging {
                    finalizeComponentDrag()
                } else if gestureState.isPanning {
                    finalizeViewPan()
                }
                
                // 重置狀態
                gestureState.draggedComponentID = nil
                gestureState.dragStartLocation = nil
                gestureState.dragCurrentLocation = nil
                gestureState.isDragging = false
                gestureState.isPanning = false
            }
        
        // 2. 縮放手勢
        let zoomGesture = MagnificationGesture(minimumScaleDelta: 0.01)
            .onChanged { value in
                self.handleScaleChange(value)
            }
            .onEnded { _ in
                gestureState.lastScale = gestureState.scale
                gestureState.isZooming = false
                self.showFeedback("縮放: \(Int(gestureState.scale * 100))%", true)
            }
        
        // 3. 旋轉手勢 (用於編輯模式下旋轉元件)
        let rotationGesture = RotationGesture()
            .onChanged { angle in
                // 僅在編輯模式且有選中元件時啟用
                guard viewState.isEditMode && !layoutManager.selectedComponents.isEmpty else {
                    return
                }
                
                if !gestureState.isRotating {
                    self.startComponentRotation(initialAngle: angle)
                }
                
                // 計算旋轉變化
                let rotationDelta = angle - gestureState.rotationStartAngle
                
                // 應用旋轉到所有選中的PAD
                for padID in layoutManager.selectedComponents.filter({ layoutManager.pads[$0] != nil }) {
                    self.applyComponentRotation(to: padID, delta: rotationDelta)
                }
            }
            .onEnded { _ in
                if gestureState.isRotating {
                    self.finalizeRotation()
                }
            }
        
        // 組合所有手勢
        return dragGesture
            .simultaneously(with: zoomGesture)
            .simultaneously(with: rotationGesture)
    }
    
    // MARK: - 輔助方法
    
    /// 處理持續拖曳
    private func handleOngoingDrag(_ value: DragGesture.Value) {
        gestureState.dragCurrentLocation = value.location
        
        // 根據是否啟用拖曳預覽選擇不同實現
        if dragPreviewManager.previewEnabled {
            updateDragPreview(currentLocation: value.location)
        } else {
            // 批量拖曳所有選中的元件
            if let componentID = gestureState.draggedComponentID,
               layoutManager.selectedComponents.contains(componentID) &&
               layoutManager.selectedComponents.count > 1 {
                updateBatchComponentPositions()
            } else {
                // 移動單個元件
                if let componentID = gestureState.draggedComponentID {
                    updateSingleComponentPosition(componentID: componentID)
                }
            }
        }
    }
    
    /// 處理持續平移
    private func handleOngoingPan(_ value: DragGesture.Value) {
        // 更新視圖的平移位置
        withAnimation(.interactiveSpring(response: 0.2, dampingFraction: 0.8)) {
            gestureState.offset = CGSize(
                width: gestureState.lastOffset.width + value.translation.width,
                height: gestureState.lastOffset.height + value.translation.height
            )
        }
    }
    
    /// 處理縮放變化
    private func handleScaleChange(_ value: MagnificationGesture.Value) {
        // 設置縮放狀態
        gestureState.isZooming = true
        
        // 計算新的縮放值
        let newScale = gestureState.lastScale * value
        
        // 應用縮放，保持在合理範圍內
        withAnimation(.interactiveSpring(response: 0.15, dampingFraction: 0.85)) {
            gestureState.scale = min(max(gestureState.minScale, newScale), gestureState.maxScale)
        }
        
        // 縮放超過閾值時提供輕微觸覺反饋
        if abs(gestureState.scale - gestureState.lastScale) > 0.05 {
            performHapticFeedback(intensity: 0.15)
        }
    }
}
