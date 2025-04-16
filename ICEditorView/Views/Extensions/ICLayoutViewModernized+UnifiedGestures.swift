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
        // 輔助手勢：更新觸控位置供 TapGesture 使用
        let positionTrackingGesture = DragGesture(minimumDistance: 0)
            .onChanged { value in
                gestureState.lastCursorX = value.location.x
                gestureState.lastCursorY = value.location.y
            }
            .onEnded { _ in }

        // Tap 手勢：純點擊（利用先前儲存的觸控位置）
        let tapGesture = TapGesture()
            .onEnded {
                let tapPoint = CGPoint(x: gestureState.lastCursorX, y: gestureState.lastCursorY)
                if let componentID = self.hitTest(tapPoint) {
                    self.handleComponentTap(componentID)
                } else {
                    self.layoutManager.clearSelection()
                    self.showingComponentDetails = false
                    self.selectedComponentID = nil
                    self.showFeedback("清除選擇", false)
                }
            }
        
        // 拖曳手勢：處理拖曳／平移邏輯，minimumDistance 設為 2 以避免輕點誤判
        let dragGesture = DragGesture(minimumDistance: 2)
            .onChanged { value in
                gestureState.lastCursorX = value.location.x
                gestureState.lastCursorY = value.location.y
                
                if gestureState.isDragging {
                    self.handleOngoingDrag(value)
                    return
                }
                if gestureState.isPanning {
                    self.handleOngoingPan(value)
                    return
                }
                
                let componentID = self.hitTest(value.startLocation)
                if let componentID = componentID {
                    if self.viewState.isEditMode {
                        self.startComponentDrag(
                            componentID: componentID,
                            startLocation: value.startLocation,
                            currentLocation: value.location
                        )
                    } else {
                        self.handleComponentTap(componentID)
                        self.startViewPan(startLocation: value.startLocation)
                    }
                } else {
                    self.startViewPan(startLocation: value.startLocation)
                }
            }
            .onEnded { value in
                let dragDistance = sqrt(
                    pow(value.translation.width, 2) +
                    pow(value.translation.height, 2)
                )
                
                if gestureState.isDragging {
                    self.finalizeComponentDrag()
                } else if gestureState.isPanning {
                    self.finalizeViewPan()
                    if dragDistance < 3 && self.hitTest(value.startLocation) == nil {
                        self.layoutManager.clearSelection()
                        self.showingComponentDetails = false
                        self.selectedComponentID = nil
                        self.showFeedback("清除選擇", false)
                    }
                }
                
                gestureState.draggedComponentID = nil
                gestureState.dragStartLocation = nil
                gestureState.dragCurrentLocation = nil
                gestureState.isDragging = false
                gestureState.isPanning = false
            }
        
        // 使用 ExclusiveGesture 將 tapGesture 優先於 dragGesture
        let exclusiveGesture = tapGesture.exclusively(before: dragGesture)
        
        // 將 exclusiveGesture 與位置追蹤手勢結合
        let primaryGesture = exclusiveGesture.simultaneously(with: positionTrackingGesture)
        
        // 縮放手勢
        let zoomGesture = MagnificationGesture(minimumScaleDelta: 0.01)
            .onChanged { value in
                self.handleScaleChange(value)
            }
            .onEnded { _ in
                gestureState.lastScale = gestureState.scale
                gestureState.isZooming = false
                self.showFeedback("縮放: \(Int(gestureState.scale * 100))%", true)
            }
        
        
        // 組合其他手勢：先處理 primaryGesture，然後同時結合縮放與旋轉
        return primaryGesture
            .simultaneously(with: zoomGesture)
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
