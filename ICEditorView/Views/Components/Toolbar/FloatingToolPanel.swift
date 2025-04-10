//
//  FloatingToolPanel.swift
//  ICEditorView
//
//  Created by TimChi on 2025/4/8.
//

import SwiftUI

/// 增強型懸浮工具面板 - 為觸控操作優化
struct FloatingToolPanel: View {
    @Binding var position: CGPoint
    @Binding var isExpanded: Bool
    @State private var dragOffset: CGSize = .zero
    @State private var opacity: Double = 0.8
    
    let onAction: (ToolAction) -> Void
    var parentGeometryProxy: GeometryProxy? // 新增
    
    // 📝 新增一個閉包型別的參數，用於接收約束函數
    var constrainPosition: ((CGPoint, GeometryProxy) -> CGPoint)?
    
    // 定義工具操作
    enum ToolAction {
        case zoomIn
        case zoomOut
        case resetView
        case toggleGrid
        case toggleLabels
        case toggleConnections
        case showSettings
        case centerSelection
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // 展開的詳細面板
            if isExpanded {
                expandedPanel
            } else {
                collapsedPanel
            }
            
            // 展開/收合按鈕
            Button(action: {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    isExpanded.toggle()
                }
            }) {
                Image(systemName: isExpanded ? "chevron.compact.down" : "chevron.compact.up")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(.primary)
                    .frame(width: 44, height: 36)
                    .background(Color.primary.opacity(0.05))
                    .clipShape(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                    )
            }
            .padding(.vertical, 4)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color(UIColor.systemBackground).opacity(opacity))
                .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 5)
        )
        .position(position)
        .gesture(
            DragGesture(minimumDistance: 10)
                .onChanged { value in
                    let newPosition = CGPoint(
                        x: position.x + value.translation.width - dragOffset.width,
                        y: position.y + value.translation.height - dragOffset.height
                    )
                    // 使用 constrainPanelPosition 限制位置
                    // ✅ 使用傳入的約束函數
                    if let constrain = constrainPosition, let geometry = parentGeometryProxy {
                        position = constrain(newPosition, geometry)
                    } else {
                        position = newPosition
                    }
                    
                    dragOffset = value.translation
                    
                    // 拖曳時提高不透明度
                    opacity = 0.95
                }
                .onEnded { _ in
                    dragOffset = .zero
                    
                    // 拖曳結束後恢復原本的不透明度
                    withAnimation(.easeOut(duration: 0.3)) {
                        opacity = 0.8
                    }
                }
        )
        .onTapGesture {
            // 點擊時提高不透明度
            withAnimation(.easeOut(duration: 0.3)) {
                opacity = 0.95
            }
            
            // 短暫後降低不透明度
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                withAnimation(.easeOut(duration: 0.3)) {
                    opacity = 0.8
                }
            }
        }
    }
        
    // 收合狀態的簡化面板
    private var collapsedPanel: some View {
        HStack(spacing: 12) {
            // 縮放按鈕
            Button(action: { onAction(.zoomIn) }) {
                Image(systemName: "plus.magnifyingglass")
                    .floatingButtonStyle()
            }
            
            Button(action: { onAction(.zoomOut) }) {
                Image(systemName: "minus.magnifyingglass")
                    .floatingButtonStyle()
            }
            
            // 分隔線
            Rectangle()
                .fill(Color.gray.opacity(0.3))
                .frame(width: 1, height: 28)
            
            // 重置視圖按鈕
            Button(action: { onAction(.resetView) }) {
                Image(systemName: "arrow.counterclockwise")
                    .floatingButtonStyle()
            }
            
            // 設定按鈕
            Button(action: { onAction(.showSettings) }) {
                Image(systemName: "slider.horizontal.3")
                    .floatingButtonStyle()
            }
        }
    }
    
    // 展開狀態的詳細面板
    private var expandedPanel: some View {
        VStack(spacing: 12) {
            // 縮放控制區
            HStack(spacing: 12) {
                Button(action: { onAction(.zoomIn) }) {
                    Image(systemName: "plus.magnifyingglass")
                        .floatingButtonStyle()
                }
                
                Button(action: { onAction(.zoomOut) }) {
                    Image(systemName: "minus.magnifyingglass")
                        .floatingButtonStyle()
                }
                
                Button(action: { onAction(.resetView) }) {
                    Image(systemName: "arrow.counterclockwise")
                        .floatingButtonStyle()
                }
            }
            
            Divider()
                .padding(.horizontal, 8)
            
            // 顯示選項控制區
            HStack(spacing: 12) {
                Button(action: { onAction(.toggleGrid) }) {
                    Image(systemName: "grid")
                        .floatingButtonStyle()
                }
                
                Button(action: { onAction(.toggleLabels) }) {
                    Image(systemName: "tag")
                        .floatingButtonStyle()
                }
                
                Button(action: { onAction(.toggleConnections) }) {
                    Image(systemName: "link")
                        .floatingButtonStyle()
                }
            }
            
            Divider()
                .padding(.horizontal, 8)
            
            // 特殊操作區
            HStack(spacing: 12) {
                Button(action: { onAction(.centerSelection) }) {
                    Image(systemName: "target")
                        .floatingButtonStyle()
                }
                
                Button(action: { onAction(.showSettings) }) {
                    Image(systemName: "gearshape")
                        .floatingButtonStyle()
                }
            }
        }
    }
}

// 懸浮按鈕樣式擴展
extension Image {
    func floatingButtonStyle() -> some View {
        self.font(.system(size: 20))
            .frame(width: 44, height: 44)
            .foregroundColor(.primary)
            .background(Color.primary.opacity(0.05))
            .clipShape(Circle())
    }
}
