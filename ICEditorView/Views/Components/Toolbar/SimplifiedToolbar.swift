//
//  SimplifiedToolbar.swift
//  ICEditorView
//
//  Created by TimChi on 2025/4/9.
//

import SwiftUI

/// 簡化的觸控友善工具列
struct SimplifiedToolbar: View {
    @Binding var selectedTool: ICLayoutViewState.LayoutTool
    @Binding var isEditMode: Bool
    @Binding var showExtendedTools: Bool
    let onAction: (ToolbarAction) -> Void
    
    // 定義工具列動作
    enum ToolbarAction {
        case toggleEditMode
        case selectTool
        case panTool
        case zoomTool
        case showFileMenu
        case showEditMenu
        case showViewOptions
        case toggleExtendedTools
        case showAssociationManager
    }
    
    var body: some View {
        HStack(spacing: 8) {
            // 左側：基本工具
            HStack(spacing: 16) {
                // 檔案選單按鈕
                BigToolbarButton(
                    icon: "doc",
                    label: "檔案",
                    action: { onAction(.showFileMenu) }
                )
                
                // 分隔線
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 1, height: 36)
                
                // 主要工具模式
                BigToolbarButton(
                    icon: "hand.point.up.fill",
                    label: "選擇",
                    isActive: selectedTool == .select,
                    action: { onAction(.selectTool) }
                )
                
                BigToolbarButton(
                    icon: "hand.draw.fill",
                    label: "平移",
                    isActive: selectedTool == .pan,
                    action: { onAction(.panTool) }
                )
                
                BigToolbarButton(
                    icon: "magnifyingglass",
                    label: "縮放",
                    isActive: selectedTool == .zoom,
                    action: { onAction(.zoomTool) }
                )
                
                // 分隔線
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 1, height: 36)
                
                // 編輯模式切換
                BigToolbarButton(
                    icon: isEditMode ? "pencil.circle.fill" : "pencil.circle",
                    label: isEditMode ? "編輯中" : "編輯",
                    isActive: isEditMode,
                    action: { onAction(.toggleEditMode) }
                )
            }
            .padding(.horizontal, 8)
            
            Spacer()
            
            // 右側：更多選項
            HStack(spacing: 16) {
                // 視圖選項按鈕
                BigToolbarButton(
                    icon: "eye",
                    label: "顯示選項",
                    action: { onAction(.showViewOptions) }
                )
                
                // 關聯管理按鈕
                BigToolbarButton(
                    icon: "link.circle",
                    label: "關聯",
                    action: { onAction(.showAssociationManager) }
                )
                
                // 展開/收合工具按鈕
                BigToolbarButton(
                    icon: showExtendedTools ? "chevron.compact.up" : "chevron.compact.down",
                    label: showExtendedTools ? "收合" : "更多",
                    action: { onAction(.toggleExtendedTools) }
                )
            }
            .padding(.horizontal, 8)
        }
        .frame(height: 70)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(UIColor.secondarySystemBackground).opacity(0.95))
                .shadow(color: Color.black.opacity(0.15), radius: 5)
        )
        .padding([.horizontal, .top], 8)
    }
}

/// 大型觸控友善工具按鈕
struct BigToolbarButton: View {
    let icon: String
    let label: String
    var isActive: Bool = false
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 24, weight: isActive ? .semibold : .regular))
                    .foregroundColor(isActive ? .accentColor : .primary)
                
                Text(label)
                    .font(.system(size: 12, weight: isActive ? .medium : .regular))
                    .foregroundColor(isActive ? .accentColor : .secondary)
            }
            .frame(width: 60, height: 56)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(isActive ? Color.accentColor.opacity(0.15) : Color.clear)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(isActive ? Color.accentColor.opacity(0.3) : Color.clear, lineWidth: 1.5)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

/// 檔案選單視圖
struct FileMenuView: View {
    let onAction: (FileAction) -> Void
    
    enum FileAction {
        case importCSV
        case exportCSV
        case saveLayout
        case loadLayout
        case dismiss
    }
    
    var body: some View {
        VStack(spacing: 0) {
            Text("檔案操作")
                .font(.headline)
                .padding(.top, 12)
                .padding(.bottom, 8)
            
            Divider()
            
            // 選單項目
            MenuItemButton(icon: "square.and.arrow.down", title: "匯入 CSV") {
                onAction(.importCSV)
            }
            
            Divider().padding(.horizontal)
            
            MenuItemButton(icon: "square.and.arrow.up", title: "匯出 CSV") {
                onAction(.exportCSV)
            }
            
            Divider().padding(.horizontal)
            
            MenuItemButton(icon: "arrow.down.doc.fill", title: "儲存佈局") {
                onAction(.saveLayout)
            }
            
            Divider().padding(.horizontal)
            
            MenuItemButton(icon: "arrow.up.doc.fill", title: "載入佈局") {
                onAction(.loadLayout)
            }
            
            Divider()
            
            // 關閉按鈕
            Button(action: { onAction(.dismiss) }) {
                Text("關閉")
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .foregroundColor(.primary)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(UIColor.systemBackground))
                .shadow(color: Color.black.opacity(0.2), radius: 10)
        )
        .frame(width: 250)
    }
}

/// 選單項目按鈕
struct MenuItemButton: View {
    let icon: String
    let title: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(.accentColor)
                    .frame(width: 24)
                
                Text(title)
                    .font(.system(size: 17))
                    .foregroundColor(.primary)
                
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
}
