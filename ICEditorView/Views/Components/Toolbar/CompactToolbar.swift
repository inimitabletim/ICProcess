//
//  CompactToolbar.swift
//  ICEditorView
//
//  Created by TimChi on 2025/4/8.
//

import SwiftUI

struct CompactToolbar: View {
    @Binding var selectedTool: ToolType
    @Binding var isEditMode: Bool
    @Binding var isMultiSelectMode: Bool
    let onAction: (ICLayoutViewModernized.ToolbarAction) -> Void
    
    var body: some View {
        HStack(spacing: 0) {
            // 檔案操作
            ToolbarGroup(title: "檔案") {
                ToolbarButton(icon: "square.and.arrow.down", label: "匯入") {
                    onAction(.importCSV)
                }
                
                ToolbarButton(icon: "square.and.arrow.up", label: "匯出") {
                    onAction(.exportCSV)
                }
            }
            
            Divider()
                .frame(height: 32)
                .padding(.horizontal, 8)
            
            // 編輯操作
            ToolbarGroup(title: "編輯") {
                ToolbarButton(icon: "arrow.uturn.backward", label: "復原") {
                    onAction(.undo)
                }
                
                ToolbarButton(icon: "arrow.uturn.forward", label: "重做") {
                    onAction(.redo)
                }
                
                ToolbarButton(
                    icon: isMultiSelectMode ? "checkmark.circle.fill" : "checkmark.circle",
                    label: isMultiSelectMode ? "多選中" : "多選",
                    isActive: isMultiSelectMode
                ) {
                    onAction(.toggleMultiSelect)
                }
            }
            
            Divider()
                .frame(height: 32)
                .padding(.horizontal, 8)
            
            // 視圖模式
            ToolbarGroup(title: "視圖") {
                ToolbarButton(
                    icon: isEditMode ? "pencil.circle.fill" : "pencil.circle",
                    label: isEditMode ? "編輯中" : "編輯",
                    isActive: isEditMode
                ) {
                    onAction(.toggleEditMode)
                }
                
                ToolbarButton(
                    icon: "hand.point.up.fill",
                    label: "選擇",
                    isActive: selectedTool == .select
                ) {
                    onAction(.selectTool)
                }
                
                ToolbarButton(
                    icon: "hand.draw.fill",
                    label: "平移",
                    isActive: selectedTool == .pan
                ) {
                    onAction(.panTool)
                }
                
                ToolbarButton(
                    icon: "plus.magnifyingglass",
                    label: "縮放",
                    isActive: selectedTool == .zoom
                ) {
                    onAction(.zoomTool)
                }
            }
            
            Divider()
                .frame(height: 32)
                .padding(.horizontal, 8)
            
            // 關聯管理
            ToolbarGroup(title: "關聯") {
                ToolbarButton(
                    icon: "link.circle",
                    label: "關聯管理"
                ) {
                    onAction(.showAssociationManager)
                }
            }
            
            Spacer()
            
            // 側欄切換按鈕
            Button(action: {
                onAction(.togglePanel)
            }) {
                Image(systemName: "sidebar.right")
                    .font(.system(size: 20))
                    .foregroundColor(.primary)
                    .frame(width: 44, height: 44)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.primary.opacity(0.1))
                    )
            }
            .buttonStyle(PlainButtonStyle())
            .padding(.trailing, 16)
        }
        .frame(height: 60)
        .background(Color(UIColor.secondarySystemBackground))
        .shadow(color: Color.black.opacity(0.15), radius: 3)
    }
}

// 工具欄分組
struct ToolbarGroup<Content: View>: View {
    let title: String
    let content: Content
    
    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.secondary)
                .padding(.leading, 8)
            
            HStack(spacing: 4) {
                content
            }
        }
    }
}

// 工具欄按鈕
struct ToolbarButton: View {
    let icon: String
    let label: String
    var isActive: Bool = false
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 2) {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: isActive ? .medium : .regular))
                    .foregroundColor(isActive ? .accentColor : .primary)
                
                Text(label)
                    .font(.system(size: 10, weight: isActive ? .medium : .regular))
                    .foregroundColor(isActive ? .accentColor : .secondary)
                    .lineLimit(1)
            }
            .frame(width: 50, height: 46)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isActive ? Color.accentColor.opacity(0.1) : Color.clear)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(isActive ? Color.accentColor.opacity(0.3) : Color.clear, lineWidth: 1)
                    )
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
}
