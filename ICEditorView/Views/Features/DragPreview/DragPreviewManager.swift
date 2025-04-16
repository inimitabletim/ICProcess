//
//  DragPreviewManager.swift
//  ICEditorView
//
//  Created by TimChi on 2025/4/9.
//

import SwiftUI
import Combine

class DragPreviewManager: ObservableObject {
    @Published var isDragging: Bool = false
    @Published var draggedComponentID: UUID? = nil
    @Published var originalPositions: [UUID: CGPoint] = [:]
    @Published var dragOffset: CGSize = .zero
    @Published var showConfirmationDialog: Bool = false
    @Published var dragCurrentPosition: CGPoint = .zero
    
    // 預覽模式是否啟用
    @Published var previewEnabled: Bool = true
    @Published var dragPreviewConfirmed: Bool = false
    
    // 座標變更發布者 (新增)
    let positionPublisher = PassthroughSubject<CGPoint, Never>()
    
    func startDragging(componentID: UUID, position: CGPoint) {
        isDragging = true
        draggedComponentID = componentID
        originalPositions[componentID] = position
        dragOffset = .zero
        dragPreviewConfirmed = false
    }
    
    func addComponentToDrag(componentID: UUID, position: CGPoint) {
        originalPositions[componentID] = position
    }
    
    func updateDragOffset(_ offset: CGSize) {
        dragOffset = offset
    }
    
    func updateCurrentPosition(_ position: CGPoint) {
        dragCurrentPosition = position
        // 發布座標變更事件
        positionPublisher.send(position)
    }
    
    func promptForConfirmation() {
        showConfirmationDialog = true
    }
    
    func cancelDrag() {
        reset()
    }
    
    func confirmDrag() {
        dragPreviewConfirmed = true
        showConfirmationDialog = false
    }
    
    func reset() {
        isDragging = false
        draggedComponentID = nil
        originalPositions.removeAll()
        dragOffset = .zero
        showConfirmationDialog = false
        dragPreviewConfirmed = false
    }
}
