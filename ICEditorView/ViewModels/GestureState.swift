//
//  GestureKit.swift
//  ICEditorView
//
//  Created for AIP ESD Team 2025/3/28
//

import SwiftUI
import Combine

/// 手勢狀態追蹤器 - 管理所有手勢相關狀態
public class GestureState: ObservableObject {
    // 手勢基本狀態
    @Published var isPanning: Bool = false
    @Published var isZooming: Bool = false
    @Published var isRotating: Bool = false
    @Published var isDragging: Bool = false
    
    // 縮放狀態
    @Published var scale: CGFloat = 1.0
    @Published var lastScale: CGFloat = 1.0
    @Published var minScale: CGFloat = 0.1
    @Published var maxScale: CGFloat = 5.0
    
    // 拖動相關
    @Published var dragStartLocation: CGPoint?
    @Published var dragCurrentLocation: CGPoint?
    @Published var dragStartComponentPosition: CGPoint?
    @Published var componentsStartPositions: [UUID: CGPoint] = [:]
    
    // 平移狀態
    @Published var offset: CGSize = .zero
    @Published var lastOffset: CGSize = .zero
    @Published var panStartLocation: CGPoint?
    
    // 旋轉狀態
    @Published var rotation: Angle = .zero
    @Published var lastRotation: Angle = .zero
    @Published var rotationStartAngle: Angle = .zero
    @Published var componentsStartRotations: [UUID: Double] = [:]
    
    // 點擊信息
    @Published var lastCursorX: CGFloat = 0
    @Published var lastCursorY: CGFloat = 0
    
    // 手勢額外數據
    @Published var gestureModifiers: GestureModifiers = []
    
    // 調試信息
    @Published var debugInfo: String = ""
    
    var draggedComponentID: UUID? = nil
    var isHovering: Bool = false
    
    // 初始化方法
    public init(initialScale: CGFloat = 1.0) {
        self.scale = initialScale
        self.lastScale = initialScale
    }
    
    /// 重置手勢狀態
    public func resetGestureState() {
        isPanning = false
        isZooming = false
        isRotating = false
        isDragging = false
        gestureModifiers = []
        lastCursorX = 0
        lastCursorY = 0
        draggedComponentID = nil
        dragStartLocation = nil
        dragCurrentLocation = nil
        dragStartComponentPosition = nil
        componentsStartPositions.removeAll()
        panStartLocation = nil
        isRotating = false
        rotationStartAngle = .zero
        componentsStartRotations.removeAll()
    }
    
    /// 重置視圖狀態但保留比例
    public func resetViewState() {
        offset = .zero
        lastOffset = .zero
        rotation = .zero
        lastRotation = .zero
    }
    
    /// 完全重置視圖
    public func resetView() {
        resetViewState()
        scale = 1.0
        lastScale = 1.0
    }
}

// MARK: - 調試工具

/// 手勢診斷視圖
struct GestureDiagnosticsView: View {
    @ObservedObject var gestureState: GestureState
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("手勢診斷")
                .font(.headline)
                .padding(.bottom, 4)
            
            VStack(alignment: .leading, spacing: 4) {
                GestureStatusRow(name: "拖動", status: gestureState.isDragging ? "✓" : "✕")
                GestureStatusRow(name: "縮放", status: gestureState.isZooming ? "✓" : "✕")
                GestureStatusRow(name: "平移", status: gestureState.isPanning ? "✓" : "✕")
                GestureStatusRow(name: "多指", status: gestureState.gestureModifiers.contains(.multiTouch) ? "✓" : "✕")
                
                Divider()
                
                Text("當前比例: \(String(format: "%.2f", gestureState.scale))")
                    .font(.system(size: 12))
                
                Text("偏移: X: \(Int(gestureState.offset.width)), Y: \(Int(gestureState.offset.height))")
                    .font(.system(size: 12))
                
                if gestureState.isDragging, let position = gestureState.dragCurrentLocation {
                    Text("拖動中: X: \(Int(position.x)), Y: \(Int(position.y))")
                        .font(.system(size: 12))
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(UIColor.secondarySystemBackground))
                .shadow(color: Color.black.opacity(0.2), radius: 8, x: 0, y: 4)
        )
        .frame(width: 200)
    }
}

/// 手勢狀態行
struct GestureStatusRow: View {
    let name: String
    let status: String
    
    var body: some View {
        HStack {
            Text(name)
                .font(.system(size: 12))
                .frame(width: 50, alignment: .leading)
            
            Circle()
                .fill(status == "✓" ? Color.green : Color.red)
                .frame(width: 8, height: 8)
            
            Text(status == "✓" ? "是" : "否")
                .font(.system(size: 12))
        }
    }
}
