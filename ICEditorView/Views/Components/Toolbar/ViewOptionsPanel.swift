//
//  ViewOptionsPanel.swift
//  ICEditorView
//
//  Created by TimChi on 2025/4/9.
//

import SwiftUI

/// 視圖選項面板 - 可折疊的右側面板
struct ViewOptionsPanel: View {
    @ObservedObject var viewState: ICLayoutViewState
    @Binding var isExpanded: Bool
    @Binding var selectedTab: Int
    
    var onClose: () -> Void
    
    // 定義頁籤
    private let tabs = ["顯示", "邊框", "關聯"]
    
    var body: some View {
        VStack(spacing: 0) {
            // 頂部標題列
            HStack {
                Spacer()
                
                Text("視圖選項")
                    .font(.headline)
                
                Spacer()
                
                Button(action: onClose) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title3)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            
            Divider()
            
            // 頁籤選擇區
            HStack(spacing: 0) {
                ForEach(0..<tabs.count, id: \.self) { index in
                    TabButton(
                        title: tabs[index],
                        isSelected: selectedTab == index,
                        action: {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                selectedTab = index
                            }
                        }
                    )
                }
            }
            .padding(.horizontal, 8)
            .padding(.top, 8)
            
            // 內容區域
            Group {
                switch selectedTab {
                case 0:
                    displayOptionsTab
                case 1:
                    boundaryOptionsTab
                case 2:
                    associationOptionsTab
                default:
                    EmptyView()
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .frame(maxHeight: .infinity)
            
            // 底部按鈕
            ExpandCollapseButton(isExpanded: $isExpanded)
                .padding(.bottom, 16)
        }
        .frame(width: 280)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(UIColor.secondarySystemBackground))
                .shadow(color: Color.black.opacity(0.2), radius: 8, x: -5, y: 0)
        )
    }
    
    // 顯示選項頁籤
    private var displayOptionsTab: some View {
        VStack(spacing: 16) {
            ToggleOption(
                isOn: $viewState.showLabels,
                icon: "tag.fill",
                title: "顯示標籤",
                description: "顯示元件名稱標籤"
            )
            
            ToggleOption(
                isOn: $viewState.showConnections,
                icon: "link",
                title: "顯示連線",
                description: "顯示Pin與PAD之間的連線"
            )
            
            ToggleOption(
                isOn: $viewState.showGrid,
                icon: "grid",
                title: "顯示網格",
                description: "顯示背景網格線"
            )
            
            Spacer()
        }
    }
    
    // IC邊框選項頁籤
    private var boundaryOptionsTab: some View {
        VStack(spacing: 16) {
            ToggleOption(
                isOn: $viewState.showICBoundary,
                icon: "square.dashed",
                title: "顯示IC邊框",
                description: "顯示IC區域邊界"
            )
            
            ToggleOption(
                isOn: $viewState.useFixedICBoundary,
                icon: "square.fill",
                title: "固定尺寸邊框",
                description: "使用固定尺寸而非自動計算"
            )
            
            // 如果啟用固定尺寸，顯示尺寸設定
            if viewState.useFixedICBoundary {
                VStack(alignment: .leading, spacing: 8) {
                    Text("邊框尺寸")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    HStack {
                        Text("寬度:")
                        Spacer()
                        TextField("", value: Binding(
                            get: { Int(viewState.fixedICSize.width) },
                            set: { viewState.fixedICSize.width = CGFloat($0) }
                        ), formatter: NumberFormatter())
                        .keyboardType(.numberPad)
                        .frame(width: 100)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                    
                    HStack {
                        Text("高度:")
                        Spacer()
                        TextField("", value: Binding(
                            get: { Int(viewState.fixedICSize.height) },
                            set: { viewState.fixedICSize.height = CGFloat($0) }
                        ), formatter: NumberFormatter())
                        .keyboardType(.numberPad)
                        .frame(width: 100)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                }
                .padding(.vertical, 8)
            }
            
            Spacer()
        }
    }
    
    // 關聯選項頁籤
    private var associationOptionsTab: some View {
        VStack(spacing: 16) {
            Button(action: {
                // 開啟關聯管理器
            }) {
                HStack {
                    Image(systemName: "link.circle.fill")
                        .font(.title3)
                        .foregroundColor(.accentColor)
                    
                    Text("開啟關聯管理器")
                        .font(.headline)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.body)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.accentColor.opacity(0.1))
                )
            }
            
            Spacer()
        }
    }
}

/// 頁籤按鈕
struct TabButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 15, weight: isSelected ? .semibold : .regular))
                .foregroundColor(isSelected ? .accentColor : .secondary)
                .padding(.vertical, 8)
                .frame(maxWidth: .infinity)
                .overlay(
                    Rectangle()
                        .frame(height: 2)
                        .foregroundColor(isSelected ? .accentColor : .clear)
                        .padding(.top, 28)
                )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

/// 開合按鈕
struct ExpandCollapseButton: View {
    @Binding var isExpanded: Bool
    
    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                isExpanded.toggle()
            }
        }) {
            HStack {
                Spacer()
                
                Text(isExpanded ? "收合面板" : "展開面板")
                    .font(.subheadline)
                    .foregroundColor(.accentColor)
                
                Image(systemName: isExpanded ? "chevron.right.circle.fill" : "chevron.left.circle.fill")
                    .foregroundColor(.accentColor)
                
                Spacer()
            }
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.accentColor.opacity(0.5), lineWidth: 1)
            )
            .padding(.horizontal, 20)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

/// 切換選項元件
struct ToggleOption: View {
    @Binding var isOn: Bool
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        Toggle(isOn: $isOn) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(isOn ? .accentColor : .secondary)
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.headline)
                    
                    Text(description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .toggleStyle(SwitchToggleStyle(tint: .accentColor))
    }
}
